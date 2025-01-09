use cmajor::{endpoint::{EndpointHandle, EndpointInfo}, performer::EndpointType, engine::{Engine, Loaded}, performer::OutputStream, value::types::{Primitive, Type}};

use flutter_rust_bridge::*;

#[derive(Copy, Clone)]
pub enum EndpointKind {
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

/*pub enum Endpoint2 {
    Input(EndpointKind),
    Output(EndpointKind),
}*/

#[derive(Clone)]
#[frb(non_opaque)]
pub struct Endpoint {
    // handle: EndpointHandle,
    // info: EndpointInfo,
    pub handle: u32,
    pub kind: EndpointKind,
    pub direction: EndpointDirection,
    pub annotation: String,
}

impl Endpoint {
    #[frb(ignore)]
    pub fn from(engine: &mut Engine<Loaded>, info: EndpointInfo) -> Result<Self, &'static str> {
        let id = info.id();

        // let endpoint = engine.endpoint::<OutputStream<f32>>(id).unwrap();
        // let handle: u32 = endpoint.0.handle().into();

        let kind = match &info {
            EndpointInfo::Stream(endpoint) => {
                EndpointKind::Stream(
                    match endpoint.ty() {
                        Type::Primitive(primitive) => match primitive {
                            Primitive::Float32 => StreamType::Float32,
                            Primitive::Float64 => StreamType::Float64,
                            Primitive::Void => return Err("unsupported endpoint type void stream"),
                            Primitive::Bool => return Err("unsupported endpoint type bool stream"),
                            Primitive::Int32 => return Err("unsupported endpoint type int32 stream"),
                            Primitive::Int64 => return Err("unsupported endpoint type int64 stream"),
                        },
                        Type::String => return Err("unsupported endpoint type string stream"),
                        Type::Array(array) => return Err("unsupported endpoint type array stream"),
                        Type::Object(object) => return Err("unsupported endpoint type object stream"),
                    }
                )
            },
            EndpointInfo::Event(endpoint) => {
                /*EndpointKind::Event(
                    match endpoint.ty() {
                        Type::Primitive(primitive) => match primitive {
                            Primitive::Float32 => return Err("unsupported endpoint type float32 event"),
                            Primitive::Float64 => return Err("unsupported endpoint type float64 event"),
                            Primitive::Void => return Err("unsupported endpoint type void stream"),
                            Primitive::Bool => return Err("unsupported endpoint type bool stream"),
                            Primitive::Int32 => return Err("unsupported endpoint type int32 stream"),
                            Primitive::Int64 => return Err("unsupported endpoint type int64 stream"),
                        },
                        Type::String => return Err("unsupported endpoint type string stream"),
                        Type::Array(array) => return Err("unsupported endpoint type array stream"),
                        Type::Object(object) => return Err("unsupported endpoint type object stream"),
                    }
                )*/

                return Err("unsupported endpoint type event");
            },
            EndpointInfo::Value(value_endpoint) => {
                EndpointKind::Value(
                    match value_endpoint.ty() {
                        Type::Primitive(primitive) => match primitive {
                            Primitive::Float32 => ValueType::Float64,
                            Primitive::Float64 => ValueType::Float64,
                            Primitive::Void => return Err("unsupported endpoint type void value"),
                            Primitive::Bool => ValueType::Bool,
                            Primitive::Int32 => return Err("unsupported endpoint type int32 value"),
                            Primitive::Int64 => ValueType::Int64,
                        },
                        Type::String => return Err("unsupported endpoint type string value"),
                        Type::Array(array) => return Err("unsupported endpoint type array value"),
                        Type::Object(object) => return Err("unsupported endpoint type object value"),
                    }
                )
            },
        };

        let direction = match info.direction() {
            cmajor::endpoint::EndpointDirection::Input => EndpointDirection::Input,
            cmajor::endpoint::EndpointDirection::Output => EndpointDirection::Output,
        };

        let annotation = serde_json::ser::to_string(info.annotation()).unwrap();

        Ok(Self { handle: 0, kind, direction, annotation })
    }

    #[frb(sync, getter)]
    pub fn get_type(&self) -> EndpointKind {
        self.kind
    }
}

/*#[frb]
#[derive(Clone)]
pub struct EndpointInfo {
    pub kind: EndpointKind,
    pub top: Option<u32>,
}*/
