use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;

use crate::api::node::*;

use cmajor::*;

use flutter_rust_bridge::*;
use performer::endpoints::stream::StreamType;
use performer::Endpoint;
use performer::InputEvent;
use performer::InputStream;
use performer::InputValue;
use performer::OutputEvent;
use performer::OutputStream;
use performer::OutputValue;

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

struct ClearValue<T> {
    voices: Arc<Mutex<Voices>>,
    handle: Endpoint<InputValue<T>>,
}

impl<T: Copy + Default + SetInputValue> ExecuteAction for ClearValue<T> {
    fn execute(&mut self, _num_frames: usize) {
        self.voices
            .try_lock()
            .unwrap()
            .set(self.handle, T::default());
    }
}

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

struct CopyConvertValue<A, B> {
    src_voices: Arc<Mutex<Voices>>,
    src_handle: Endpoint<OutputValue<A>>,
    dst_voices: Arc<Mutex<Voices>>,
    dst_handle: Endpoint<InputValue<B>>,
}

impl<A, B> ExecuteAction for CopyConvertValue<A, B>
where
    B: Copy + SetInputValue, A: Copy + for<'a> GetOutputValue<Output<'a> = A> + ConvertTo<B>,
{
    fn execute(&mut self, num_frames: usize) {
        let mut src = self.src_voices
            .try_lock()
            .unwrap();
        let mut dst = self.dst_voices
            .try_lock()
            .unwrap();

        let a = src.get(self.src_handle);
        let b = a.convert_to();
        dst.set(self.dst_handle, b);
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

    // Convert values
    CopyValueFloat32ToFloat64(CopyConvertValue<f32, f64>),
    CopyValueFloat32ToInt32(CopyConvertValue<f32, i32>),
    CopyValueFloat32ToInt64(CopyConvertValue<f32, i64>),
    CopyValueFloat32ToBool(CopyConvertValue<f32, bool>),

    CopyValueFloat64ToFloat32(CopyConvertValue<f64, f32>),
    CopyValueFloat64ToInt32(CopyConvertValue<f64, i32>),
    CopyValueFloat64ToInt64(CopyConvertValue<f64, i64>),
    CopyValueFloat64ToBool(CopyConvertValue<f64, bool>),

    CopyValueInt32ToFloat32(CopyConvertValue<i32, f32>),
    CopyValueInt32ToFloat64(CopyConvertValue<i32, f64>),
    CopyValueInt32ToInt64(CopyConvertValue<i32, i64>),
    CopyValueInt32ToBool(CopyConvertValue<i32, bool>),

    CopyValueInt64ToFloat32(CopyConvertValue<i64, f32>),
    CopyValueInt64ToFloat64(CopyConvertValue<i64, f64>),
    CopyValueInt64ToInt32(CopyConvertValue<i64, i32>),
    CopyValueInt64ToBool(CopyConvertValue<i64, bool>),

    CopyValueBoolToFloat32(CopyConvertValue<bool, f32>),
    CopyValueBoolToFloat64(CopyConvertValue<bool, f64>),
    CopyValueBoolToInt32(CopyConvertValue<bool, i32>),
    CopyValueBoolToInt64(CopyConvertValue<bool, i64>),

    // Clear values
    ClearValueFloat32(ClearValue<f32>),
    ClearValueFloat64(ClearValue<f64>),
    ClearValueInt32(ClearValue<i32>),
    ClearValueInt64(ClearValue<i64>),
    ClearValueBool(ClearValue<bool>),

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

                let value = voices.get(handle.clone()).unwrap();
                queue.force_push(value.to_owned());
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

            // Convert values
            Action::CopyValueFloat32ToFloat64(action) => action.execute(num_frames),
            Action::CopyValueFloat32ToInt32(action) => action.execute(num_frames),
            Action::CopyValueFloat32ToInt64(action) => action.execute(num_frames),
            Action::CopyValueFloat32ToBool(action) => action.execute(num_frames),

            Action::CopyValueFloat64ToFloat32(action) => action.execute(num_frames),
            Action::CopyValueFloat64ToInt32(action) => action.execute(num_frames),
            Action::CopyValueFloat64ToInt64(action) => action.execute(num_frames),
            Action::CopyValueFloat64ToBool(action) => action.execute(num_frames),

            Action::CopyValueInt32ToFloat32(action) => action.execute(num_frames),
            Action::CopyValueInt32ToFloat64(action) => action.execute(num_frames),
            Action::CopyValueInt32ToInt64(action) => action.execute(num_frames),
            Action::CopyValueInt32ToBool(action) => action.execute(num_frames),

            Action::CopyValueInt64ToFloat32(action) => action.execute(num_frames),
            Action::CopyValueInt64ToFloat64(action) => action.execute(num_frames),
            Action::CopyValueInt64ToInt32(action) => action.execute(num_frames),
            Action::CopyValueInt64ToBool(action) => action.execute(num_frames),

            Action::CopyValueBoolToFloat32(action) => action.execute(num_frames),
            Action::CopyValueBoolToFloat64(action) => action.execute(num_frames),
            Action::CopyValueBoolToInt32(action) => action.execute(num_frames),
            Action::CopyValueBoolToInt64(action) => action.execute(num_frames),

            // Clear values
            Action::ClearValueFloat32(action) => action.execute(num_frames),
            Action::ClearValueFloat64(action) => action.execute(num_frames),
            Action::ClearValueInt32(action) => action.execute(num_frames),
            Action::ClearValueInt64(action) => action.execute(num_frames),
            Action::ClearValueBool(action) => action.execute(num_frames),

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

pub struct Actions {
    actions: Vec<Action>
}

impl Actions {
    pub fn from(graph: Graph) {
        // TODO
    }
}

pub fn generate_graph_actions(mut graph: Graph) -> Vec<Action> {
    let mut actions = Vec::new();

    // Sort nodes topologically
    sort_nodes_topologically(&mut graph).unwrap();

    // Generate actions for each node
    for node in &graph.nodes {
        generate_node_actions(&mut actions, node, &graph);
    }

    return actions;
}

fn sort_nodes_topologically(graph: &mut Graph) -> Result<(), String> {
    let node_count = graph.nodes.len();

    // Map from node_id to its current index in self.nodes
    let node_id_to_index: HashMap<u32, usize> = graph.nodes
        .iter()
        .enumerate()
        .map(|(index, node)| (node.id, index))
        .collect();

    // Initialize in-degree and adjacency list (successors)
    let mut in_degree = vec![0; node_count];
    let mut adj = vec![Vec::new(); node_count];

    // Build the graph representation
    for cable in &graph.cables {
        let &source_index = node_id_to_index.get(&cable.source.node.id)
            .ok_or_else(|| format!("Source node_id {} not found in nodes", cable.source.node.id))?;
        let &dest_index = node_id_to_index.get(&cable.destination.node.id)
            .ok_or_else(|| format!("Destination node_id {} not found in nodes", cable.destination.node.id))?;

        // Add edge from source to destination
        adj[source_index].push(dest_index);

        // Increment in-degree of destination
        in_degree[dest_index] += 1;
    }

    // Kahn's algorithm to compute topological order
    let mut stack: Vec<usize> = in_degree.iter()
        .enumerate()
        .filter_map(|(index, &deg)| if deg == 0 { Some(index) } else { None })
        .collect();

    let mut sorted_indices = Vec::with_capacity(node_count);

    while let Some(node_index) = stack.pop() {
        sorted_indices.push(node_index);

        for &succ_index in &adj[node_index] {
            in_degree[succ_index] -= 1;
            if in_degree[succ_index] == 0 {
                stack.push(succ_index);
            }
        }
    }

    if sorted_indices.len() != node_count {
        // Graph has at least one cycle
        return Err("The graph contains a cycle and cannot be topologically sorted.".to_string());
    }
    // Create a mapping from old index to new index
    let mut index_map = vec![0; node_count]; // index_map[old_index] = new_index
    for (new_index, &old_index) in sorted_indices.iter().enumerate() {
        index_map[old_index] = new_index;
    }

    // Rearrange nodes in place without cloning
    for i in 0..node_count {
        while index_map[i] != i {
            let target = index_map[i];
            graph.nodes.swap(i, target);
            index_map[i] = index_map[target];
            index_map[target] = target;
        }
    }

    Ok(())
}

fn generate_node_actions(actions: &mut Vec<Action>, dst_node: &Node, graph: &Graph) {
    // Copy node input data
    for endpoint in dst_node.get_inputs().iter() {
        // Generate external input actions
        if let EndpointHandle::ExternalInput { handle, channel } = &endpoint.handle() {
            generate_external_input_actions(actions, dst_node, handle.clone(), *channel);
            continue;
        }

        // Generate input actions
        if let EndpointHandle::Input(handle) = &endpoint.handle() {
            if let InputHandle::Widget(widget) = handle {
                generate_widget_endpoint_actions(actions, dst_node, widget);
                continue;
            }

            let mut filled = false;

            // Generate connection actions
            graph
                .cables
                .iter()
                .filter(| cable | &cable.destination.node == dst_node && &cable.destination.endpoint == endpoint)
                .for_each(| cable | {
                    println!(" - Copy {} to {}", cable.source.node.id, dst_node.id);

                    let src = cable.source.endpoint.handle();

                    if let EndpointHandle::Output(src) = src {
                        let _ = generate_connection_actions(
                            actions,
                            cable.source.node.voices(),
                            src.clone(),
                            dst_node.voices(),
                            handle.clone(),
                        );
                    } else {
                        println!("Connection is not from an output to an input");
                    }

                    filled = true;
                });

            // Generate actions to fill missing input streams
            if !filled {
                println!(" - Clear input of node {}", dst_node.id);
                if let EndpointHandle::Input(handle) = &endpoint.handle() {
                    generate_clear_actions(actions, dst_node.voices(), handle.clone());
                }
            }
        }
    }

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

fn generate_widget_endpoint_actions(actions: &mut Vec<Action>, node: &Node, handle: &InputWidgetHandle) {
    match handle {
        InputWidgetHandle::Value { handle, queue } => {
            println!(" - Send widget value updates for node {}", node.id);
            actions.push(
                Action::ReceiveValue {
                    voices: node.voices(),
                    handle: handle.clone(),
                    queue: queue.clone()
                }
            );
        },
        InputWidgetHandle::Event { handle, queue } => {
            println!(" - Send widget event updates for node {}", node.id);
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

fn generate_clear_actions(actions: &mut Vec<Action>, voices: Arc<Mutex<Voices>>, handle: InputHandle) {
    match handle {
        InputHandle::Stream(handle) => {
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
        },
        InputHandle::Value(handle) => {
            match handle {
                InputValueHandle::Float32(handle) => {
                    actions.push(
                        Action::ClearValueFloat32(
                            ClearValue {
                                voices,
                                handle
                            }
                        )
                    );
                },
                InputValueHandle::Float64(handle) => {
                    actions.push(
                        Action::ClearValueFloat64(
                            ClearValue {
                                voices,
                                handle
                            }
                        )
                    );
                },
                InputValueHandle::Int32(handle) => {
                    actions.push(
                        Action::ClearValueInt32(
                            ClearValue {
                                voices,
                                handle
                            }
                        )
                    );
                },
                InputValueHandle::Int64(handle) => {
                    actions.push(
                        Action::ClearValueInt64(
                            ClearValue {
                                voices,
                                handle
                            }
                        )
                    );
                },
                InputValueHandle::Bool(handle) => {
                    actions.push(
                        Action::ClearValueBool(
                            ClearValue {
                                voices,
                                handle
                            }
                        )
                    );
                },
            }
        },
        _ => ()
    }
}

fn generate_external_input_actions(actions: &mut Vec<Action>, node: &Node, handle: InputHandle, channel: usize) {
    match handle {
        InputHandle::Stream(handle) => {
            match handle {
                InputStreamHandle::MonoFloat32(handle) => {
                    println!(" - External mono input channel {} to node {}", channel, node.id);
                    actions.push(
                        Action::InputStreamMonoFloat32 {
                            voices: node.voices(),
                            handle,
                            channel,
                        }
                    );
                },
                InputStreamHandle::StereoFloat32(handle) => {
                    println!(" - External stereo input channel {} to node {}", channel, node.id);
                    let buffer = vec![[0.0, 0.0]; 1024];
                    actions.push(
                        Action::InputStreamStereoFloat32 {
                            voices: node.voices(),
                            handle,
                            buffer,
                            channel,
                        }
                    );
                }
            }
        }
        InputHandle::Widget(_) => println!(" - External widgets are not supported"),
        InputHandle::Event(_) => println!(" - External events are not supported"),
        InputHandle::Value(_) => println!(" - External values are not supported")
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

use crate::api::endpoint::NodeEndpoint;

pub fn is_connection_supported(src_node: &Node, src_endpoint: &NodeEndpoint, dst_node: &Node, dst_endpoint: &NodeEndpoint) -> Result<(), &'static str> {
    let mut actions = Vec::new();
    let src_voices = src_node.voices();
    let src_handle = src_endpoint.handle();
    let dst_voices = dst_node.voices();
    let dst_handle = dst_endpoint.handle();

    if let (EndpointHandle::Output(src_handle), EndpointHandle::Input(dst_handle)) = (src_handle, dst_handle) {
        return generate_connection_actions(&mut actions, src_voices, src_handle.clone(), dst_voices, dst_handle.clone());
    } else {
        return Err("Connection not from an output to an input");
    }
}

fn generate_connection_actions(
    actions: &mut Vec<Action>,
    src_voices: Arc<Mutex<Voices>>,
    src_handle: OutputHandle,
    dst_voices: Arc<Mutex<Voices>>,
    dst_handle: InputHandle) -> Result<(), &'static str> {

    let max_frames: usize = 1024;

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
                _ => return Err("Endpoints streams types are not compatible")
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
            let action = match src_handle {
                OutputValueHandle::Float32(src_handle) => match dst_handle {
                    InputValueHandle::Float32(dst_handle) => Action::CopyValueFloat32( CopyValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Float64(dst_handle) => Action::CopyValueFloat32ToFloat64( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Int32(dst_handle) => Action::CopyValueFloat32ToInt32( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Int64(dst_handle) => Action::CopyValueFloat32ToInt64( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Bool(dst_handle) => Action::CopyValueFloat32ToBool( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                }
                OutputValueHandle::Float64(src_handle) => match dst_handle {
                    InputValueHandle::Float32(dst_handle) => Action::CopyValueFloat64ToFloat32( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Float64(dst_handle) => Action::CopyValueFloat64( CopyValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Int32(dst_handle) => Action::CopyValueFloat64ToInt32( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Int64(dst_handle) => Action::CopyValueFloat64ToInt64( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Bool(dst_handle) => Action::CopyValueFloat64ToBool( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                }
                OutputValueHandle::Int32(src_handle) => match dst_handle {
                    InputValueHandle::Float32(dst_handle) => Action::CopyValueInt32ToFloat32( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Float64(dst_handle) => Action::CopyValueInt32ToFloat64( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Int32(dst_handle) => Action::CopyValueInt32( CopyValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Int64(dst_handle) => Action::CopyValueInt32ToInt64( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Bool(dst_handle) => Action::CopyValueInt32ToBool( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                }
                OutputValueHandle::Int64(src_handle) => match dst_handle {
                    InputValueHandle::Float32(dst_handle) => Action::CopyValueInt64ToFloat32( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Float64(dst_handle) => Action::CopyValueInt64ToFloat64( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Int32(dst_handle) => Action::CopyValueInt64ToInt32( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Int64(dst_handle) => Action::CopyValueInt64( CopyValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Bool(dst_handle) => Action::CopyValueInt64ToBool( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                }
                OutputValueHandle::Bool(src_handle) => match dst_handle {
                    InputValueHandle::Float32(dst_handle) => Action::CopyValueBoolToFloat32( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Float64(dst_handle) => Action::CopyValueBoolToFloat64( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Int32(dst_handle) => Action::CopyValueBoolToInt32( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Int64(dst_handle) => Action::CopyValueBoolToInt64( CopyConvertValue { src_voices, src_handle, dst_voices, dst_handle } ),
                    InputValueHandle::Bool(dst_handle) => Action::CopyValueBool( CopyValue { src_voices, src_handle, dst_voices, dst_handle } ),
                }
            };

            actions.push(action);
        },
        _ => return Err("Connection not between compatible endpoints")
    };

    Ok(())
}