use cmajor::*;

use flutter_rust_bridge::*;

#[derive(Copy, Clone)]
#[frb(non_opaque)]
pub struct Cable {
    pub source: Connection,
    pub destination: Connection,
}

#[derive(Copy, Clone)]
#[frb(non_opaque)]
pub struct Connection {
    pub node_id: u32,
    pub pin_index: u32
}
