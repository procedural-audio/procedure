use cmajor_rs::*;

use flutter_rust_bridge::*;

#[derive(Copy, Clone)]
#[frb(non_opaque)]
pub struct Cable {
    pub source: Connection,
    pub destination: Connection,
    pub endpoint_type: u32,
}

#[derive(Copy, Clone)]
#[frb(non_opaque)]
pub struct Connection {
    pub node_id: u32,
    pub endpoint_handle: u32,
}
