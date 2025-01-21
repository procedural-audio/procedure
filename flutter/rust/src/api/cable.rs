use cmajor::*;

use flutter_rust_bridge::*;

use super::{endpoint::NodeEndpoint, node::Node};

#[derive(Clone)]
#[frb(ignore)]
pub struct Cable {
    pub source: Connection,
    pub destination: Connection,
}

#[derive(Clone)]
#[frb(ignore)]
pub struct Connection {
    pub node: Node,
    pub endpoint: NodeEndpoint,
}
