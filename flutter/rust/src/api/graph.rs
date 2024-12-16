use std::collections::HashMap;

use crate::api::cable::*;
use crate::api::endpoint::*;
use crate::api::node::*;

use cmajor::*;

use flutter_rust_bridge::*;

#[no_mangle]
pub extern "C" fn patch_render_callback(audio: *const *mut f32, channels: u32, frames: u32, midi: *const u8, size: u32) {
    println!("Processing midi an the graph");
}

#[frb(opaque)]
pub struct Graph {
    nodes: Vec<Node>,
    cables: Vec<Cable>,
}

impl Graph {
    pub fn from(nodes: &Vec<Node>, cables: &Vec<Cable>) -> Self {
        Self {
            nodes: nodes.clone(),
            cables: cables.clone(),
        }
    }

    /*
    pub fn prepare(&mut self, block_size: u32) {
        for node in &mut self.nodes {
            node.prepare(block_size);
        }
    }

    pub fn process(&mut self) {
        for node in &self.nodes {
            // Todo: Process the node
        }
    }*/

    /*pub fn process_node(&self, node: &mut Node) {
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

                match cable.endpoint_type {
                    EndpointType::Value => {
                        // self.performer.set_input_value(destination.handle, source.value, 0);
                        println!("Setting value from source to destination");
                    },
                    EndpointType::Stream => {
                        // self.performer.set_input_frames(destination.handle, source.value, self.block_size);
                        println!("Setting stream from source to destination");
                    },
                    EndpointType::Event => {
                        // self.performer.add_input_event(destination.handle, 0, source.value);
                        println!("Setting event from source to destination");
                    },
                    EndpointType::Unknown => {
                        panic!("Unknown endpoint type");
                    }
                }

                // node.performer.copy_output_frames(handle, dest, size)
                // self.performer.set_input_frames(handle, frames, size);
            });
    }

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
    }*/
}