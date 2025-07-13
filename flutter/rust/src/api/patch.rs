use flutter_rust_bridge::*;
use crate::api::cable::Cable;
use serde::{Serialize, Deserialize};
use serde_json;

use super::node::Node;
use super::module::Module;

pub type NodeId = u32;
pub type WidgetId = u32;

// Serializable representations
#[derive(Serialize, Deserialize)]
struct SerializableNode {
    id: u32,
    module: Module,
    position: (f64, f64),
}

#[derive(Serialize, Deserialize)]
struct SerializableConnection {
    node_id: u32,
    endpoint_type: String,
    endpoint_annotation: String,
}

#[derive(Serialize, Deserialize)]
struct SerializableCable {
    source: SerializableConnection,
    destination: SerializableConnection,
}

#[derive(Serialize, Deserialize)]
struct SerializablePatch {
    nodes: Vec<SerializableNode>,
    cables: Vec<SerializableCable>,
}

#[frb(opaque)]
pub struct Patch {
    pub nodes: Vec<Node>,
    pub cables: Vec<Cable>
}

impl Patch {
    #[frb(sync)]
    pub fn new() -> Self {
        Self {
            nodes: Vec::new(),
            cables: Vec::new(),
        }
    }

    #[frb(sync)]
    pub fn add_node(&mut self, node: Node) {
        self.nodes.push(node);
    }

    #[frb(sync)]
    pub fn remove_node(&mut self, node: Node) {
        self.nodes.retain(|n| n.id != node.id);

        // Also remove any connectors connected to this node
        self.cables.retain(|c| c.source.node.id != node.id && c.destination.node.id != node.id);
    }

    #[frb(sync)]
    pub fn add_cable(&mut self, cable: Cable) {
        self.cables.push(cable);
    }

    #[frb(sync)]
    pub fn remove_cable(&mut self, cable: Cable) {
        self.cables.retain(|c| !(
            c.source.node.id == cable.source.node.id && 
            c.destination.node.id == cable.destination.node.id
        ));
    }

    #[frb(sync)]
    pub fn get_nodes(&self) -> Vec<Node> {
        self.nodes.clone()
    }

    #[frb(sync)]
    pub fn get_cables(&self) -> Vec<Cable> {
        self.cables.clone()
    }

    #[frb(sync)]
    pub fn update_node_position(&mut self, node_id: u32, position: (f64, f64)) {
        if let Some(node) = self.nodes.iter_mut().find(|n| n.id == node_id) {
            node.position = position;
        }
    }

    pub async fn load(&mut self, json_str: &str) -> Result<(), String> {
        let serializable: SerializablePatch = serde_json::from_str(json_str)
            .map_err(|e| format!("Failed to parse JSON: {}", e))?;
        
        // Clear existing data
        self.nodes.clear();
        self.cables.clear();
        
        // Recreate nodes
        for s_node in serializable.nodes {
            if let Some(node) = Node::from(s_node.id, s_node.module, s_node.position) {
                self.nodes.push(node);
            } else {
                return Err(format!("Failed to recreate node with id {}", s_node.id));
            }
        }
        
        // Recreate cables
        for s_cable in serializable.cables {
            // Find source node and endpoint
            let source_node = self.nodes.iter()
                .find(|n| n.id == s_cable.source.node_id)
                .ok_or_else(|| format!("Source node {} not found", s_cable.source.node_id))?;
            
            let source_endpoint = source_node.get_outputs().into_iter()
                .chain(source_node.get_inputs().into_iter())
                .find(|e| e.get_type() == s_cable.source.endpoint_type && 
                         e.annotation == s_cable.source.endpoint_annotation)
                .ok_or_else(|| format!("Source endpoint not found"))?;
            
            // Find destination node and endpoint  
            let dest_node = self.nodes.iter()
                .find(|n| n.id == s_cable.destination.node_id)
                .ok_or_else(|| format!("Destination node {} not found", s_cable.destination.node_id))?;
            
            let dest_endpoint = dest_node.get_inputs().into_iter()
                .chain(dest_node.get_outputs().into_iter())
                .find(|e| e.get_type() == s_cable.destination.endpoint_type && 
                         e.annotation == s_cable.destination.endpoint_annotation)
                .ok_or_else(|| format!("Destination endpoint not found"))?;
            
            // Create cable
            let cable = Cable {
                source: super::cable::Connection {
                    node: source_node.clone(),
                    endpoint: source_endpoint,
                },
                destination: super::cable::Connection {
                    node: dest_node.clone(),
                    endpoint: dest_endpoint,
                },
            };
            
            self.cables.push(cable);
        }
        
        Ok(())
    }

    pub async fn save(&self) -> Result<String, String> {
        // Convert nodes to serializable format
        let s_nodes: Vec<SerializableNode> = self.nodes.iter()
            .map(|node| SerializableNode {
                id: node.id,
                module: node.module.clone(),
                position: node.position,
            })
            .collect();
        
        // Convert cables to serializable format
        let s_cables: Vec<SerializableCable> = self.cables.iter()
            .map(|cable| SerializableCable {
                source: SerializableConnection {
                    node_id: cable.source.node.id,
                    endpoint_type: cable.source.endpoint.get_type(),
                    endpoint_annotation: cable.source.endpoint.annotation.clone(),
                },
                destination: SerializableConnection {
                    node_id: cable.destination.node.id,
                    endpoint_type: cable.destination.endpoint.get_type(),
                    endpoint_annotation: cable.destination.endpoint.annotation.clone(),
                },
            })
            .collect();
        
        let serializable = SerializablePatch {
            nodes: s_nodes,
            cables: s_cables,
        };
        
        serde_json::to_string_pretty(&serializable)
            .map_err(|e| format!("Failed to serialize patch: {}", e))
    }
}
