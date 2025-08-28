use cmajor::*;

use flutter_rust_bridge::*;
use serde::{Deserialize, Serialize};

use super::{endpoint::NodeEndpoint, node::Node};

#[derive(Clone)]
pub struct Cable {
    pub source: Connection,
    pub destination: Connection,
}

#[derive(Clone)]
pub struct Connection {
    pub node: Node,
    pub endpoint: NodeEndpoint,
}

impl Cable {
    #[frb(sync)]
    pub fn new(src_node: Node, src_endpoint: NodeEndpoint, dst_node: Node, dst_endpoint: NodeEndpoint) -> Self {
        Self {
            source: Connection {
                node: src_node,
                endpoint: src_endpoint,
            },
            destination: Connection {
                node: dst_node,
                endpoint: dst_endpoint,
            },
        }
    }

    // Check if this cable connects to a specific node and endpoint (by annotation)
    #[frb(sync)]
    pub fn connects_to(&self, node: &Node, endpoint: &NodeEndpoint) -> bool {
        (self.source.node.module.title == node.module.title && 
         self.source.endpoint.annotation == endpoint.annotation) ||
        (self.destination.node.module.title == node.module.title && 
         self.destination.endpoint.annotation == endpoint.annotation)
    }

    // Check if this cable has the same source and destination as another cable
    #[frb(sync)]
    pub fn matches(&self, other: &Cable) -> bool {
        (self.source.node.module.title == other.source.node.module.title &&
         self.source.endpoint.annotation == other.source.endpoint.annotation &&
         self.destination.node.module.title == other.destination.node.module.title &&
         self.destination.endpoint.annotation == other.destination.endpoint.annotation)
    }
}
