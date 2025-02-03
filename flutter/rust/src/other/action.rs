use std::borrow::BorrowMut;
use std::collections::HashMap;
use std::marker::PhantomData;
use std::process::Output;
use std::sync::Arc;
use std::sync::Mutex;
use std::sync::RwLock;

use crate::api::cable::*;
use crate::api::endpoint::*;
use crate::api::node::*;

use cmajor::*;

use flutter_rust_bridge::*;
use for_generated::futures::SinkExt;
use performer::endpoints::stream::StreamType;
use performer::Endpoint;
use performer::InputEvent;
use performer::InputStream;
use performer::InputValue;
use performer::OutputEvent;
use performer::OutputStream;
use performer::OutputValue;
use performer::Performer;

use cmajor::performer::endpoints::value::{GetOutputValue, SetInputValue};
use crossbeam_queue::ArrayQueue;

use crate::api::graph::*;
use crate::other::voices::*;
use crate::other::handle::*;

trait ExecuteAction {
    fn execute(&mut self, num_frames: usize);
}

struct CopyStream<T: StreamType> {
    src_voices: Arc<Mutex<Voices>>,
    src_handle: Endpoint<OutputStream<T>>,
    dst_voices: Arc<Mutex<Voices>>,
    dst_handle: Endpoint<InputStream<T>>,
    buffer: Vec<T>,
}

impl<T: StreamType> ExecuteAction for CopyStream<T> {
    fn execute(&mut self, num_frames: usize) {
        let src = self.src_voices
            .try_lock()
            .unwrap();
        let mut dst = self.dst_voices
            .try_lock()
            .unwrap();

        src.copy_streams_to(self.src_handle, &mut dst, self.dst_handle, &mut self.buffer[..num_frames]);
    }
}

struct ConvertCopyStream<A: StreamType, B: StreamType> {
    src_voices: Arc<Mutex<Voices>>,
    src_handle: Endpoint<OutputStream<A>>,
    src_buffer: Vec<A>,
    dst_voices: Arc<Mutex<Voices>>,
    dst_handle: Endpoint<InputStream<B>>,
    dst_buffer: Vec<B>
}

impl<B: StreamType, A: StreamType + ConvertTo<B>> ExecuteAction for ConvertCopyStream<A, B> {
    fn execute(&mut self, num_frames: usize) {
        let src = self.src_voices
            .try_lock()
            .unwrap();
        let mut dst = self.dst_voices
            .try_lock()
            .unwrap();

        src.convert_copy_streams_to(
            self.src_handle,
            &mut self.src_buffer[..num_frames],
            &mut dst,
            self.dst_handle,
            &mut self.dst_buffer[..num_frames]
        );
    }
}

struct ClearStream<T: StreamType + Default> {
    voices: Arc<Mutex<Voices>>,
    handle: Endpoint<InputStream<T>>,
    buffer: Vec<T>,
}

impl<T: StreamType + Default> ExecuteAction for ClearStream<T> {
    fn execute(&mut self, num_frames: usize) {
        self.voices
            .try_lock()
            .unwrap()
            .write(self.handle, self.buffer.as_slice());
    }
}

#[frb(ignore)]
struct CopyValue<T> {
    src_voices: Arc<Mutex<Voices>>,
    src_handle: Endpoint<OutputValue<T>>,
    dst_voices: Arc<Mutex<Voices>>,
    dst_handle: Endpoint<InputValue<T>>,
}

impl<T> ExecuteAction for CopyValue<T>
where
    T: Copy + SetInputValue + for<'a> GetOutputValue<Output<'a> = T>,
{
    fn execute(&mut self, num_frames: usize) {
        let mut src = self.src_voices
            .try_lock()
            .unwrap();
        let mut dst = self.dst_voices
            .try_lock()
            .unwrap();

        src.copy_values_to(self.src_handle, &mut dst, self.dst_handle);
    }
}

struct CopyEvent {
    src_voices: Arc<Mutex<Voices>>,
    src_handle: Endpoint<OutputEvent>,
    dst_voices: Arc<Mutex<Voices>>,
    dst_handle: Endpoint<InputEvent>,
}

impl ExecuteAction for CopyEvent {
    fn execute(&mut self, num_frames: usize) {
        let mut src = self.src_voices
            .try_lock()
            .unwrap();
        let mut dst = self.dst_voices
            .try_lock()
            .unwrap();

        src.copy_events_to(self.src_handle, &mut dst, self.dst_handle);
    }
}

pub enum Action {
    Advance(Arc<Mutex<Voices>>),

    // Copy streams
    CopyStreamMonoFloat32(CopyStream<f32>),
    CopyStreamStereoFloat32(CopyStream<[f32; 2]>),
    CopyStreamMonoToStereoFloat32(ConvertCopyStream<f32, [f32; 2]>),
    CopyStreamStereoToMonoFloat32(ConvertCopyStream<[f32; 2], f32>),

    // Clear streams
    ClearStreamMonoFloat32(ClearStream<f32>),
    ClearStreamStereoFloat32(ClearStream<[f32; 2]>),

    // Copy events
    CopyEvent(CopyEvent),

    // Recieve value from the user interface
    ReceiveValue {
        voices: Arc<Mutex<Voices>>,
        handle: Endpoint<InputValue<cmajor::value::Value>>,
        queue: Arc<ArrayQueue<cmajor::value::Value>>,
    },

    // Recieve events from the user interface
    ReceiveEvents {
        voices: Arc<Mutex<Voices>>,
        handle: Endpoint<InputEvent>,
        queue: Arc<ArrayQueue<cmajor::value::Value>>,
    },

    // Send value to the user interface
    SendValue {
        voices: Arc<Mutex<Voices>>,
        handle: Endpoint<OutputValue<cmajor::value::Value>>,
        queue: Arc<ArrayQueue<cmajor::value::Value>>,
    },

    // Send events to the user interface
    SendEvents {
        voices: Arc<Mutex<Voices>>,
        handle: Endpoint<OutputEvent>,
        queue: Arc<ArrayQueue<cmajor::value::Value>>,
    },

    // Copy values
    CopyValueFloat32(CopyValue<f32>),
    CopyValueFloat64(CopyValue<f64>),
    CopyValueInt32(CopyValue<i32>),
    CopyValueInt64(CopyValue<i64>),
    CopyValueBool(CopyValue<bool>),

    // Output streams
    InputStreamMonoFloat32 {
        voices: Arc<Mutex<Voices>>,
        handle: Endpoint<InputStream<f32>>,
        channel: usize,
    },
    OutputStreamMonoFloat32 {
        voices: Arc<Mutex<Voices>>,
        handle: Endpoint<OutputStream<f32>>,
        channel: usize,
    },
    InputStreamStereoFloat32 {
        voices: Arc<Mutex<Voices>>,
        handle: Endpoint<InputStream<[f32; 2]>>,
        buffer: Vec<[f32; 2]>,
        channel: usize,
    },
    OutputStreamStereoFloat32 {
        voices: Arc<Mutex<Voices>>,
        handle: Endpoint<OutputStream<[f32; 2]>>,
        buffer: Vec<[f32; 2]>,
        channel: usize,
    }
}

impl Action {
    pub fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let num_frames = audio
            .get(0)
            .unwrap()
            .len();

        match self {
            Action::Advance(voices) => {
                let mut voices = voices
                    .try_lock()
                    .unwrap();

                voices.set_block_size(num_frames);
                voices.advance();
            },

            // Copy streams
            Action::CopyStreamMonoFloat32(action) => action.execute(num_frames),
            Action::CopyStreamStereoFloat32(action) => action.execute(num_frames),

            // Convert copy streams
            Action::CopyStreamMonoToStereoFloat32(action) => action.execute(num_frames),
            Action::CopyStreamStereoToMonoFloat32(action) => action.execute(num_frames),

            // Fill streams
            Action::ClearStreamMonoFloat32(action) => action.execute(num_frames),
            Action::ClearStreamStereoFloat32(action) => action.execute(num_frames),

            // Copy event
            Action::CopyEvent(action) => action.execute(num_frames),
            
            // Recieve UI value
            Action::ReceiveValue { voices, handle, queue } => {
                let mut voices = voices
                    .try_lock()
                    .unwrap();

                while let Some(value) = queue.pop() {
                    voices.set_value(handle.clone(), value);
                }
            }

            // Recieve UI events
            Action::ReceiveEvents { voices, handle, queue } => {
                let mut voices = voices
                    .try_lock()
                    .unwrap();

                while let Some(event) = queue.pop() {
                    let _ = voices.post(*handle, &event);
                }
            }

            Action::SendValue { voices, handle, queue } => {
                let mut voices = voices
                    .try_lock()
                    .unwrap();

                // let value = voices.get(*handle).unwrap();
            }

            Action::SendEvents { voices, handle, queue } => {
                let mut voices = voices
                    .try_lock()
                    .unwrap();

                voices.fetch(*handle, | _, value | {
                    // queue.force_push(value);
                });
            }

            // Copy values
            Action::CopyValueFloat32(action) => action.execute(num_frames),
            Action::CopyValueFloat64(action) => action.execute(num_frames),
            Action::CopyValueInt32(action) => action.execute(num_frames),
            Action::CopyValueInt64(action) => action.execute(num_frames),
            Action::CopyValueBool(action) => action.execute(num_frames),

            // Input stream
            Action::InputStreamMonoFloat32 { voices, handle, channel } => {
                if let Some(channel) = audio.get(*channel) {
                    voices
                        .try_lock()
                        .unwrap()
                        .write(*handle, channel);
                }
            }
            Action::OutputStreamMonoFloat32 { voices, handle, channel } => {
                if let Some(channel) = audio.get_mut(*channel) {
                    voices
                        .try_lock()
                        .unwrap()
                        .read(*handle, channel);
                }
            }
            Action::InputStreamStereoFloat32 { voices, handle, channel, buffer } => {
                // Copy the left channel
                if let Some(left) = audio.get(*channel * 2) {
                    for (b, l) in buffer.iter_mut().zip(left.iter()) {
                        b[0] = *l;
                    }
                }

                // Copy the right channel
                if let Some(right) = audio.get(*channel * 2 + 1) {
                    for (b, r) in buffer.iter_mut().zip(right.iter()) {
                        b[0] = *r;
                    }
                }

                // Write the samples
                voices
                    .try_lock()
                    .unwrap()
                    .write(*handle, buffer);
            }
            Action::OutputStreamStereoFloat32 { voices, handle, channel, buffer} => {
                // Read the samples
                voices
                    .try_lock()
                    .unwrap()
                    .read(*handle, buffer);

                // Copy the left channel
                if let Some(left) = audio.get_mut(*channel * 2) {
                    for (l, b) in left.iter_mut().zip(buffer.iter()) {
                        *l = b[0];
                    }
                }

                // Copy the right channel
                if let Some(right) = audio.get_mut(*channel * 2 + 1) {
                    for (r, b) in right.iter_mut().zip(buffer.iter()) {
                        *r = b[1];
                    }
                }
            }
        }
    }
}

pub fn generate_graph_actions(graph: &Graph) -> Vec<Action> {
    let mut actions = Vec::new();

    // Generate actions for each node
    for node in &graph.nodes {
        generate_node_actions(&mut actions, node, graph);
    }

    return actions;
}

fn generate_node_actions(actions: &mut Vec<Action>, dst_node: &Node, graph: &Graph) {
    // Copy node input data
    for endpoint in dst_node.get_inputs().iter() {
        let mut filled = false;

        // Generate input actions
        if let EndpointHandle::Input(handle) = &endpoint.handle() {
            generate_input_endpoint_actions(actions, dst_node, &handle);
        }

        // Generate connection actions
        graph
            .cables
            .iter()
            .filter(| cable | &cable.destination.node == dst_node && &cable.destination.endpoint == endpoint)
            .for_each(| cable | {
                println!(" - Copy {} to {}", cable.source.node.id, dst_node.id);

                generate_connection_actions(
                    actions,
                    cable.source.node.voices(),
                    cable.source.endpoint.handle().clone(),
                    dst_node.voices(),
                    endpoint.handle().clone()
                );

                filled = true;
            });

        // Generate actions to fill missing input streams
        if !filled {
            println!(" - Fill input of node {}", dst_node.id);
            generate_clear_stream_actions(actions, dst_node.voices(), endpoint.handle().clone());
        }
    }

    // Generate any external input actions
    generate_external_input_actions(actions, dst_node);

    // Generate actions for each node advance
    println!(" - Advance node {}", dst_node.id);
    actions.push(Action::Advance(dst_node.voices()));

    // Generate output actions
    for endpoint in dst_node.get_outputs().iter() {
        if let EndpointHandle::Output(handle) = &endpoint.handle() {
            generate_output_endpoint_actions(actions, dst_node, &handle);
        }
    }

    // Generate any external output actions
    generate_external_output_actions(actions, dst_node);
}

fn generate_input_endpoint_actions(actions: &mut Vec<Action>, node: &Node, handle: &InputHandle) {
    match handle {
        InputHandle::Widget(handle) => {
            match handle {
                InputWidgetHandle::Value { handle, queue } => {
                    println!(" - Recieve widget value updates for node {}", node.id);
                    actions.push(
                        Action::ReceiveValue {
                            voices: node.voices(),
                            handle: handle.clone(),
                            queue: queue.clone()
                        }
                    );
                },
                InputWidgetHandle::Event { handle, queue } => {
                    println!(" - Recieve widget event updates for node {}", node.id);
                    actions.push(
                        Action::ReceiveEvents {
                            voices: node.voices(),
                            handle: handle.clone(),
                            queue: queue.clone()
                        }
                    );
                }
            };
        }
        _ => ()
    }
}

fn generate_output_endpoint_actions(actions: &mut Vec<Action>, node: &Node, handle: &OutputHandle) {
    match handle {
        OutputHandle::Widget(handle) => {
            match handle {
                OutputWidgetHandle::Value { handle, queue } => {
                    println!(" - Send widget value updates for node {}", node.id);
                    actions.push(
                        Action::SendValue {
                            voices: node.voices(),
                            handle: handle.clone(),
                            queue: queue.clone()
                        }
                    );
                },
                OutputWidgetHandle::Event { handle, queue } => {
                    println!(" - Send widget event updates for node {}", node.id);
                    actions.push(
                        Action::SendEvents {
                            voices: node.voices(),
                            handle: handle.clone(),
                            queue: queue.clone()
                        }
                    );
                }
            };
        }
        _ => ()
    }
}

fn generate_clear_stream_actions(actions: &mut Vec<Action>, voices: Arc<Mutex<Voices>>, handle: EndpointHandle) {
    match handle {
        EndpointHandle::Input(handle) => {
            if let InputHandle::Stream(handle) = handle {
                match handle {
                    InputStreamHandle::MonoFloat32(handle) => {
                        let buffer = vec![0.0; 1024];
                        actions.push(
                            Action::ClearStreamMonoFloat32(
                                ClearStream {
                                    voices,
                                    handle,
                                    buffer
                                }
                            )
                        );
                    },
                    InputStreamHandle::StereoFloat32(handle) => {
                        let buffer = vec![[0.0; 2]; 1024];
                        actions.push(
                            Action::ClearStreamStereoFloat32(
                                ClearStream {
                                    voices,
                                    handle,
                                    buffer
                                }
                            )
                        );
                    },
                }
            }
        },
        _ => ()
    }
}

fn generate_external_input_actions(actions: &mut Vec<Action>, node: &Node) {
    for endpoint in &node.get_inputs() {
        match &endpoint.handle() {
            EndpointHandle::ExternalInput { handle, channel } => match handle {
                InputHandle::Stream(handle) => {
                    match handle {
                        InputStreamHandle::MonoFloat32(handle) => {
                            println!(" - External mono input channel {} to node {}", channel, node.id);
                            actions.push(
                                Action::InputStreamMonoFloat32 {
                                    voices: node.voices(),
                                    handle: *handle,
                                    channel: *channel
                                }
                            );
                        },
                        InputStreamHandle::StereoFloat32(handle) => {
                            println!(" - External stereo input channel {} to node {}", channel, node.id);
                            let buffer = vec![[0.0, 0.0]; 1024];
                            actions.push(
                                Action::InputStreamStereoFloat32 {
                                    voices: node.voices(),
                                    handle: *handle,
                                    buffer,
                                    channel: *channel
                                }
                            );
                        }
                    }
                }
                InputHandle::Widget(_) => println!(" - External widgets are not supported"),
                InputHandle::Event(_) => println!(" - External events are not supported"),
                InputHandle::Value(_) => println!(" - External values are not supported")
            }
            _ => ()
        }
    }
}

fn generate_external_output_actions(actions: &mut Vec<Action>, node: &Node) {
    for endpoint in &node.get_outputs() {
        match &endpoint.handle() {
            EndpointHandle::ExternalOutput { handle, channel } => match handle {
                OutputHandle::Stream(handle) => {
                    match handle {
                        OutputStreamHandle::MonoFloat32(handle) => {
                            println!(" - External mono ouput channel {} to node {}", channel, node.id);
                            actions.push(
                                Action::OutputStreamMonoFloat32 {
                                    voices: node.voices(),
                                    handle: *handle,
                                    channel: *channel
                                }
                            );
                        },
                        OutputStreamHandle::StereoFloat32(handle) => {
                            println!(" - External stereo output channel {} to node {}", channel, node.id);
                            let buffer = vec![[0.0, 0.0]; 1024];
                            actions.push(
                                Action::OutputStreamStereoFloat32 {
                                    voices: node.voices(),
                                    handle: *handle,
                                    buffer,
                                    channel: *channel
                                }
                            );
                        }
                    }
                }
                OutputHandle::Widget(_) => println!(" - External widgets are not supported"),
                OutputHandle::Event(_) => println!(" - External events are not supported"),
                OutputHandle::Value(_) => println!(" - External values are not supported")
            }
            _ => ()
        }
    }
}

fn generate_connection_actions(
    actions: &mut Vec<Action>,
    src_voices: Arc<Mutex<Voices>>,
    src_handle: EndpointHandle,
    dst_voices: Arc<Mutex<Voices>>,
    dst_handle: EndpointHandle) {

    let max_frames: usize = 1024;

    match (src_handle, dst_handle) {
        (EndpointHandle::Output(src_handle), EndpointHandle::Input(dst_handle)) => {
            match (src_handle, dst_handle) {
                (OutputHandle::Stream(src), InputHandle::Stream(dst)) => {
                    match (src, dst) {
                        (OutputStreamHandle::MonoFloat32(src_handle), InputStreamHandle::MonoFloat32(dst_handle)) => {
                            let buffer = vec![0.0; max_frames];
                            actions.push(
                                Action::CopyStreamMonoFloat32(
                                    CopyStream {
                                        src_voices,
                                        src_handle,
                                        dst_voices,
                                        dst_handle,
                                        buffer
                                    }
                                )
                            );
                        },
                        (OutputStreamHandle::StereoFloat32(src_handle), InputStreamHandle::StereoFloat32(dst_handle)) => {
                            let buffer = vec![[0.0; 2]; max_frames];
                            actions.push(
                                Action::CopyStreamStereoFloat32(
                                    CopyStream {
                                        src_voices,
                                        src_handle,
                                        dst_voices,
                                        dst_handle,
                                        buffer
                                    }
                                )
                            );
                        },
                        (OutputStreamHandle::MonoFloat32(src_handle), InputStreamHandle::StereoFloat32(dst_handle)) => {
                            let src_buffer = vec![0.0; max_frames];
                            let dst_buffer = vec![[0.0; 2]; max_frames];
                            actions.push(
                                Action::CopyStreamMonoToStereoFloat32(
                                    ConvertCopyStream {
                                        src_voices,
                                        src_handle,
                                        src_buffer,
                                        dst_voices,
                                        dst_handle,
                                        dst_buffer,
                                    }
                                )
                            );
                        },
                        _ => println!("Connection not between streams of the same type")
                    }
                },
                (OutputHandle::Event(src_handle), InputHandle::Event(dst_handle)) => {
                    actions.push(
                        Action::CopyEvent(
                            CopyEvent {
                                src_voices,
                                src_handle,
                                dst_voices,
                                dst_handle,
                            }
                        )
                    );
                },
                (OutputHandle::Value(src_handle), InputHandle::Value(dst_handle)) => {
                    match (src_handle, dst_handle) {
                        (OutputValueHandle::Float32(src_handle), InputValueHandle::Float32(dst_handle)) => {
                            actions.push(
                                Action::CopyValueFloat32(
                                    CopyValue {
                                        src_voices,
                                        src_handle,
                                        dst_voices,
                                        dst_handle,
                                    }
                                )
                            );
                        },
                        (OutputValueHandle::Float64(src_handle), InputValueHandle::Float64(dst_handle)) => {
                            actions.push(
                                Action::CopyValueFloat64(
                                    CopyValue {
                                        src_voices,
                                        src_handle,
                                        dst_voices,
                                        dst_handle,
                                    }
                                )
                            );
                        },
                        (OutputValueHandle::Int32(src_handle), InputValueHandle::Int32(dst_handle)) => {
                            actions.push(
                                Action::CopyValueInt32(
                                    CopyValue {
                                        src_voices,
                                        src_handle,
                                        dst_voices,
                                        dst_handle,
                                    }
                                )
                            );
                        },
                        (OutputValueHandle::Int64(src_handle), InputValueHandle::Int64(dst_handle)) => {
                            actions.push(
                                Action::CopyValueInt64(
                                    CopyValue {
                                        src_voices,
                                        src_handle,
                                        dst_voices,
                                        dst_handle,
                                    }
                                )
                            );
                        },
                        (OutputValueHandle::Bool(src_handle), InputValueHandle::Bool(dst_handle)) => {
                            actions.push(
                                Action::CopyValueBool(
                                    CopyValue {
                                        src_voices,
                                        src_handle,
                                        dst_voices,
                                        dst_handle,
                                    }
                                )
                            );
                        },
                        _ => println!("Connection not between values of the same type")
                    }
                },
                _ => println!("Connection not between compatible endpoints")
            }
        },
        _ => println!("Connection not from an output to an input")
    }
}