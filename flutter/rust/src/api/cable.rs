use cmajor::*;

use flutter_rust_bridge::*;

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
}
