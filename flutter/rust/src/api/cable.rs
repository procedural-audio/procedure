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
