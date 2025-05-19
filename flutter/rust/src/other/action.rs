use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;

use crate::api::endpoint::NodeEndpoint;
use crate::api::node::*;

use cmajor::performer::Performer;
use cmajor::*;

use crossbeam::atomic::AtomicCell;
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
use value::Value;
use value::ValueRef;

use crate::api::graph::*;
use crate::other::voices::*;
use crate::other::handle::*;

use super::stream::*;
use super::value::*;
use super::event::*;

pub struct IO<'a> {
    pub audio: &'a mut [&'a mut [f32]],
    pub midi_input: &'a [u32],
    pub midi_output: &'a mut Vec<u32>,
}

impl<'a> IO<'a> {
    pub fn get_num_frames(&self) -> usize {
        self
            .audio
            .get(0)
            .unwrap()
            .len()
    }
}


pub trait ExecuteAction {
    fn execute(&mut self, io: &mut IO);
}

struct Advance(Arc<Mutex<Performer>>);

impl ExecuteAction for Advance {
    fn execute(&mut self, io: &mut IO) {
        let num_frames = io.get_num_frames();
        let mut voices = self
            .0
            .try_lock()
            .unwrap();

        voices.set_block_size(num_frames as u32);
        voices.advance();
    }
}

pub struct Actions {
    actions: Vec<Box<dyn ExecuteAction + Send + Sync>>,
}

impl ExecuteAction for Actions {
    fn execute(&mut self, io: &mut IO) {
        for action in self.actions.iter_mut() {
            action.execute(io);
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
        self.push(Advance(dst_node.performer.clone()));
    
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
            OutputEndpoint::Endpoint { .. } => {
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
                            src_node.performer.clone(),
                            src_handle.clone(),
                            dst_node.performer.clone(),
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
            self.process_input_endpoint_clear(node.performer.clone(), handle.clone());
        }
    }

    fn process_input_external(&mut self, node: &Node, handle: &InputHandle, channel: usize) {
        match handle {
            InputHandle::Stream(_) => println!(" - External input streams are not supported"),
            InputHandle::Event( InputEventHandle { handle, types }) => {
                self.push(
                    ExternalInputEvent {
                        voices: node.performer.clone(),
                        handle: handle.clone(),
                    }
                );
            }
            InputHandle::Value(_) => println!(" - External values are not supported")
        }
    }

    fn process_output_external(&mut self, node: &Node, handle: &OutputHandle, channel: usize) {
        match handle {
            OutputHandle::Stream { handle, feedback } => {
                match handle {
                    OutputStreamHandle::MonoFloat32(handle) => {
                        println!(" - External mono ouput channel {} to node {}", channel, node.id);
                        let buffer = vec![0.0; 1024];
                        self.push(
                            ExternalOutputStream {
                                voices: node.performer.clone(),
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
                                voices: node.performer.clone(),
                                handle: *handle,
                                buffer,
                                channel,
                            }
                        );
                    }
                    OutputStreamHandle::Err(e) => ()
                }
            }
            OutputHandle::Event { handle, feedback } => {
                self.push(
                    ExternalOutputEvent {
                        voices: node.performer.clone(),
                        handle: handle.handle.clone(),
                    }
                );
            }
            OutputHandle::Value { .. } => println!(" - External values are not supported")
        }
    }

    fn process_input_widget(&mut self, node: &Node, handle: &InputHandle, queue: &Arc<ArrayQueue<Value>>) {
        match handle {
            InputHandle::Stream(handle) => {
                println!(" - Unsupported widget input stream");
            },
            InputHandle::Event(InputEventHandle { handle, types }) => {
                self.push(
                    ReceiveEvents {
                        voices: node.performer.clone(),
                        handle: handle.clone(),
                        queue: queue.clone(),
                    }
                );
            },
            InputHandle::Value(handle) => {
                println!(" - Receive values from widget");
                match handle {
                    InputValueHandle::Float32(handle) => {
                        self.process_input_widget_value(node, handle, queue);
                    }
                    InputValueHandle::Float64(handle) => {
                        self.process_input_widget_value(node, handle, queue);
                    }
                    InputValueHandle::Int32(handle) => {
                        self.process_input_widget_value(node, handle, queue);
                    }
                    InputValueHandle::Int64(handle) => {
                        self.process_input_widget_value(node, handle, queue);
                    }
                    InputValueHandle::Bool(handle) => {
                        self.process_input_widget_value(node, handle, queue);
                    }
                    InputValueHandle::Object { .. } => todo!(),
                    InputValueHandle::Err(_) => println!(" - Unsupported widget input value"),
                }
            },
        }
    }

    fn process_input_widget_value<T>(&mut self, node: &Node, handle: &Endpoint<InputValue<T>>, queue: &Arc<ArrayQueue<Value>>)
        where
            T: Copy + SetInputValue + Send + Sync + 'static + for<'a> TryFrom<ValueRef<'a>> {

        self.push(
            ReceiveValue {
                voices: node.performer.clone(),
                handle: handle.clone(),
                queue: queue.clone(),
            }
        );
    }

    fn process_output_widget(&mut self, node: &Node, handle: &OutputHandle, queue: &Arc<ArrayQueue<Value>>) {
        match handle {
            OutputHandle::Stream { handle, feedback } => {
                println!(" - Unsupported widget output stream");
            },
            OutputHandle::Event { handle, feedback } => {
                println!(" - Send events to widget");
                self.push(
                    SendEvents {
                        voices: node.performer.clone(),
                        handle: handle.handle.clone(),
                        queue: queue.clone(),
                    }
                );
            },
            OutputHandle::Value { handle, feedback } => {
                println!(" - Unsupported widget output value");
            },
        }
    }

    fn process_input_endpoint_clear(&mut self, voices: Arc<Mutex<Performer>>, handle: InputHandle) {
        match handle {
            InputHandle::Stream(handle) => {
                match handle {
                    InputStreamHandle::MonoFloat32(handle) => {
                        let buffer = vec![0.0; 1024];
                        self.push( ClearStream { voices, handle, buffer });
                    }
                    InputStreamHandle::StereoFloat32(handle) => {
                        let buffer = vec![[0.0; 2]; 1024];
                        self.push( ClearStream { voices, handle, buffer });
                    }
                    InputStreamHandle::Err(_) => ()
                }
            },
            InputHandle::Value(handle) => {
                match handle {
                    InputValueHandle::Float32(handle) => {
                        self.push( ClearValue { voices, handle });
                    }
                    InputValueHandle::Float64(handle) => {
                        self.push( ClearValue { voices, handle });
                    }
                    InputValueHandle::Int32(handle) => {
                        self.push( ClearValue { voices, handle });
                    }
                    InputValueHandle::Int64(handle) => {
                        self.push( ClearValue { voices, handle });
                    }
                    InputValueHandle::Bool(handle) => {
                        self.push( ClearValue { voices, handle });
                    }
                    InputValueHandle::Object { .. } => todo!(),
                    InputValueHandle::Err(_) => (),
                }
            },
            _ => ()
        }
    }

    fn process_cable(
        &mut self,
        src_voices: Arc<Mutex<Performer>>,
        src_handle: OutputHandle,
        dst_voices: Arc<Mutex<Performer>>,
        dst_handle: InputHandle) -> Result<(), &'static str> {

        match (src_handle, dst_handle) {
            (OutputHandle::Stream { handle, feedback }, InputHandle::Stream(dst_handle)) => self
                .connect_streams(src_voices, handle, feedback, dst_voices, dst_handle)?,
            (OutputHandle::Event { handle, feedback }, InputHandle::Event(dst_handle)) => self
                .connect_events(src_voices, handle, feedback, dst_voices, dst_handle)?,
            (OutputHandle::Value { handle, feedback }, InputHandle::Value(dst_handle)) => self
                .connect_values(src_voices, handle, feedback, dst_voices, dst_handle)?,
            _ => return Err("Connection not between different endpoint kinds")
        };

        Ok(())
    }

    fn connect_streams(
        &mut self,
        src_voices: Arc<Mutex<Performer>>,
        src_handle: OutputStreamHandle,
        feedback: Arc<AtomicCell<f32>>,
        dst_voices: Arc<Mutex<Performer>>,
        dst_handle: InputStreamHandle) -> Result<(), &'static str> {
        
        match (src_handle, dst_handle) {
            (OutputStreamHandle::MonoFloat32(src), InputStreamHandle::MonoFloat32(dst)) => self
                .copy_stream(src_voices, src, feedback, dst_voices, dst),
            (OutputStreamHandle::StereoFloat32(src), InputStreamHandle::StereoFloat32(dst)) => self
                .copy_stream(src_voices, src, feedback, dst_voices, dst),
            _ => return Err("Endpoints streams types are not compatible")
        }

        Ok(())
    }

    fn connect_events(
        &mut self,
        src_voices: Arc<Mutex<Performer>>,
        src_handle: OutputEventHandle,
        feedback: Arc<AtomicCell<usize>>,
        dst_voices: Arc<Mutex<Performer>>,
        dst_handle: InputEventHandle) -> Result<(), &'static str> {

        println!(" - Connect events");
        self.copy_event(src_voices, src_handle.handle, feedback, dst_voices, dst_handle.handle);

        Ok(())
    }

    fn connect_values(
        &mut self,
        src_voices: Arc<Mutex<Performer>>,
        src_handle: OutputValueHandle,
        feedback: Arc<AtomicCell<bool>>,
        dst_voices: Arc<Mutex<Performer>>,
        dst_handle: InputValueHandle) -> Result<(), &'static str> {

        println!(" - Connect values");

        match (src_handle, dst_handle) {
            (OutputValueHandle::Float32(src), InputValueHandle::Float32(dst)) => self
                .copy_value(src_voices, src, feedback, dst_voices, dst),
            (OutputValueHandle::Float64(src), InputValueHandle::Float64(dst)) => self
                .copy_value(src_voices, src, feedback, dst_voices, dst),
            (OutputValueHandle::Int32(src), InputValueHandle::Int32(dst)) => self
                .copy_value(src_voices, src, feedback, dst_voices, dst),
            (OutputValueHandle::Int64(src), InputValueHandle::Int64(dst)) => self
                .copy_value(src_voices, src, feedback, dst_voices, dst),
            (OutputValueHandle::Bool(src), InputValueHandle::Bool(dst)) => self
                .copy_value(src_voices, src, feedback, dst_voices, dst),
            _ => return Err("Endpoints value types are not compatible"),
        }

        Ok(())
    }

    fn copy_stream<T>(
        &mut self,
        src_voices: Arc<Mutex<Performer>>,
        src_handle: Endpoint<OutputStream<T>>,
        feedback: Arc<AtomicCell<f32>>,
        dst_voices: Arc<Mutex<Performer>>,
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
                buffer,
                feedback
            }
        );
    }

    fn copy_event(
        &mut self,
        src_voices: Arc<Mutex<Performer>>,
        src_handle: Endpoint<OutputEvent>,
        feedback: Arc<AtomicCell<usize>>,
        dst_voices: Arc<Mutex<Performer>>,
        dst_handle: Endpoint<InputEvent>) {

        self.push(
            CopyEvent {
                src_voices,
                src_handle,
                dst_voices,
                dst_handle,
                feedback
            }
        );
    }

    fn copy_value<T>(
        &mut self,
        src_voices: Arc<Mutex<Performer>>,
        src_handle: Endpoint<OutputValue<T>>,
        feedback: Arc<AtomicCell<bool>>,
        dst_voices: Arc<Mutex<Performer>>,
        dst_handle: Endpoint<InputValue<T>>)
        where
            T: Copy + Default + Send + Sync + PartialEq + SetInputValue + for<'a> GetOutputValue<Output<'a> = T> + 'static {

        self.push(
            CopyValue {
                src_voices,
                src_handle,
                dst_voices,
                dst_handle,
                feedback,
                previous: T::default(),
            }
        );
    }
}

pub fn is_connection_supported(src_node: &Node, src_endpoint: &NodeEndpoint, dst_node: &Node, dst_endpoint: &NodeEndpoint) -> Result<(), &'static str> {
    let mut actions = Actions::new();
    let src_voices = src_node.performer.clone();
    let src_handle = src_endpoint.handle();
    let dst_voices = dst_node.performer.clone();
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