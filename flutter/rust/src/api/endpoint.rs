use cmajor::{endpoint::{EndpointHandle, EndpointInfo}, value::types::{Primitive, Type}};

use flutter_rust_bridge::*;

#[derive(Copy, Clone)]
pub enum EndpointType {
    Stream(StreamType),
    Value(ValueType),
    Event(EventType),
}

#[derive(Copy, Clone)]
pub enum StreamType {
    Float32,
    Float64,
}

#[derive(Copy, Clone)]
pub enum ValueType {
    Float64,
    Int64,
    Bool,
}

#[derive(Copy, Clone)]
pub enum EventType {
    Midi,
    Bool,
    Int64,
}

#[derive(Copy, Clone)]
pub enum EndpointDirection {
    Input,
    Output,
}

#[derive(Clone)]
#[frb(non_opaque)]
pub struct Endpoint {
    // handle: EndpointHandle,
    // info: EndpointInfo,
    pub kind: EndpointType,
    pub direction: EndpointDirection,
    pub annotation: String,
}

impl Endpoint {
    #[frb(ignore)]
    pub fn from(info: EndpointInfo) -> Self {
        let kind = match &info {
            EndpointInfo::Stream(endpoint) => {
                EndpointType::Stream(
                    match endpoint.ty() {
                        Type::Primitive(primitive) => match primitive {
                            Primitive::Float32 => StreamType::Float32,
                            Primitive::Float64 => StreamType::Float64,
                            Primitive::Void => todo!(),
                            Primitive::Bool => todo!(),
                            Primitive::Int32 => todo!(),
                            Primitive::Int64 => todo!(),
                        },
                        Type::String => todo!(),
                        Type::Array(array) => todo!(),
                        Type::Object(object) => todo!(),
                    }
                )
            },
            EndpointInfo::Event(event_endpoint) => {
                /*EndpointType::Event(
                    match event_endpoint.get_type().unwrap() {
                        Type::Primitive(primitive) => match primitive {
                            Primitive::Float32 => EventType::Midi,
                            Primitive::Float64 => EventType::Bool,
                            Primitive::Void => todo!(),
                            Primitive::Bool => EventType::Bool,
                            Primitive::Int32 => EventType::Int64,
                            Primitive::Int64 => todo!(),
                        },
                        Type::String => todo!(),
                        Type::Array(array) => todo!(),
                        Type::Object(object) => todo!(),
                    }
                )*/

                EndpointType::Event(EventType::Midi)
            },
            EndpointInfo::Value(value_endpoint) => {
                EndpointType::Value(
                    match value_endpoint.ty() {
                        Type::Primitive(primitive) => match primitive {
                            Primitive::Float32 => ValueType::Float64,
                            Primitive::Float64 => ValueType::Float64,
                            Primitive::Void => todo!(),
                            Primitive::Bool => ValueType::Bool,
                            Primitive::Int32 => todo!(),
                            Primitive::Int64 => ValueType::Int64,
                        },
                        Type::String => todo!(),
                        Type::Array(array) => todo!(),
                        Type::Object(object) => todo!(),
                    }
                )
            },
        };

        let direction = match info.direction() {
            cmajor::endpoint::EndpointDirection::Input => EndpointDirection::Input,
            cmajor::endpoint::EndpointDirection::Output => EndpointDirection::Output,
        };

        let annotation = serde_json::ser::to_string(info.annotation()).unwrap();

        Self { kind, direction, annotation }
    }

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
