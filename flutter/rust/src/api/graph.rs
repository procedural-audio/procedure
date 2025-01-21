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
    pub fn add_cable(&mut self, cable: &Cable) {
        self.cables.push(cable.clone());
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
            let &source_index = node_id_to_index.get(&cable.source.node_id)
                .ok_or_else(|| format!("Source node_id {} not found in nodes", cable.source.node_id))?;
            let &dest_index = node_id_to_index.get(&cable.destination.node_id)
                .ok_or_else(|| format!("Destination node_id {} not found in nodes", cable.destination.node_id))?;

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
    fn execute(&mut self);
}

#[frb(ignore)]
struct CopyStream<T: StreamType> {
    src_performer: Arc<Mutex<Performer>>,
    src_handle: Endpoint<OutputStream<T>>,
    dst_performer: Arc<Mutex<Performer>>,
    dst_handle: Endpoint<InputStream<T>>,
    buffer: Vec<T>,
}

impl<T: StreamType> ExecuteAction for CopyStream<T> {
    fn execute(&mut self) {
        self.src_performer
            .try_lock()
            .unwrap()
            .read(self.src_handle, self.buffer.as_mut_slice());

        self.dst_performer
            .try_lock()
            .unwrap()
            .write(self.dst_handle, self.buffer.as_slice());
    }
}

#[frb(ignore)]
struct ClearStream<T: StreamType + Default> {
    dst_performer: Arc<Mutex<Performer>>,
    dst_handle: Endpoint<InputStream<T>>,
    buffer: Vec<T>,
}

impl<T: StreamType + Default> ExecuteAction for ClearStream<T> {
    fn execute(&mut self) {
        self.dst_performer
            .try_lock()
            .unwrap()
            .write(self.dst_handle, self.buffer.as_slice());
    }
}

#[frb(ignore)]
struct CopyValue<T> {
    src_performer: Arc<Mutex<Performer>>,
    src_handle: Endpoint<OutputValue<T>>,
    dst_performer: Arc<Mutex<Performer>>,
    dst_handle: Endpoint<InputValue<T>>,
}

impl<T> ExecuteAction for CopyValue<T>
where
    T: Copy + SetInputValue + for<'a> GetOutputValue<Output<'a> = T>,
{
    fn execute(&mut self) {
        let mut src_performer = self.src_performer
            .try_lock()
            .unwrap();

        let temp = src_performer.get(self.src_handle);

        let mut dst_performer = self.dst_performer
            .try_lock()
            .unwrap();

        dst_performer.set(self.dst_handle, temp);
    }
}

#[frb(ignore)]
struct CopyEvent {
    src_performer: Arc<Mutex<Performer>>,
    src_handle: Endpoint<OutputEvent>,
    dst_performer: Arc<Mutex<Performer>>,
    dst_handle: Endpoint<InputEvent>,
}

impl ExecuteAction for CopyEvent {
    fn execute(&mut self) {
        let mut src_performer = self.src_performer
            .try_lock()
            .unwrap();
        let mut dst_performer = self.dst_performer
            .try_lock()
            .unwrap();

        src_performer.fetch(self.src_handle, | _i, event | {
            dst_performer.post(self.dst_handle, event).unwrap();
        }).unwrap();
    }
}

#[frb(ignore)]
enum Action {
    Process(Arc<Mutex<Performer>>),

    // Copy streams
    CopyStreamFloat32(CopyStream<f32>),
    CopyStreamFloat64(CopyStream<f64>),
    CopyStreamInt32(CopyStream<i32>),
    CopyStreamInt64(CopyStream<i64>),

    // Clear streams
    ClearStreamFloat32(ClearStream<f32>),
    ClearStreamFloat64(ClearStream<f64>),
    ClearStreamInt32(ClearStream<i32>),
    ClearStreamInt64(ClearStream<i64>),

    // Copy events
    CopyEvent(CopyEvent),

    // Update event
    ReceiveEvents {
        voices: Voices,
        handle: Endpoint<InputEvent>,
        queue: Arc<ArrayQueue<cmajor::value::Value>>,
    },

    // Copy values
    CopyValueFloat32(CopyValue<f32>),
    CopyValueFloat64(CopyValue<f64>),
    CopyValueInt32(CopyValue<i32>),
    CopyValueInt64(CopyValue<i64>),
    CopyValueBool(CopyValue<bool>),

    InputStream {
        performer: Arc<Mutex<Performer>>,
        handle: Endpoint<InputStream<f32>>,
        channel: usize,
    },
    OutputStream {
        performer: Arc<Mutex<Performer>>,
        handle: Endpoint<OutputStream<f32>>,
        channel: usize,
    }
}

impl Action {
    #[frb(ignore)]
    pub fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let num_frames = audio
            .get(0)
            .unwrap()
            .len() as u32;

        match self {
            Action::Process(performer) => {
                match performer.try_lock() {
                    Ok(mut performer) => {
                        performer.set_block_size(num_frames);
                        performer.advance();
                    }
                    Err(_) => println!("Failed to lock performer"),
                }
            },

            // Copy streams
            Action::CopyStreamFloat32(action) => action.execute(),
            Action::CopyStreamFloat64(action) => action.execute(),
            Action::CopyStreamInt32(action) => action.execute(),
            Action::CopyStreamInt64(action) => action.execute(),

            // Fill streams
            Action::ClearStreamFloat32(action) => action.execute(),
            Action::ClearStreamFloat64(action) => action.execute(),
            Action::ClearStreamInt32(action) => action.execute(),
            Action::ClearStreamInt64(action) => action.execute(),

            // Copy event
            Action::CopyEvent(action) => action.execute(),
            
            // Recieve UI events
            Action::ReceiveEvents { voices, handle, queue } => {
                while let Some(value) = queue.pop() {
                    match voices {
                        Voices::Mono(ref performer) => {
                            match performer.try_lock() {
                                Ok(mut performer) => {
                                    match performer.post(*handle, &value) {
                                        Ok(_) => (),
                                        Err(e) => println!(" > Failed to post event: {}", e),
                                    }
                                }
                                Err(e) => println!("Failed to lock performer: {}", e),
                            }
                        },
                        Voices::Poly(ref performers) => {
                            for performer in performers.iter() {
                                match performer.try_lock() {
                                    Ok(mut performer) => {
                                        match performer.post(*handle, &value) {
                                            Ok(_) => (),
                                            Err(e) => println!(" > Failed to post event: {}", e),
                                        }
                                    }
                                    Err(e) => println!("Failed to lock performer: {}", e),
                                }
                            }
                        }
                    }
                }
            }

            // Copy values
            Action::CopyValueFloat32(action) => action.execute(),
            Action::CopyValueFloat64(action) => action.execute(),
            Action::CopyValueInt32(action) => action.execute(),
            Action::CopyValueInt64(action) => action.execute(),
            Action::CopyValueBool(action) => action.execute(),
            Action::InputStream { performer, handle, channel } => {
                match performer.try_lock() {
                    Ok(performer) => {
                        if let Some(channel) = audio.get(*channel) {
                            performer.write(*handle, channel);
                        }
                    }
                    Err(_) => println!("Failed to lock performer"),
                }
            }
            Action::OutputStream { performer, handle, channel } => {
                match performer.try_lock() {
                    Ok(performer) => {
                        if let Some(channel) = audio.get_mut(*channel) {
                            performer.read(*handle, channel);
                        }
                    }
                    Err(_) => println!("Failed to lock performer"),
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

#[frb(ignore)]
fn generate_node_actions(actions: &mut Vec<Action>, dst_node: &Node, graph: &Graph) {
    // Copy node input data
    for (i, dst_endpoint) in dst_node.get_inputs().iter().enumerate() {
        let mut filled = false;

        // Generate actions for each connected cable
        graph
            .cables
            .iter()
            .filter(| cable | cable.destination.node_id == dst_node.id && cable.destination.pin_index == i as u32)
            .for_each(| cable | {
                let src_node = graph
                    .nodes
                    .iter()
                    .find(| n | n.id == cable.source.node_id)
                    .unwrap();

                let outputs = src_node
                    .get_outputs();

                let src_endpoint = outputs
                    .get(cable.source.pin_index as usize - outputs.len())
                    .unwrap();

                println!(" - Copy {}:{} to {}:{}", src_node.id, cable.source.pin_index as usize - outputs.len(), dst_node.id, i);

                generate_connection_actions(actions, src_node, src_endpoint, dst_node, dst_endpoint);
                filled = true;
            });
        
        // Generate actions to recieve widget updates
        if let EndpointHandle::Widget { handle, queue } = &dst_endpoint.endpoint {
            println!(" - Update widget endpoint {} of node {}", i, dst_node.id);
            filled = true;
            actions.push(
                Action::ReceiveEvents {
                    voices: dst_node.voices.clone(),
                    handle: handle.clone(),
                    queue: queue.clone(),
                }
            );
        }
        
        // Generate actions to fill missing input streams
        if !filled {
            println!(" - Fill input {} of node {}", i, dst_node.id);
            generate_zero_stream_endpoint_action(actions, dst_node, dst_endpoint);
        }
    }

    // Generate actions for each node process
    match dst_node.voices {
        Voices::Mono(ref performer) => {
            println!(" - Process node {}", dst_node.id);
            actions.push(Action::Process(performer.clone()));
        },
        Voices::Poly(ref performers) => {
            for (i, performer) in performers.iter().enumerate() {
                println!(" - Process node {} voice {}", dst_node.id, i);
                actions.push(Action::Process(performer.clone()));
            }
        }
    }

    generate_io_actions(actions, dst_node);
}

#[frb(ignore)]
fn generate_zero_stream_endpoint_action(actions: &mut Vec<Action>, node: &Node, endpoint: &NodeEndpoint) {
    match node.voices {
        Voices::Mono(ref performer) => {
            generate_zero_stream_handle_action(actions, performer, &endpoint.endpoint);
        },
        Voices::Poly(ref performers) => {
            for performer in performers.iter() {
                generate_zero_stream_handle_action(actions, performer, &endpoint.endpoint);
            }
        }
    }
}

#[frb(ignore)]
fn generate_zero_stream_handle_action(actions: &mut Vec<Action>, performer: &Arc<Mutex<Performer>>, handle: &EndpointHandle) {
    match handle {
        EndpointHandle::Input(handle) => {
            if let InputHandle::Stream(handle) = handle {
                match handle {
                    InputStreamHandle::Float32(handle) => {
                        let buffer = vec![0.0; 1024];
                        actions.push(
                            Action::ClearStreamFloat32(
                                ClearStream {
                                    dst_performer: performer.clone(),
                                    dst_handle: handle.clone(),
                                    buffer
                                }
                            )
                        );
                    },
                    InputStreamHandle::Float64(handle) => {
                        let buffer = vec![0.0; 1024];
                        actions.push(
                            Action::ClearStreamFloat64(
                                ClearStream {
                                    dst_performer: performer.clone(),
                                    dst_handle: handle.clone(),
                                    buffer
                                }
                            )
                        );
                    },
                    InputStreamHandle::Int32(handle) => {
                        let buffer = vec![0; 1024];
                        actions.push(
                            Action::ClearStreamInt32(
                                ClearStream {
                                    dst_performer: performer.clone(),
                                    dst_handle: handle.clone(),
                                    buffer
                                }
                            )
                        );
                    },
                    InputStreamHandle::Int64(handle) => {
                        let buffer = vec![0; 1024];
                        actions.push(
                            Action::ClearStreamInt64(
                                ClearStream {
                                    dst_performer: performer.clone(),
                                    dst_handle: handle.clone(),
                                    buffer
                                }
                            )
                        );
                    }
                    InputStreamHandle::Input { endpoint, channel } => ()
                }
            }
        },
        _ => ()
    }
}

#[frb(ignore)]
fn generate_io_actions(actions: &mut Vec<Action>, node: &Node) {
    // Generate actions for each input
    for endpoint in node.get_inputs().iter().chain(node.get_outputs().iter()) {
        match endpoint.endpoint {
            EndpointHandle::Input(handle) => {
                if let InputHandle::Stream(handle) = handle {
                    if let InputStreamHandle::Input { endpoint, channel } = handle {
                        match node.voices {
                            Voices::Mono(ref performer) => {
                                println!(" - Input channel {} to node {}", channel, node.id);
                                actions.push(
                                    Action::InputStream {
                                        performer: performer.clone(),
                                        handle: endpoint,
                                        channel
                                    }
                                );
                            },
                            Voices::Poly(ref performers) => {
                                for performer in performers.iter() {
                                    actions.push(
                                        Action::InputStream {
                                            performer: performer.clone(),
                                            handle: endpoint,
                                            channel
                                        }
                                    );
                                }
                            }
                        }
                    }
                }
            }
            EndpointHandle::Output(handle) => {
                if let OutputHandle::Stream(handle) = handle {
                    if let OutputStreamHandle::Output { endpoint, channel } = handle {
                        match node.voices {
                            Voices::Mono(ref performer) => {
                                println!(" - Output node {} to channel {}", node.id, channel);
                                actions.push(
                                    Action::OutputStream {
                                        performer: performer.clone(),
                                        handle: endpoint,
                                        channel
                                    }
                                );
                            },
                            Voices::Poly(ref performers) => {
                                for performer in performers.iter() {
                                    actions.push(
                                        Action::OutputStream {
                                            performer: performer.clone(),
                                            handle: endpoint,
                                            channel
                                        }
                                    );
                                }
                            }
                        }
                    }
                }
            }
            EndpointHandle::Widget { .. } => ()
        }
    }
}

#[frb(ignore)]
fn generate_connection_actions(
    actions: &mut Vec<Action>,
    src_node: &Node,
    src_endpoint: &NodeEndpoint,
    dst_node: &Node,
    dst_endpoint: &NodeEndpoint) {

    // Generate connection actions
    match &src_node.voices {
        Voices::Mono(ref src_performer) => {
            match &dst_node.voices {
                // Copy mono => mono frames
                Voices::Mono(ref dst_performer) => {
                    generate_copy_action(
                        actions,
                        src_performer.clone(),
                        src_endpoint.endpoint.clone(),
                        dst_performer.clone(),
                        dst_endpoint.endpoint.clone()
                    );
                },
                // Copy mono => poly frames
                Voices::Poly(ref performers) => {
                    // Generate actions for poly voices
                    for dst_performer in performers {
                        generate_copy_action(
                            actions,
                            src_performer.clone(),
                            src_endpoint.endpoint.clone(),
                            dst_performer.clone(),
                            dst_endpoint.endpoint.clone()
                        );
                    }
                }
            }
        },
        Voices::Poly(ref performers) => {
            // Generate actions for poly voices
            todo!()
        }
    }
}

/*#[frb(ignore)]
fn generate_stream_copy_action<T: StreamType>(
    actions: &mut Vec<Action>,
    src_performer: Arc<Mutex<Performer>>,
    src_handle: Endpoint<OutputStream<T>>,
    dst_performer: Arc<Mutex<Performer>>,
    dst_handle: Endpoint<InputStream<T>>) {

    let max_frames: usize = 1024;

    actions.push(
        Action::Copy(
            Box::new(
                CopyStream {
                    src_performer,
                    src_handle,
                    dst_performer,
                    dst_handle,
                    buffer: vec![0.0; max_frames]
                }
            )
        )
    );
}*/

#[frb(ignore)]
fn generate_copy_action(
    actions: &mut Vec<Action>,
    src_performer: Arc<Mutex<Performer>>,
    src_endpoint: EndpointHandle,
    dst_performer: Arc<Mutex<Performer>>,
    dst_endpoint: EndpointHandle) {

    let max_frames: usize = 1024;

    match (src_endpoint, dst_endpoint) {
        (EndpointHandle::Output(src_handle), EndpointHandle::Input(dst_handle)) => {
            match (src_handle, dst_handle) {
                (OutputHandle::Stream(src), InputHandle::Stream(dst)) => {

                    match (src, dst) {
                        (OutputStreamHandle::Float32(src_handle), InputStreamHandle::Float32(dst_handle)) => {
                            let buffer = vec![0.0; max_frames];
                            actions.push(
                                Action::CopyStreamFloat32(
                                    CopyStream {
                                        src_performer,
                                        src_handle,
                                        dst_performer,
                                        dst_handle,
                                        buffer
                                    }
                                )
                            );
                        },
                        (OutputStreamHandle::Float64(src_handle), InputStreamHandle::Float64(dst_handle)) => {
                            let buffer = vec![0.0; max_frames];
                            actions.push(
                                Action::CopyStreamFloat64(
                                    CopyStream {
                                        src_performer,
                                        src_handle,
                                        dst_performer,
                                        dst_handle,
                                        buffer
                                    }
                                )
                            );
                        },
                        (OutputStreamHandle::Int32(src_handle), InputStreamHandle::Int32(dst_handle)) => {
                            let buffer = vec![0; max_frames];
                            actions.push(
                                Action::CopyStreamInt32(
                                    CopyStream {
                                        src_performer,
                                        src_handle,
                                        dst_performer,
                                        dst_handle,
                                        buffer,
                                    }
                                )
                            );

                        },
                        (OutputStreamHandle::Int64(src_handle), InputStreamHandle::Int64(dst_handle)) => {
                            let buffer = vec![0; max_frames];
                            actions.push(
                                Action::CopyStreamInt64(
                                    CopyStream {
                                        src_performer,
                                        src_handle,
                                        dst_performer,
                                        dst_handle,
                                        buffer,
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
                                src_performer,
                                src_handle,
                                dst_performer,
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
                                        src_performer,
                                        src_handle,
                                        dst_performer,
                                        dst_handle,
                                    }
                                )
                            );
                        },
                        (OutputValueHandle::Float64(src_handle), InputValueHandle::Float64(dst_handle)) => {
                            actions.push(
                                Action::CopyValueFloat64(
                                    CopyValue {
                                        src_performer,
                                        src_handle,
                                        dst_performer,
                                        dst_handle,
                                    }
                                )
                            );
                        },
                        (OutputValueHandle::Int32(src_handle), InputValueHandle::Int32(dst_handle)) => {
                            actions.push(
                                Action::CopyValueInt32(
                                    CopyValue {
                                        src_performer,
                                        src_handle,
                                        dst_performer,
                                        dst_handle,
                                    }
                                )
                            );
                        },
                        (OutputValueHandle::Int64(src_handle), InputValueHandle::Int64(dst_handle)) => {
                            actions.push(
                                Action::CopyValueInt64(
                                    CopyValue {
                                        src_performer,
                                        src_handle,
                                        dst_performer,
                                        dst_handle,
                                    }
                                )
                            );
                        },
                        (OutputValueHandle::Bool(src_handle), InputValueHandle::Bool(dst_handle)) => {
                            actions.push(
                                Action::CopyValueBool(
                                    CopyValue {
                                        src_performer,
                                        src_handle,
                                        dst_performer,
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
