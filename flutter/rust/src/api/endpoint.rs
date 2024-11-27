use cmajor::{endpoint::{EndpointHandle, EndpointInfo}, value::types::{Primitive, Type}};

use flutter_rust_bridge::*;

#[derive(Copy, Clone)]
pub enum EndpointType {
    Stream = 1,
    Value = 2,
    Event = 3
}

#[derive(Clone)]
#[frb(opaque)]
pub struct Endpoint {
    // handle: EndpointHandle,
    info: EndpointInfo
}

impl Endpoint {
    #[frb(ignore)]
    pub fn from(info: EndpointInfo) -> Self {
        match info {
            EndpointInfo::Stream(endpoint) => {
                match endpoint.ty() {
                    Type::Primitive(primitive) => match primitive {
                        Primitive::Float32 => (),
                        Primitive::Void => todo!(),
                        Primitive::Bool => todo!(),
                        Primitive::Int32 => todo!(),
                        Primitive::Int64 => todo!(),
                        Primitive::Float64 => todo!(),
                    },
                    Type::String => todo!(),
                    Type::Array(array) => todo!(),
                    Type::Object(object) => todo!(),
                }
            },
            EndpointInfo::Event(event_endpoint) => {
            },
            EndpointInfo::Value(value_endpoint) => {
            },
        }

        Self { info }
    }

    #[frb(sync, getter)]
    pub fn get_type(&self) -> EndpointType {
        EndpointType::Stream
    }
}

/*#[frb]
#[derive(Clone)]
pub struct EndpointInfo {
    pub kind: EndpointKind,
    pub top: Option<u32>,
}*/
