use std::collections::HashMap;
use std::process::Output;
use std::sync::Arc;
use std::sync::Mutex;
use std::sync::mpsc::*;
use std::sync::RwLock;

use crate::api::cable::*;
use crate::api::endpoint::*;
use crate::api::node::*;

use cmajor::*;

use flutter_rust_bridge::*;
use performer::Endpoint;
use performer::InputStream;
use performer::InputValue;
use performer::OutputStream;
use performer::OutputValue;
use performer::Performer;

use super::cable;
use super::node;

lazy_static::lazy_static! {
    static ref ACTIONS: RwLock<Option<Vec<Action>>> = RwLock::new(None);
    // static ref GRAPH_PLAYING: RwLock<Option<Graph>> = RwLock::new(None);
    // static ref GRAPH_PENDING: RwLock<Option<Graph>> = RwLock::new(None);
}

#[frb(sync)]
pub fn set_patch(mut graph: Graph) {
    println!("Updated patch ({} nodes, {} cables)", graph.nodes.len(), graph.cables.len());
    
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
    if let Ok(mut actions) = ACTIONS.try_write() {
        /*if let Some(graph) = &mut *graph {
            graph.prepare(sample_rate, block_size);
        }*/
    }
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
    pub fn prepare(&mut self, sample_rate: f64, block_size: u32) {
        // Prepare each node
        for node in &self.nodes {
            node.prepare(sample_rate, block_size);
        }
    }

    #[frb(ignore)]
    pub fn process(&self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        // This method isn't mutable since it works through mutexes

        // TODO: Copy audio to input nodes
        // TODO: Copy midi to input nodes

        // Process each node
        for node in &self.nodes {
            // TODO: Copy input data to this node

            // Process the node
            node.process();
        }

        // Clear the midi output
        midi.fill(0);

        // Clear the audio output
        for channel in audio.iter_mut() {
            channel.fill(0.0);
        }

        // TODO: Copy midi from output nodes
        // TODO: Copy audio from output nodes
    }

    #[frb(ignore)]
    fn process_node(&self, node: &mut Node) {
       self 
            .cables
            // All the cables
            .iter()
            // Cables that input to this node
            .filter(| cable | cable.destination.node_id == node.id)
            // Iterate over each input cable to this node
            .for_each(| cable | {
                // Get the source node for this cable
                let source_node = self
                    .nodes
                    .iter()
                    .find(| n | n.id == cable.source.node_id)
                    .unwrap();

                // Get the source endpoint for this cable

                // node.performer.copy_output_frames(handle, dest, size)
                // self.performer.set_input_frames(handle, frames, size);
            });
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
pub enum Action {
    Process(Arc<Mutex<Performer>>),
    
    // Copy streams
    CopyStreamFloat32 {
        src_performer: Arc<Mutex<Performer>>,
        src_handle: Endpoint<OutputStream<f32>>,
        dst_performer: Arc<Mutex<Performer>>,
        dst_handle: Endpoint<InputStream<f32>>,
        buffer: Vec<f32>,
    },
    CopyStreamFloat64 {
        src_performer: Arc<Mutex<Performer>>,
        src_handle: Endpoint<OutputStream<f64>>,
        dst_performer: Arc<Mutex<Performer>>,
        dst_handle: Endpoint<InputStream<f64>>,
        buffer: Vec<f64>,
    },
    CopyStreamInt32 {
        src_performer: Arc<Mutex<Performer>>,
        src_handle: Endpoint<OutputStream<i32>>,
        dst_performer: Arc<Mutex<Performer>>,
        dst_handle: Endpoint<InputStream<i32>>,
        buffer: Vec<i32>,
    },
    CopyStreamInt64 {
        src_performer: Arc<Mutex<Performer>>,
        src_handle: Endpoint<OutputStream<i64>>,
        dst_performer: Arc<Mutex<Performer>>,
        dst_handle: Endpoint<InputStream<i64>>,
        buffer: Vec<i64>,
    },

    // Copy values
    CopyValueFloat32 {
        src_performer: Arc<Mutex<Performer>>,
        src_handle: Endpoint<OutputValue<f32>>,
        dst_performer: Arc<Mutex<Performer>>,
        dst_handle: Endpoint<InputValue<f32>>,
    },
    CopyValueFloat64 {
        src_performer: Arc<Mutex<Performer>>,
        src_handle: Endpoint<OutputValue<f64>>,
        dst_performer: Arc<Mutex<Performer>>,
        dst_handle: Endpoint<InputValue<f64>>,
    },
    CopyValueInt32 {
        src_performer: Arc<Mutex<Performer>>,
        src_handle: Endpoint<OutputValue<i32>>,
        dst_performer: Arc<Mutex<Performer>>,
        dst_handle: Endpoint<InputValue<i32>>,
    },
    CopyValueInt64 {
        src_performer: Arc<Mutex<Performer>>,
        src_handle: Endpoint<OutputValue<i64>>,
        dst_performer: Arc<Mutex<Performer>>,
        dst_handle: Endpoint<InputValue<i64>>,
    },
    CopyValueBool {
        src_performer: Arc<Mutex<Performer>>,
        src_handle: Endpoint<OutputValue<bool>>,
        dst_performer: Arc<Mutex<Performer>>,
        dst_handle: Endpoint<InputValue<bool>>,
    },

    // Output {}
    // Input {}
    // Clear {}
}

impl Action {
    #[frb(ignore)]
    pub fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let num_frames = audio.get(0).unwrap().len() as u32;

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
            Action::CopyStreamFloat32 { src_performer, src_handle, dst_performer, dst_handle, buffer } => {
                src_performer
                    .try_lock()
                    .unwrap()
                    .read(*src_handle, buffer);

                dst_performer
                    .try_lock()
                    .unwrap()
                    .write(*dst_handle, buffer);
            }
            Action::CopyStreamFloat64 { src_performer, src_handle, dst_performer, dst_handle, buffer } => {
                src_performer
                    .try_lock()
                    .unwrap()
                    .read(*src_handle, buffer);

                dst_performer
                    .try_lock()
                    .unwrap()
                    .write(*dst_handle, buffer);
            }
            Action::CopyStreamInt32 { src_performer, src_handle, dst_performer, dst_handle, buffer } => {
                src_performer
                    .try_lock()
                    .unwrap()
                    .read(*src_handle, buffer);

                dst_performer
                    .try_lock()
                    .unwrap()
                    .write(*dst_handle, buffer);
            }
            Action::CopyStreamInt64 { src_performer, src_handle, dst_performer, dst_handle, buffer } => {
                src_performer
                    .try_lock()
                    .unwrap()
                    .read(*src_handle, buffer);

                dst_performer
                    .try_lock()
                    .unwrap()
                    .write(*dst_handle, buffer);
            }
            Action::CopyValueFloat32 { src_performer, src_handle, dst_performer, dst_handle } => {
                let value = src_performer
                    .try_lock()
                    .unwrap()
                    .get(*src_handle);

                dst_performer
                    .try_lock()
                    .unwrap()
                    .set(*dst_handle, value);
            }
            Action::CopyValueFloat64 { src_performer, src_handle, dst_performer, dst_handle } => {
                let value = src_performer
                    .try_lock()
                    .unwrap()
                    .get(*src_handle);

                dst_performer
                    .try_lock()
                    .unwrap()
                    .set(*dst_handle, value);
            }
            Action::CopyValueInt32 { src_performer, src_handle, dst_performer, dst_handle } => {
                let value = src_performer
                    .try_lock()
                    .unwrap()
                    .get(*src_handle);

                dst_performer
                    .try_lock()
                    .unwrap()
                    .set(*dst_handle, value);
            }
            Action::CopyValueInt64 { src_performer, src_handle, dst_performer, dst_handle } => {
                let value = src_performer
                    .try_lock()
                    .unwrap()
                    .get(*src_handle);

                dst_performer
                    .try_lock()
                    .unwrap()
                    .set(*dst_handle, value);
            }
            Action::CopyValueBool { src_performer, src_handle, dst_performer, dst_handle } => {
                let value = src_performer
                    .try_lock()
                    .unwrap()
                    .get(*src_handle);

                dst_performer
                    .try_lock()
                    .unwrap()
                    .set(*dst_handle, value);
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
    for cable in &graph.cables {
        if cable.destination.node_id == dst_node.id {
            let src_node = graph
                .nodes
                .iter()
                .find(| n | n.id == cable.source.node_id)
                .unwrap();

            let src_idx = cable.source.pin_index as usize;
            let dst_idx = cable.destination.pin_index as usize;

            generate_connection_actions(actions, src_node, src_idx, dst_node, dst_idx);
        }
    }

    // Process each voice
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
}

#[frb(ignore)]
fn generate_connection_actions(
    actions: &mut Vec<Action>,
    src_node: &Node,
    src_idx: usize,
    dst_node: &Node,
    dst_idx: usize) {

    // Generate connection actions
    match &src_node.voices {
        Voices::Mono(ref src_performer) => {
            let src_input_count = src_node
                .get_inputs()
                .len();

            println!(" - Copy from {}:{} to {}:{}", src_node.id, src_idx - src_input_count, dst_node.id, dst_idx);

            let src_handle = src_node
                .get_outputs()
                .get(src_idx - src_input_count)
                .unwrap()
                .endpoint;

            match &dst_node.voices {
                // Copy mono => mono frames
                Voices::Mono(ref dst_performer) => {
                    let dst_handle = dst_node
                        .get_inputs()
                        .get(dst_idx)
                        .unwrap()
                        .endpoint;

                    generate_copy_action(actions, src_performer.clone(), src_handle, dst_performer.clone(), dst_handle);
                },
                // Copy mono => poly frames
                Voices::Poly(ref performers) => {
                    // Generate actions for poly voices
                    todo!()
                }
            }
        },
        Voices::Poly(ref performers) => {
            // Generate actions for poly voices
            todo!()
        }
    }
}

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
                            actions.push(Action::CopyStreamFloat32 {
                                src_performer,
                                src_handle,
                                dst_performer,
                                dst_handle,
                                buffer,
                            });
                        },
                        (OutputStreamHandle::Float64(src_handle), InputStreamHandle::Float64(dst_handle)) => {
                            let buffer = vec![0.0; max_frames];
                            actions.push(Action::CopyStreamFloat64 {
                                src_performer,
                                src_handle,
                                dst_performer,
                                dst_handle,
                                buffer,
                            });
                        },
                        (OutputStreamHandle::Int32(src_handle), InputStreamHandle::Int32(dst_handle)) => {
                            let buffer = vec![0; max_frames];
                            actions.push(Action::CopyStreamInt32 {
                                src_performer,
                                src_handle,
                                dst_performer,
                                dst_handle,
                                buffer,
                            });
                        },
                        (OutputStreamHandle::Int64(src_handle), InputStreamHandle::Int64(dst_handle)) => {
                            let buffer = vec![0; max_frames];
                            actions.push(Action::CopyStreamInt64 {
                                src_performer,
                                src_handle,
                                dst_performer,
                                dst_handle,
                                buffer,
                            });
                        },
                        _ => println!("Connection not between streams of the same type")
                    }
                },
                (OutputHandle::Value(src_handle), InputHandle::Value(dst_handle)) => {
                    match (src_handle, dst_handle) {
                        (OutputValueHandle::Float32(src_handle), InputValueHandle::Float32(dst_handle)) => {
                            actions.push(Action::CopyValueFloat32 {
                                src_performer,
                                src_handle,
                                dst_performer,
                                dst_handle,
                            });
                        },
                        (OutputValueHandle::Float64(src_handle), InputValueHandle::Float64(dst_handle)) => {
                            actions.push(Action::CopyValueFloat64 {
                                src_performer,
                                src_handle,
                                dst_performer,
                                dst_handle,
                            });
                        },
                        (OutputValueHandle::Int32(src_handle), InputValueHandle::Int32(dst_handle)) => {
                            actions.push(Action::CopyValueInt32 {
                                src_performer,
                                src_handle,
                                dst_performer,
                                dst_handle,
                            });
                        },
                        (OutputValueHandle::Int64(src_handle), InputValueHandle::Int64(dst_handle)) => {
                            actions.push(Action::CopyValueInt64 {
                                src_performer,
                                src_handle,
                                dst_performer,
                                dst_handle,
                            });
                        },
                        (OutputValueHandle::Bool(src_handle), InputValueHandle::Bool(dst_handle)) => {
                            actions.push(Action::CopyValueBool {
                                src_performer,
                                src_handle,
                                dst_performer,
                                dst_handle,
                            });
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