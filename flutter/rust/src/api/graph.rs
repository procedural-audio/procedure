use std::collections::HashMap;
use std::sync::RwLock;

use crate::api::cable::*;
use crate::api::endpoint::*;
use crate::api::node::*;

use flutter_rust_bridge::*;
use crate::other::action::*;

lazy_static::lazy_static! {
    static ref ACTIONS: RwLock<Option<Vec<Action>>> = RwLock::new(None);
    // static ref GRAPH_PLAYING: RwLock<Option<Graph>> = RwLock::new(None);
    // static ref GRAPH_PENDING: RwLock<Option<Graph>> = RwLock::new(None);
}

#[frb(sync)]
pub fn set_patch(graph: Graph) {
    println!("Updating patch ({} nodes, {} cables)", graph.nodes.len(), graph.cables.len());

    let actions = generate_graph_actions(graph);

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

#[frb(sync)]
pub fn is_connection_supported(src_node: &Node, src_endpoint: &NodeEndpoint, dst_node: &Node, dst_endpoint: &NodeEndpoint) -> bool {
    match crate::other::action::is_connection_supported(src_node, src_endpoint, dst_node, dst_endpoint) {
        Ok(_) => true,
        Err(e) => {
            println!("Error: {}", e);
            false
        },
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
    pub nodes: Vec<Node>,
    pub cables: Vec<Cable>,
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
}
