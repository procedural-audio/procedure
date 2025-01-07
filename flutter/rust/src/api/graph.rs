use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;
use std::sync::mpsc::*;
use std::sync::RwLock;

use crate::api::cable::*;
use crate::api::endpoint::*;
use crate::api::node::*;

use cmajor::*;

use flutter_rust_bridge::*;

use super::node;

lazy_static::lazy_static! {
    static ref GRAPH: RwLock<Option<Graph>> = RwLock::new(None);
}

#[frb(sync)]
pub fn set_patch(graph: Graph) {
    println!("Updated patch ({} nodes, {} cables)", graph.nodes.len(), graph.cables.len());

    *GRAPH.write().unwrap() = Some(graph.clone());
}

#[frb(sync)]
pub fn clear_patch() {
    println!("Cleared patch");
    *GRAPH.write().unwrap() = None;
}

#[frb(ignore)]
#[no_mangle]
pub unsafe extern "C" fn prepare_patch(sample_rate: f64, block_size: u32) {
    if let Ok(mut graph) = GRAPH.write() {
        if let Some(graph) = &mut *graph {
            graph.prepare(sample_rate, block_size);
        }
    }
}

#[frb(ignore)]
#[no_mangle]
pub unsafe extern "C" fn process_patch(audio: *const *mut f32, channels: u32, frames: u32, midi: *mut u8, size: u32) {
    // TODO: Update patch from pending patch if it exists

    if let Ok(graph) = GRAPH.read() {
        if let Some(graph) = &*graph {
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
            graph.process(buffer.as_mut_slice(), midi);
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

    /*#[frb(sync)]
    pub fn from(nodes: &Vec<Node>, cables: &Vec<Cable>) -> Self {
        Self {
            nodes: nodes.clone(),
            cables: cables.clone(),
        }
    }*/

    #[frb(ignore)]
    pub fn prepare(&mut self, sample_rate: f64, block_size: u32) {
        // Sort the nodes topologically
        self.sort_nodes_topologically().unwrap();

        // Prepare each node
        for node in &self.nodes {
            node.prepare(sample_rate, block_size);
        }
    }

    #[frb(ignore)]
    pub fn process(&self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        // This method isn't mutable since it works through mutexes

        // Copy audio to input nodes
        // Copy midi to input nodes

        // Process each node
        for node in &self.nodes {
            node.process();
        }

        // Clear the midi output
        midi.fill(0);

        // Clear the audio output
        for channel in audio.iter_mut() {
            channel.fill(0.0);
        }

        // Copy midi from output nodes
        // Copy audio from output nodes
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
