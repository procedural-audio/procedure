use flutter_rust_bridge::*;
use crate::api::cable::Cable;

use super::node::Node;

pub type NodeId = u32;
pub type WidgetId = u32;

#[frb(opaque)]
pub struct Patch {
    nodes: Vec<Node>,
    cables: Vec<Cable>
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

    pub fn load_from_json(&self, _json_str: &str) -> Result<(), String> {
        // todo: serialize with serde
        todo!()
    }

    pub fn save_to_json(&self) -> Result<String, String> {
        // todo: serialize with serde
        todo!()
    }
}
