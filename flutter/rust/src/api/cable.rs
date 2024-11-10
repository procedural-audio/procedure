use cmajor_rs::*;

use flutter_rust_bridge::*;

#[derive(Copy, Clone)]
#[frb(opaque)]
pub struct Cable {
    pub source: Connection,
    pub destination: Connection,
    endpoint_type: EndpointType,
}

#[derive(Copy, Clone)]
#[frb(opaque)]
pub struct Connection {
    pub node_id: u32,
    pub endpoint_handle: u32,
}
