use flutter_rust_bridge::*;
use crate::api::cable::Cable;
use crate::api::node::Node;
use serde::{Serialize, Deserialize};
use serde_json;
use std::path::Path;
use tokio::fs;

use super::module::Module;

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

// Simplified patch API with just three functions

/// Load a patch from JSON string and return nodes and cables
#[frb]
pub async fn load_patch(json_str: &str) -> Result<(Vec<Node>, Vec<Cable>), String> {
    let serializable: SerializablePatch = serde_json::from_str(json_str)
        .map_err(|e| format!("Failed to parse JSON: {}", e))?;
    
    let mut nodes = Vec::new();
    let mut next_node_id = 1u32;
    
    // Find the maximum node ID to set next_node_id correctly
    let max_id = serializable.nodes.iter().map(|n| n.id).max().unwrap_or(0);
    next_node_id = max_id + 1;
    
    // Recreate nodes
    for s_node in serializable.nodes {
        if let Some(mut node) = Node::from_module(s_node.module, s_node.position) {
            node.id = s_node.id;
            nodes.push(node);
        } else {
            return Err(format!("Failed to recreate node with id {}", s_node.id));
        }
    }
    
    let mut cables = Vec::new();
    
    // Recreate cables
    for s_cable in serializable.cables {
        // Find source node and endpoint
        let source_node = nodes.iter()
            .find(|n| n.id == s_cable.source.node_id)
            .ok_or_else(|| format!("Source node {} not found", s_cable.source.node_id))?;
        
        let source_endpoint = source_node.get_outputs().into_iter()
            .chain(source_node.get_inputs().into_iter())
            .find(|e| e.get_type() == s_cable.source.endpoint_type && 
                     e.annotation == s_cable.source.endpoint_annotation)
            .ok_or_else(|| format!("Source endpoint not found"))?;
        
        // Find destination node and endpoint  
        let dest_node = nodes.iter()
            .find(|n| n.id == s_cable.destination.node_id)
            .ok_or_else(|| format!("Destination node {} not found", s_cable.destination.node_id))?;
        
        let dest_endpoint = dest_node.get_inputs().into_iter()
            .chain(dest_node.get_outputs().into_iter())
            .find(|e| e.get_type() == s_cable.destination.endpoint_type && 
                     e.annotation == s_cable.destination.endpoint_annotation)
            .ok_or_else(|| format!("Destination endpoint not found"))?;
        
        // Create cable using the factory constructor
        let cable = Cable::new(
            source_node.clone(),
            source_endpoint,
            dest_node.clone(),
            dest_endpoint,
        );
        
        cables.push(cable);
    }
    
    Ok((nodes, cables))
}

/// Save nodes and cables to JSON string
#[frb]
pub async fn save_patch(nodes: Vec<Node>, cables: Vec<Cable>) -> Result<String, String> {
    // Convert nodes to serializable format
    let s_nodes: Vec<SerializableNode> = nodes.iter()
        .map(|node| SerializableNode {
            id: node.id,
            module: node.module.clone(),
            position: node.position,
        })
        .collect();
    
    // Convert cables to serializable format
    let s_cables: Vec<SerializableCable> = cables.iter()
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

pub struct Patch {
    pub nodes: Vec<Node>,
    pub cables: Vec<Cable>,
}

impl Patch {
    #[frb(sync)]
    pub fn from(nodes: Vec<Node>, cables: Vec<Cable>) -> Self {
        Self { nodes, cables }
    }

    pub async fn save(&self, path: String) -> Result<String, String> {
        todo!()
    }

    pub async fn load(path: String) -> Result<(), String> {
        todo!()
    }
}

/// Update the playing patch using the audio manager
/// Note: This function requires an AudioManager instance to be passed to it
/// The actual integration will be handled at the Flutter level
#[frb]
pub async fn play_patch(nodes: Vec<Node>, cables: Vec<Cable>) -> Result<(), String> {
    use crate::other::action::Actions;
    
    println!("Playing patch with {} nodes and {} cables", nodes.len(), cables.len());
    
    // Create actions from nodes and cables
    let _actions = Actions::from_nodes_and_cables(nodes.to_vec(), cables.to_vec());
    
    // The actual audio manager integration will be done from Flutter
    // by calling AudioManager.set_patch_data(nodes, cables)
    println!("Patch actions created successfully");
    
    Ok(())
}