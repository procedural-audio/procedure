use cmajor::endpoint::{EndpointHandle, EndpointInfo};

use flutter_rust_bridge::*;

#[derive(Clone)]
#[frb(opaque)]
pub struct Endpoint {
    handle: EndpointHandle,
    kind: EndpointType
    // details: EndpointDetails,
}

impl Endpoint {
    /*pub fn new(handle: EndpointHandle, details: &EndpointDetails) -> Self {
        Self {
            handle,
            details: details.clone(),
        }
    }*/

    #[frb(sync, getter)]
    pub fn get_type(&self) -> EndpointType {
        self.kind
    }
}

/*#[frb]
#[derive(Clone)]
pub struct EndpointInfo {
    pub kind: EndpointKind,
    pub top: Option<u32>,
}*/

impl Endpoint {
}

#[derive(Copy, Clone)]
pub enum EndpointType {
    Stream = 1,
    Value = 2,
    Event = 3
}