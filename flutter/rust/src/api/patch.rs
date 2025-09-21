use flutter_rust_bridge::*;
use crate::api::cable::Cable;
use crate::api::node::Node;
use serde::{Serialize, Deserialize};
use serde_json;
use std::path::Path;
use tokio::fs;

use super::module::Module;

#[frb(opaque)]
pub struct Patch {
    pub nodes: Vec<Node>,
    pub cables: Vec<Cable>,
}

impl Patch {
    #[frb(sync)]
    pub fn new() -> Self {
        Self { nodes: Vec::new(), cables: Vec::new() }
    }

    // Build patch incrementally by borrowing existing Node/Cable handles from Dart
    // This avoids consuming Dart-side RustOpaque handles (prevents DroppableDisposedException)
    #[frb(sync)]
    pub fn clear(&mut self) {
        self.nodes.clear();
        self.cables.clear();
    }

    #[frb(sync)]
    pub fn add_node(&mut self, node: &Node) {
        self.nodes.push(node.clone());
    }

    #[frb(sync)]
    pub fn add_cable(&mut self, cable: &Cable) {
        self.cables.push(cable.clone());
    }
}