use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;

use crate::api::cable::Cable;
use crate::api::endpoint::NodeEndpoint;
use crate::api::node::*;

use cmajor::*;

use crossbeam_queue::ArrayQueue;
use performer::endpoints::stream::StreamType;
use performer::Endpoint;
use performer::InputEvent;
use performer::InputStream;
use performer::InputValue;
use performer::OutputEvent;
use performer::OutputStream;
use performer::OutputValue;

use cmajor::performer::endpoints::value::{GetOutputValue, SetInputValue};
use value::types::Array;
use value::Value;

use crate::api::graph::*;
use crate::other::voices::*;
use crate::other::handle::*;

use super::stream::*;
use super::value::*;
use super::event::*;
use super::handle::*;

pub trait ExecuteAction {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]);
}

pub fn get_num_frames(audio: &mut [&mut [f32]]) -> usize {
    audio
        .get(0)
        .unwrap()
        .len()
}

struct Advance(Arc<Mutex<Voices>>);

impl ExecuteAction for Advance {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let num_frames = get_num_frames(audio);
        let mut voices = self.0
            .try_lock()
            .unwrap();

        voices.set_block_size(num_frames);
        voices.advance();
    }
}

/*struct CopyTypedEvent<T> {
    src_voices: Arc<Mutex<Voices>>,
    src_handle: Endpoint<OutputEvent>,
    dst_voices: Arc<Mutex<Voices>>,
    dst_handle: Endpoint<InputEvent>,
    data: PhantomData<T>
}

impl<T: Copy> ExecuteAction for CopyTypedEvent<T> {
    fn execute(&mut self, num_frames: usize) {
    }
}*/



/*pub enum Action {
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

    // Copy convert events
    CopyEventFloat32ToFloat64(CopyEvent),

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
    },
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
            Action::CopyEventFloat32ToFloat64(CopyEvent { src_voices, src_handle, dst_voices, dst_handle }) => {
                todo!()
            }
            
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
}*/

pub struct Actions {
    actions: Vec<Box<dyn ExecuteAction + Send + Sync>>
}

impl ExecuteAction for Actions {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        for action in self.actions.iter_mut() {
            action.execute(audio, midi);
        }
    }
}

impl Actions {
    pub fn new() -> Self {
        Self {
            actions: Vec::new()
        }
    }

    pub fn from(graph: Graph) -> Self {
        let mut actions = Self::new();

        actions.process_graph(graph);

        return actions;
    }

    fn push<T>(&mut self, action: T) where T: ExecuteAction + Send + Sync + 'static {
        self.actions.push(Box::new(action));
    }

    pub fn process_graph(&mut self, mut graph: Graph) {
        // Sort nodes topologically
        sort_nodes_topologically(&mut graph).unwrap();

        // Generate actions for each node
        for node in &graph.nodes {
            self.process_node(node, &graph);
        }
    }

    fn process_node(&mut self, dst_node: &Node, graph: &Graph) {
        // Generate input endpoint actions
        for endpoint in dst_node.get_inputs().iter() {
            if let EndpointHandle::Input(endpoint) = &endpoint.handle() {
                self.process_input(dst_node, endpoint, graph);
            }
        }
    
        // Generate actions for each node advance
        println!(" - Advance node {}", dst_node.id);
        self.push(Advance(dst_node.voices()));
    
        // Generate output endpoint actions
        for endpoint in dst_node.get_outputs().iter() {
            if let EndpointHandle::Output(endpoint) = &endpoint.handle() {
                self.process_output(dst_node, endpoint);
            }
        }
    }

    fn process_input(&mut self, node: &Node, endpoint: &InputEndpoint, graph: &Graph) {
        match endpoint {
            InputEndpoint::Endpoint(handle) => {
                self.process_input_endpoint(node, handle, graph);
            },
            InputEndpoint::External { handle, channel } => {
                self.process_input_external(node, handle, *channel);
            }
            InputEndpoint::Widget { handle, queue } => {
                self.process_input_widget(node, handle, queue);
            },
        }
    }

    fn process_output(&mut self, node: &Node, handle: &OutputEndpoint) {
        match handle {
            OutputEndpoint::Endpoint(_) => {
                // Do nothing for output endpoints
            }
            OutputEndpoint::External { handle, channel } => {
                self.process_output_external(node, handle, *channel);
            },
            OutputEndpoint::Widget { handle, queue } => {
                self.process_output_widget(node, handle, queue);
            },
        }
    }

    fn process_input_endpoint(&mut self, node: &Node, handle: &InputHandle, graph: &Graph) {
        let mut filled = false;

        for cable in &graph.cables {
            let src_node = &cable.source.node;
            let src_handle = cable.source.endpoint.handle();
            let dst_node = &cable.destination.node;
            let dst_handle = cable.destination.endpoint.handle();

            match (src_handle, dst_handle) {
                (EndpointHandle::Output(OutputEndpoint::Endpoint(src_handle)),
                    EndpointHandle::Input(InputEndpoint::Endpoint(dst_handle))) => {
                    if dst_node == node && dst_handle == handle {
                        let _ = self.process_cable(
                            src_node.voices(),
                            src_handle.clone(),
                            dst_node.voices(),
                            dst_handle.clone()
                        );

                        filled = true;
                    }
                }
                _ => ()
            }
        }

        // Generate actions to fill missing input streams
        if !filled {
            self.process_input_clear(node.voices(), handle.clone());
        }
    }

    fn process_input_external(&mut self, node: &Node, handle: &InputHandle, channel: usize) {
        match handle {
            InputHandle::Stream(_) => println!(" - External input streams are not supproted"),
            InputHandle::Event(_) => println!(" - External events are not supported"),
            InputHandle::Value(_) => println!(" - External values are not supported")
        }
    }

    fn process_output_external(&mut self, node: &Node, handle: &OutputHandle, channel: usize) {
        match handle {
            OutputHandle::Stream(handle) => {
                match handle {
                    OutputStreamHandle::MonoFloat32(handle) => {
                        println!(" - External mono ouput channel {} to node {}", channel, node.id);
                        let buffer = vec![0.0; 1024];
                        self.push(
                            ExternalOutputStream {
                                voices: node.voices(),
                                handle: *handle,
                                buffer,
                                channel,
                            }
                        );
                    },
                    OutputStreamHandle::StereoFloat32(handle) => {
                        println!(" - External stereo output channel {} to node {}", channel, node.id);
                        let buffer = vec![[0.0, 0.0]; 1024];
                        self.push(
                            ExternalOutputStream {
                                voices: node.voices(),
                                handle: *handle,
                                buffer,
                                channel,
                            }
                        );
                    }
                    OutputStreamHandle::Err(e) => ()
                }
            }
            OutputHandle::Event(_) => println!(" - External events are not supported"),
            OutputHandle::Value(_) => println!(" - External values are not supported")
        }
    }

    fn process_input_widget(&mut self, node: &Node, handle: &InputHandle, queue: &Arc<ArrayQueue<Value>>) {
        match handle {
            InputHandle::Stream(handle) => {
                println!(" - Unsupported widget input stream");
            },
            InputHandle::Event(handle) => {
                todo!()
            },
            InputHandle::Value(handle) => {
                todo!()
            },
            _ => ()
        }
    }

    fn process_output_widget(&mut self, node: &Node, handle: &OutputHandle, queue: &Arc<ArrayQueue<Value>>) {
        match handle {
            OutputHandle::Stream(handle) => {
                println!(" - Unsupported widget output stream");
            },
            OutputHandle::Event(handle) => {
                println!(" - Unsupported widget output event");
            },
            OutputHandle::Value(handle) => {
                println!(" - Unsupported widget output value");
            },
        }
    }

    fn process_input_clear(&mut self, voices: Arc<Mutex<Voices>>, handle: InputHandle) {
        match handle {
            InputHandle::Stream(handle) => {
                match handle {
                    InputStreamHandle::MonoFloat32(handle) => {
                        self.push_clear_input_stream(voices, handle);
                    }
                    InputStreamHandle::StereoFloat32(handle) => {
                        self.push_clear_input_stream(voices, handle);
                    }
                    InputStreamHandle::Err(_) => ()
                }
            },
            InputHandle::Value(handle) => {
                match handle {
                    InputValueHandle::Float32(handle) => {
                        self.push_clear_input_value(voices, handle);
                    }
                    InputValueHandle::Float64(handle) => {
                        self.push_clear_input_value(voices, handle);
                    }
                    InputValueHandle::Int32(handle) => {
                        self.push_clear_input_value(voices, handle);
                    }
                    InputValueHandle::Int64(handle) => {
                        self.push_clear_input_value(voices, handle);
                    }
                    InputValueHandle::Bool(handle) => {
                        self.push_clear_input_value(voices, handle);
                    }
                    InputValueHandle::Object { .. } => todo!(),
                    InputValueHandle::Err(_) => (),
                }
            },
            _ => ()
        }
    }

    fn push_clear_input_stream<T>(&mut self, voices: Arc<Mutex<Voices>>, handle: Endpoint<InputStream<T>>) 
        where
            T: Copy + Default + StreamType + Send + Sync + 'static {

        // Push the clear action
        self.push(
            ClearStream {
                voices,
                handle,
                buffer: vec![T::default(); 1024]
            }
        );
    }

    fn push_clear_input_value<T>(&mut self, voices: Arc<Mutex<Voices>>, handle: Endpoint<InputValue<T>>) 
        where
            T: Copy + Default + SetInputValue + 'static {

        // Push the clear action
        self.push(
            ClearValue {
                voices,
                handle
            }
        );
    }

    fn process_cable(
        &mut self,
        src_voices: Arc<Mutex<Voices>>,
        src_handle: OutputHandle,
        dst_voices: Arc<Mutex<Voices>>,
        dst_handle: InputHandle) -> Result<(), &'static str> {

        match (src_handle, dst_handle) {
            (OutputHandle::Stream(src_handle), InputHandle::Stream(dst_handle)) => self
                .push_connection_stream_to_stream(
                    src_voices,
                    src_handle,
                    dst_voices,
                    dst_handle
                )?,
            (OutputHandle::Event(src_handle), InputHandle::Event(dst_handle)) => self
                .push_connection_event_to_event(
                    src_voices,
                    src_handle,
                    dst_voices,
                    dst_handle
                )?,
            (OutputHandle::Value(src_handle), InputHandle::Value(dst_handle)) => self
                .push_connection_value_to_value(
                    src_voices,
                    src_handle,
                    dst_voices,
                    dst_handle
                )?,
            _ => return Err("Connection not between different endpoint kinds")
        };

        Ok(())
    }

    fn push_connection_stream_to_stream(
        &mut self,
        src_voices: Arc<Mutex<Voices>>,
        src_handle: OutputStreamHandle,
        dst_voices: Arc<Mutex<Voices>>,
        dst_handle: InputStreamHandle) -> Result<(), &'static str> {
        
        match (src_handle, dst_handle) {
            (OutputStreamHandle::MonoFloat32(src_handle), InputStreamHandle::MonoFloat32(dst_handle)) => self
                .push_copy_stream(
                    src_voices,
                    src_handle,
                    dst_voices,
                    dst_handle
                ),
            (OutputStreamHandle::StereoFloat32(src_handle), InputStreamHandle::StereoFloat32(dst_handle)) => self
                .push_copy_stream(
                    src_voices,
                    src_handle,
                    dst_voices,
                    dst_handle
                ),
            (OutputStreamHandle::MonoFloat32(src_handle), InputStreamHandle::StereoFloat32(dst_handle)) => self
                .push_copy_convert_stream(
                    src_voices,
                    src_handle,
                    dst_voices,
                    dst_handle
                ),
            _ => return Err("Endpoints streams types are not compatible")
        }

        Ok(())
    }

    fn push_connection_event_to_event(
        &mut self,
        src_voices: Arc<Mutex<Voices>>,
        src_handle: OutputEventHandle,
        dst_voices: Arc<Mutex<Voices>>,
        dst_handle: InputEventHandle) -> Result<(), &'static str> {
        
        match src_handle {
            OutputEventHandle::Primitive(src_handle) => match dst_handle {
                InputEventHandle::Primitive(dst_handle) => self
                    .push_copy_event(
                        src_voices,
                        src_handle,
                        dst_voices,
                        dst_handle
                    ),
                InputEventHandle::Object { .. } => return Err("Endpoints event types are not compatible"),
                InputEventHandle::Err(e) => return Err(e),
            }
            OutputEventHandle::Object { handle: src_handle, object } => match dst_handle {
                InputEventHandle::Primitive(dst_handle) => todo!(),
                InputEventHandle::Object { handle: dst_handle, object } => self
                    .push_copy_event(
                        src_voices,
                        src_handle,
                        dst_voices,
                        dst_handle
                    ),
                InputEventHandle::Err(e) => return Err(e),
            }
            OutputEventHandle::Err(e) => return Err(e),
        }

        Ok(())
    }

    fn push_connection_value_to_value(
        &mut self,
        src_voices: Arc<Mutex<Voices>>,
        src_handle: OutputValueHandle,
        dst_voices: Arc<Mutex<Voices>>,
        dst_handle: InputValueHandle) -> Result<(), &'static str> {

        match src_handle {
            OutputValueHandle::Float32(src_handle) => match dst_handle {
                InputValueHandle::Float32(dst_handle) => self
                    .push_copy_value(
                        src_voices,
                        src_handle,
                        dst_voices,
                        dst_handle
                    ),
                InputValueHandle::Float64(dst_handle) => self
                    .push_copy_convert_value(
                        src_voices,
                        src_handle,
                        dst_voices,
                        dst_handle
                    ),
                InputValueHandle::Int32(dst_handle) => self
                    .push_copy_convert_value(
                        src_voices,
                        src_handle,
                        dst_voices,
                        dst_handle
                    ),
                InputValueHandle::Int64(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Bool(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Object { .. } => return Err("Endpoints value types are not compatible"),
                InputValueHandle::Err(e) => return Err(e),
            }
            OutputValueHandle::Float64(src_handle) => match dst_handle {
                InputValueHandle::Float32(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Float64(dst_handle) => self.push_copy_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Int32(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Int64(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Bool(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Object { .. } => return Err("Endpoints value types are not compatible"),
                InputValueHandle::Err(e) => return Err(e),
            }
            OutputValueHandle::Int32(src_handle) => match dst_handle {
                InputValueHandle::Float32(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Float64(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Int32(dst_handle) => self.push_copy_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Int64(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Bool(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Object { .. } => return Err("Endpoints value types are not compatible"),
                InputValueHandle::Err(e) => return Err(e),
            }
            OutputValueHandle::Int64(src_handle) => match dst_handle {
                InputValueHandle::Float32(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Float64(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Int32(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Int64(dst_handle) => self.push_copy_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Bool(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Object { .. } => return Err("Endpoints value types are not compatible"),
                InputValueHandle::Err(e) => return Err(e),
            }
            OutputValueHandle::Bool(src_handle) => match dst_handle {
                InputValueHandle::Float32(dst_handle) => self
                    .push_copy_convert_value(
                        src_voices,
                        src_handle,
                        dst_voices,
                        dst_handle
                    ),
                InputValueHandle::Float64(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Int32(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Int64(dst_handle) => self.push_copy_convert_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Bool(dst_handle) => self.push_copy_value(src_voices, src_handle, dst_voices, dst_handle),
                InputValueHandle::Object { .. } => return Err("Endpoints value types are not compatible"),
                InputValueHandle::Err(e) => return Err(e),
            }
            OutputValueHandle::Object { handle, object } => match dst_handle {
                InputValueHandle::Object { handle: dst_handle, object: dst_object } => {
                    if object != dst_object {
                        return Err("Endpoints value types are not compatible");
                    }
                    todo!()
                }
                InputValueHandle::Err(e) => return Err(e),
                _ => return Err("Endpoints value types are not compatible"),
            }
            OutputValueHandle::Err(e) => return Err(e)
        }

        Ok(())
    }

    fn push_copy_stream<T>(
        &mut self,
        src_voices: Arc<Mutex<Voices>>,
        src_handle: Endpoint<OutputStream<T>>,
        dst_voices: Arc<Mutex<Voices>>,
        dst_handle: Endpoint<InputStream<T>>)
        where
            T: StreamType + Default + Send + Sync + 'static {

        let buffer = vec![T::default(); 1024];
        self.push(
            CopyStream {
                src_voices,
                src_handle,
                dst_voices,
                dst_handle,
                buffer
            }
        );
    }

    fn push_copy_convert_stream<T, U>(
        &mut self,
        src_voices: Arc<Mutex<Voices>>,
        src_handle: Endpoint<OutputStream<T>>,
        dst_voices: Arc<Mutex<Voices>>,
        dst_handle: Endpoint<InputStream<U>>)
        where
            T: StreamType + Default + Send + Sync + 'static + ConvertTo<U>,
            U: StreamType + Default + Send + Sync + 'static {

        let src_buffer = vec![T::default(); 1024];
        let dst_buffer = vec![U::default(); 1024];
        self.push(
            ConvertCopyStream {
                src_voices,
                src_handle,
                src_buffer,
                dst_voices,
                dst_handle,
                dst_buffer
            }
        );
    }

    fn push_copy_event(
        &mut self,
        src_voices: Arc<Mutex<Voices>>,
        src_handle: Endpoint<OutputEvent>,
        dst_voices: Arc<Mutex<Voices>>,
        dst_handle: Endpoint<InputEvent>) {

        self.push(
            CopyEvent {
                src_voices,
                src_handle,
                dst_voices,
                dst_handle,
            }
        );
    }

    fn push_copy_value<T>(
        &mut self,
        src_voices: Arc<Mutex<Voices>>,
        src_handle: Endpoint<OutputValue<T>>,
        dst_voices: Arc<Mutex<Voices>>,
        dst_handle: Endpoint<InputValue<T>>)
        where
            T: Copy + SetInputValue + for<'a> GetOutputValue<Output<'a> = T> + 'static {

        self.push(
            CopyValue {
                src_voices,
                src_handle,
                dst_voices,
                dst_handle,
            }
        );
    }

    fn push_copy_convert_value<T, U>(
        &mut self,
        src_voices: Arc<Mutex<Voices>>,
        src_handle: Endpoint<OutputValue<T>>,
        dst_voices: Arc<Mutex<Voices>>,
        dst_handle: Endpoint<InputValue<U>>)
        where
            U: Copy + SetInputValue + 'static,
            T: Copy + for<'a> GetOutputValue<Output<'a> = T> + ConvertTo<U> + 'static {

        self.push(
            CopyConvertValue {
                src_voices,
                src_handle,
                dst_voices,
                dst_handle,
            }
        );
    }
}

pub fn is_connection_supported(src_node: &Node, src_endpoint: &NodeEndpoint, dst_node: &Node, dst_endpoint: &NodeEndpoint) -> Result<(), &'static str> {
    let mut actions = Actions::new();
    let src_voices = src_node.voices();
    let src_handle = src_endpoint.handle();
    let dst_voices = dst_node.voices();
    let dst_handle = dst_endpoint.handle();

    if let (EndpointHandle::Output(src_handle), EndpointHandle::Input(dst_handle)) = (src_handle, dst_handle) {
        if let (OutputEndpoint::Endpoint(src_handle), InputEndpoint::Endpoint(dst_handle)) = (src_handle, dst_handle) {
                return actions.process_cable(src_voices, src_handle.clone(), dst_voices, dst_handle.clone());
        } else {
            return Err("Connection not between endpoints");
        }
    } else {
        return Err("Connection not from an output to an input");
    }
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