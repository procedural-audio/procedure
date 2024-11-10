use cmajor_rs::*;

use flutter_rust_bridge::*;

#[derive(Clone)]
#[frb(opaque)]
pub struct Endpoint {
    handle: EndpointHandle,
    details: EndpointDetails,
}

impl Endpoint {
    /*pub fn new(handle: EndpointHandle, details: &EndpointDetails) -> Self {
        Self {
            handle,
            details: details.clone(),
        }
    }*/
}
