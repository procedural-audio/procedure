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

use super::node;
use super::voices::*;

lazy_static::lazy_static! {
    static ref ACTIONS: RwLock<Option<Vec<Action>>> = RwLock::new(None);
    // static ref GRAPH_PLAYING: RwLock<Option<Graph>> = RwLock::new(None);
    // static ref GRAPH_PENDING: RwLock<Option<Graph>> = RwLock::new(None);
}

#[frb(sync)]
pub fn set_patch(mut graph: Graph) {
    println!("Updating patch ({} nodes, {} cables)", graph.nodes.len(), graph.cables.len());
    
    // Prepare the graph for playback
    graph.sort_nodes_topologically().unwrap();

    let actions = generate_graph_actions(&graph);

    *ACTIONS.write().unwrap() = Some(actions);
}

#[frb(sync)]
pub fn clear_patch() {
    println!("Cleared patch");
    *ACTIONS.write().unwrap() = None;
}

#[frb(ignore)]
#[no_mangle]
pub unsafe extern "C" fn prepare_patch(sample_rate: f64, block_size: u32) {
    println!("Should re-generate the graph here");
}

#[frb(ignore)]
#[no_mangle]
pub unsafe extern "C" fn process_patch(audio: *const *mut f32, channels: u32, frames: u32, midi: *mut u8, size: u32) {
    let mut buffer_1 = [0.0f32];
    let mut buffer_2 = [0.0];
    let mut buffer_3 = [0.0];
    let mut buffer_4 = [0.0];
    let mut buffer_5 = [0.0];
    let mut buffer_6 = [0.0];
    let mut buffer_7 = [0.0];
    let mut buffer_8 = [0.0];

    let mut buffer = [
        buffer_1.as_mut_slice(),
        buffer_2.as_mut_slice(),
        buffer_3.as_mut_slice(),
        buffer_4.as_mut_slice(),
        buffer_5.as_mut_slice(),
        buffer_6.as_mut_slice(),
        buffer_7.as_mut_slice(),
        buffer_8.as_mut_slice(),
    ];

    for i in 0..usize::min(channels as usize, buffer.len()) {
        buffer[i] = unsafe {
            std::slice::from_raw_parts_mut(*audio.offset(i as isize), frames as usize)
        };
    }

    let midi = unsafe { std::slice::from_raw_parts_mut(midi, size as usize) };

    // TODO: Update patch from pending patch if it exists
    if let Ok(mut actions) = ACTIONS.try_write() {
        if let Some(actions) = &mut *actions {
            for action in actions {
                action.execute(buffer.as_mut_slice(), midi);
            }
        }
    }
}

#[frb(opaque)]
#[derive(Clone)]
pub struct Graph {
    nodes: Vec<Node>,
    cables: Vec<Cable>,
}

impl Graph {
    #[frb(sync)]
    pub fn new() -> Self {
        Self {
            nodes: Vec::new(),
            cables: Vec::new(),
        }
    }

    #[frb(sync)]
    pub fn add_cable(
        &mut self,
        src_node: &Node,
        src_endpoint: &NodeEndpoint,
        dst_node: &Node,
        dst_endpoint: &NodeEndpoint) {

        self.cables.push(
            Cable {
                source: Connection {
                    node: src_node.clone(),
                    endpoint: src_endpoint.clone()
                },
                destination: Connection {
                    node: dst_node.clone(),
                    endpoint: dst_endpoint.clone()
                }
            }
        );
    }

    #[frb(sync)]
    pub fn add_node(&mut self, node: &Node) {
        self.nodes.push(node.clone());
    }

    #[frb(ignore)]
    fn sort_nodes_topologically(&mut self) -> Result<(), String> {
        let node_count = self.nodes.len();

        // Map from node_id to its current index in self.nodes
        let node_id_to_index: HashMap<u32, usize> = self.nodes
            .iter()
            .enumerate()
            .map(|(index, node)| (node.id, index))
            .collect();

        // Initialize in-degree and adjacency list (successors)
        let mut in_degree = vec![0; node_count];
        let mut adj = vec![Vec::new(); node_count];

        // Build the graph representation
        for cable in &self.cables {
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
                self.nodes.swap(i, target);
                index_map[i] = index_map[target];
                index_map[target] = target;
            }
        }

        Ok(())
    }
}

#[frb(ignore)]
trait ExecuteAction {
    fn execute(&mut self, num_frames: usize);
}

#[frb(ignore)]
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

#[frb(ignore)]
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

#[frb(ignore)]
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

#[frb(ignore)]
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

#[frb(ignore)]
enum Action {
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

    // Recieve events
    ReceiveValues {
        voices: Arc<Mutex<Voices>>,
        handle: Endpoint<InputValue<cmajor::value::Value>>,
        queue: Arc<ArrayQueue<cmajor::value::Value>>,
    },

    // Recieve events
    ReceiveEvents {
        voices: Arc<Mutex<Voices>>,
        handle: Endpoint<InputEvent>,
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
    #[frb(ignore)]
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
            
            // Recieve UI values
            Action::ReceiveValues { voices, handle, queue } => {
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

#[frb(ignore)]
fn generate_graph_actions(graph: &Graph) -> Vec<Action> {
    let mut actions = Vec::new();

    // Generate actions for each node
    for node in &graph.nodes {
        generate_node_actions(&mut actions, node, graph);
    }

    return actions;
}

fn generate_node_actions(actions: &mut Vec<Action>, dst_node: &Node, graph: &Graph) {
    // Copy node input data
    for dst_endpoint in dst_node.get_inputs().iter() {
        let mut filled = false;

        // Generate actions for each connected cable
        graph
            .cables
            .iter()
            .filter(| cable | &cable.destination.node == dst_node && &cable.destination.endpoint == dst_endpoint)
            .for_each(| cable | {
                println!(" - Copy {} to {}", cable.source.node.id, dst_node.id);

                generate_connection_actions(
                    actions,
                    cable.source.node.voices(),
                    cable.source.endpoint.endpoint.clone(),
                    dst_node.voices(),
                    dst_endpoint.endpoint.clone()
                );

                filled = true;
            });
        
        // Generate actions to recieve widget updates
        if let EndpointHandle::Widget(handle) = &dst_endpoint.endpoint {
            filled = true;

            match handle {
                WidgetHandle::Value { handle, queue } => {
                    println!(" - Recieve widget value updates for node {}", dst_node.id);
                    actions.push(
                        Action::ReceiveValues {
                            voices: dst_node.voices(),
                            handle: handle.clone(),
                            queue: queue.clone(),
                        }
                    );
                },
                WidgetHandle::Event { handle, queue } => {
                    println!(" - Recieve widget event updates for node {}", dst_node.id);
                    actions.push(
                        Action::ReceiveEvents {
                            voices: dst_node.voices(),
                            handle: handle.clone(),
                            queue: queue.clone(),
                        }
                    );
                }
            };
        }
        
        // Generate actions to fill missing input streams
        if !filled {
            println!(" - Fill input of node {}", dst_node.id);
            generate_clear_stream_actions(actions, dst_node.voices(), dst_endpoint.endpoint.clone());
        }
    }

    // Generate any external input actions
    generate_external_input_actions(actions, dst_node);

    // Generate actions for each node advance
    println!(" - Advance node {}", dst_node.id);
    actions.push(Action::Advance(dst_node.voices()));

    // Generate any external output actions
    generate_external_output_actions(actions, dst_node);
}

#[frb(ignore)]
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

#[frb(ignore)]
fn generate_external_input_actions(actions: &mut Vec<Action>, node: &Node) {
    for endpoint in &node.get_inputs() {
        match endpoint.endpoint {
            EndpointHandle::ExternalInput { handle, channel } => match handle {
                InputHandle::Stream(handle) => {
                    match handle {
                        InputStreamHandle::MonoFloat32(handle) => {
                            println!(" - External mono input channel {} to node {}", channel, node.id);
                            actions.push(
                                Action::InputStreamMonoFloat32 {
                                    voices: node.voices(),
                                    handle,
                                    channel
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
                                    channel
                                }
                            );
                        }
                    }
                }
                InputHandle::Event(_) => println!(" - External events are not supported"),
                InputHandle::Value(_) => println!(" - External values are not supported")
            }
            _ => ()
        }
    }
}

#[frb(ignore)]
fn generate_external_output_actions(actions: &mut Vec<Action>, node: &Node) {
    for endpoint in &node.get_outputs() {
        match endpoint.endpoint {
            EndpointHandle::ExternalOutput { handle, channel } => match handle {
                OutputHandle::Stream(handle) => {
                    match handle {
                        OutputStreamHandle::MonoFloat32(handle) => {
                            println!(" - External mono ouput channel {} to node {}", channel, node.id);
                            actions.push(
                                Action::OutputStreamMonoFloat32 {
                                    voices: node.voices(),
                                    handle,
                                    channel
                                }
                            );
                        },
                        OutputStreamHandle::StereoFloat32(handle) => {
                            println!(" - External stereo output channel {} to node {}", channel, node.id);
                            let buffer = vec![[0.0, 0.0]; 1024];
                            actions.push(
                                Action::OutputStreamStereoFloat32 {
                                    voices: node.voices(),
                                    handle,
                                    buffer,
                                    channel
                                }
                            );
                        }
                    }
                }
                OutputHandle::Event(_) => println!(" - External events are not supported"),
                OutputHandle::Value(_) => println!(" - External values are not supported")
            }
            _ => ()
        }
    }
}

#[frb(ignore)]
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
