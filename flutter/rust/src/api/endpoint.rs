use std::{f32::consts::E, primitive, sync::{Arc, Mutex}};

use cmajor::{endpoint::{self, EndpointDirection, EndpointInfo, StreamEndpoint, ValueEndpoint}, engine::{Engine, Loaded}, performer::{Endpoint, EndpointType, InputEvent, InputStream, InputValue, OutputEvent, OutputStream, OutputValue}, value::types::{Array, Primitive, Type}};
use cmajor::value::Value;
use crossbeam_queue::ArrayQueue;

use flutter_rust_bridge::*;

static QUEUE_SIZE: usize = 4;

#[derive(Copy, Clone, PartialEq)]
pub enum InputStreamHandle {
    MonoFloat32(Endpoint<InputStream<f32>>),
    StereoFloat32(Endpoint<InputStream<[f32; 2]>>),
}

impl InputStreamHandle {
    fn from_endpoint(engine: &mut Engine<Loaded>, endpoint: &StreamEndpoint) -> Result<Self, &'static str> {
        let id = endpoint.id();
        let stream_handle = match endpoint.ty() {
            Type::Primitive(Primitive::Float32) => {
                Self::MonoFloat32(
                    engine.endpoint(id).unwrap()
                )
            },
            Type::Array(array) => {
                match array.elem_ty() {
                    Type::Primitive(Primitive::Float32) => {
                        match array.len() {
                            2 => Self::StereoFloat32(
                                engine.endpoint(id).unwrap()
                            ),
                            _ => return Err("unsupported endpoint type array stream"),
                        }
                    },
                    Type::Primitive(_) => return Err("unsupported endpoint type stream"),
                    Type::Array(_) => return Err("unsupported endpoint type array stream"),
                    Type::Object(_) => return Err("unsupported endpoint type array stream"),
                    Type::String => return Err("unsupported endpoint type array stream"),
                }
            },
            Type::Primitive(_) => return Err("unsupported endpoint type stream"),
            Type::String => return Err("unsupported endpoint type string stream"),
            Type::Object(_) => return Err("unsupported endpoint type object stream"),
        };

        Ok(stream_handle)
    }
}

#[derive(Copy, Clone, PartialEq)]
pub enum OutputStreamHandle {
    MonoFloat32(Endpoint<OutputStream<f32>>),
    StereoFloat32(Endpoint<OutputStream<[f32; 2]>>),
}

impl OutputStreamHandle {
    fn from_endpoint(engine: &mut Engine<Loaded>, endpoint: &StreamEndpoint) -> Result<Self, &'static str> {
        let id = endpoint.id();
        let stream_handle = match endpoint.ty() {
            Type::Primitive(Primitive::Float32) => {
                Self::MonoFloat32(
                    engine.endpoint(id).unwrap()
                )
            },
            Type::Array(array) => {
                match array.elem_ty() {
                    Type::Primitive(Primitive::Float32) => {
                        match array.len() {
                            2 => Self::StereoFloat32(
                                engine.endpoint(id).unwrap()
                            ),
                            _ => return Err("unsupported endpoint type array stream"),
                        }
                    },
                    Type::Primitive(_) => return Err("unsupported endpoint type stream"),
                    Type::Array(_) => return Err("unsupported endpoint type array stream"),
                    Type::Object(_) => return Err("unsupported endpoint type array stream"),
                    Type::String => return Err("unsupported endpoint type array stream"),
                }
            },
            Type::Primitive(_) => return Err("unsupported endpoint type stream"),
            Type::String => return Err("unsupported endpoint type string stream"),
            Type::Object(_) => return Err("unsupported endpoint type object stream"),
        };

        Ok(stream_handle)
    }
}

#[derive(Copy, Clone, PartialEq)]
pub enum InputValueHandle {
    Float32(Endpoint<InputValue<f32>>),
    Float64(Endpoint<InputValue<f64>>),
    Int32(Endpoint<InputValue<i32>>),
    Int64(Endpoint<InputValue<i64>>),
    Bool(Endpoint<InputValue<bool>>),
}

impl InputValueHandle {
    fn from_endpoint(engine: &mut Engine<Loaded>, endpoint: &ValueEndpoint) -> Result<Self, &'static str> {
        // Ensure it's a primitive otherwise error
        let primitive = match endpoint.ty() {
            Type::Primitive(p) => p,
            Type::String => return Err("unsupported endpoint type string value"),
            Type::Array(_) => return Err("unsupported endpoint type array value"),
            Type::Object(_) => return Err("unsupported endpoint type object value"),
        };

        // Get the endpoint id
        let id = endpoint.id();

        // Match on the specific primitive variant
        let value_handle = match primitive {
            Primitive::Float32 => Self::Float32(
                engine.endpoint(id).unwrap()
            ),
            Primitive::Float64 => Self::Float64(
                engine.endpoint(id).unwrap()
            ),
            Primitive::Int32 => Self::Int32(
                engine.endpoint(id).unwrap()
            ),
            Primitive::Int64 => Self::Int64(
                engine.endpoint(id).unwrap()
            ),
            Primitive::Bool => return Err("unsupported endpoint type bool value"),
            Primitive::Void => return Err("unsupported endpoint type void value"),
        };

        Ok(value_handle)
    }
}

#[derive(Copy, Clone, PartialEq)]
pub enum OutputValueHandle {
    Float32(Endpoint<OutputValue<f32>>),
    Float64(Endpoint<OutputValue<f64>>),
    Int32(Endpoint<OutputValue<i32>>),
    Int64(Endpoint<OutputValue<i64>>),
    Bool(Endpoint<OutputValue<bool>>),
}

impl OutputValueHandle {
    fn from_endpoint(engine: &mut Engine<Loaded>, endpoint: &ValueEndpoint) -> Result<Self, &'static str> {
        // Ensure it's a primitive otherwise error
        let primitive = match endpoint.ty() {
            Type::Primitive(p) => p,
            Type::String => return Err("unsupported endpoint type string value"),
            Type::Array(_) => return Err("unsupported endpoint type array value"),
            Type::Object(_) => return Err("unsupported endpoint type object value"),
        };

        // Get the endpoint id
        let id = endpoint.id();

        // Match on the specific primitive variant
        let value_handle = match primitive {
            Primitive::Float32 => Self::Float32(
                engine.endpoint(id).unwrap()
            ),
            Primitive::Float64 => Self::Float64(
                engine.endpoint(id).unwrap()
            ),
            Primitive::Int32 => Self::Int32(
                engine.endpoint(id).unwrap()
            ),
            Primitive::Int64 => Self::Int64(
                engine.endpoint(id).unwrap()
            ),
            Primitive::Bool => return Err("unsupported endpoint type bool value"),
            Primitive::Void => return Err("unsupported endpoint type void value"),
        };

        Ok(value_handle)
    }
}

#[derive(Copy, Clone, PartialEq)]
pub enum InputHandle {
    Stream(InputStreamHandle),
    Value(InputValueHandle),
    Event(Endpoint<InputEvent>),
}

impl InputHandle {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Result<Self, &'static str> {
        let handle = match info {
            EndpointInfo::Stream(stream) => InputHandle::Stream(
                InputStreamHandle::from_endpoint(engine, stream)?
            ),
            EndpointInfo::Event(e) => InputHandle::Event(
                engine.endpoint(e.id()).unwrap()
            ),
            EndpointInfo::Value(value) => InputHandle::Value(
                InputValueHandle::from_endpoint(engine, value)?
            )
        };

        Ok(handle)
    }
}

#[derive(Copy, Clone, PartialEq)]
pub enum OutputHandle {
    Stream(OutputStreamHandle),
    Value(OutputValueHandle),
    Event(Endpoint<OutputEvent>),
}

impl OutputHandle {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Result<Self, &'static str> {
        let handle = match info {
            EndpointInfo::Stream(stream) => OutputHandle::Stream(
                OutputStreamHandle::from_endpoint(engine, stream)?
            ),
            EndpointInfo::Event(e) => OutputHandle::Event(
                engine.endpoint(e.id()).unwrap()
            ),
            EndpointInfo::Value(value) => OutputHandle::Value(
                OutputValueHandle::from_endpoint(engine, value)?
            )
        };

        Ok(handle)
    }
}

#[derive(Clone)]
pub enum WidgetHandle {
    Event {
        handle: Endpoint<InputEvent>,
        queue: Arc<ArrayQueue<Value>>,
    },
    Value {
        handle: Endpoint<InputValue<Value>>,
        queue: Arc<ArrayQueue<Value>>,
    },
}

impl WidgetHandle {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Result<Self, &'static str> {
        let id = info.id();
        let annotation = info.annotation();

        let queue = ArrayQueue::new(QUEUE_SIZE);

        let handle = match info {
            EndpointInfo::Event(_) => WidgetHandle::Event {
                handle: engine.endpoint(id).unwrap(),
                queue: Arc::new(queue),
            },
            EndpointInfo::Value(_) => WidgetHandle::Value {
                handle: engine.endpoint(id).unwrap(),
                queue: Arc::new(queue),
            },
            _ => return Err("unsupported widget endpoint type")
        };

        Ok(handle)
    }
}

#[derive(Clone)]
pub enum EndpointHandle {
    Input(InputHandle),
    Output(OutputHandle),
    ExternalInput {
        handle: InputHandle,
        channel: usize
    },
    ExternalOutput {
        handle: OutputHandle,
        channel: usize
    },
    Widget(WidgetHandle)
}

impl EndpointHandle {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Result<Self, &'static str> {
        // Get the endpoint id
        let id = info.id();

        // Get the endpoint annotation
        let annotation = info.annotation();

        // Build widget endpoints
        if annotation.contains_key("widget") {
            let handle = WidgetHandle::from_info(engine, info)?;

            return Ok(
                Self::Widget(handle)
            );
        }

        // Build external endpoints
        if let Some(channel) = annotation.get("external") {
            let channel = channel.as_u64().unwrap_or(0) as usize;

            // Build external endpoints
            let handle = match info.direction() {
                EndpointDirection::Input => {
                    EndpointHandle::ExternalInput {
                        handle: InputHandle::from_info(engine, info)?,
                        channel
                    }
                },
                EndpointDirection::Output => {
                    EndpointHandle::ExternalOutput {
                        handle: OutputHandle::from_info(engine, info)?,
                        channel
                    }
                },
            };

            return Ok(handle);
        }

        // Build regular endpoints
        let handle = match info.direction() {
            EndpointDirection::Input => EndpointHandle::Input(
                InputHandle::from_info(engine, info)?
            ),
            EndpointDirection::Output => EndpointHandle::Output(
                OutputHandle::from_info(engine, info)?
            ),
        };

        Ok(handle)
    }
}

impl PartialEq for EndpointHandle {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (EndpointHandle::Input(a), EndpointHandle::Input(b)) => a == b,
            (EndpointHandle::Output(a), EndpointHandle::Output(b)) => a == b,
            (EndpointHandle::ExternalInput { handle, .. }, EndpointHandle::ExternalInput { handle: other, .. }) => handle == other,
            (EndpointHandle::ExternalOutput { handle, .. }, EndpointHandle::ExternalOutput { handle: other, .. }) => handle == other,
            // (EndpointHandle::Widget { handle, .. }, EndpointHandle::Widget { handle: other, .. }) => handle == other,
            _ => false
        }
    }
}

#[derive(Clone, PartialEq)]
#[frb(opaque)]
pub struct NodeEndpoint {
    pub endpoint: EndpointHandle,
    pub annotation: String,
}

impl NodeEndpoint {
    #[frb(ignore)]
    pub fn from(engine: &mut Engine<Loaded>, info: EndpointInfo, node_id: u32) -> Result<Self, &'static str> {
        let endpoint = EndpointHandle::from_info(engine, &info)?;
        let annotation = serde_json::ser::to_string(info.annotation()).unwrap();

        Ok(
            Self {
                endpoint,
                annotation,
            }
        )
    }

    #[frb(sync, getter)]
    pub fn is_input(&self) -> bool {
        match self.endpoint {
            EndpointHandle::Input(_) => true,
            EndpointHandle::Output(_) => false,
            EndpointHandle::ExternalInput { .. } => true,
            EndpointHandle::ExternalOutput { .. } => false,
            EndpointHandle::Widget { .. } => true
        }
    }

    #[frb(ignore)]
    pub fn write_value(&self, value: Value) -> Result<(), &'static str> {
        match &self.endpoint {
            EndpointHandle::Widget(handle) => {
                match handle {
                    WidgetHandle::Event { queue, .. } => {
                        queue.force_push(value);
                    }
                    WidgetHandle::Value { queue, .. } => {
                        queue.force_push(value);
                    }
                    _ => return Err("endpoint is not a widget handle")
                }
            }
            _ => return Err("endpoint is not a widget")
        }

        Ok(())
    }

    #[frb(sync)]
    pub fn write_float(&self, v: f64) -> Result<(), String> {
        self
            .write_value(Value::Float32(v as f32))
            .map_err(| e | e.to_string())
    }

    #[frb(sync)]
    pub fn write_int(&self, v: i64) -> Result<(), String> {
        self
            .write_value(Value::Int64(v))
            .map_err(| e | e.to_string())
    }

    #[frb(sync)]
    pub fn write_bool(&self, b: bool) -> Result<(), String> {
        self
            .write_value(Value::Bool(b))
            .map_err(| e | e.to_string())
    }

    #[frb(sync, getter)]
    pub fn get_type(&self) -> EndpointKind {
        match self.endpoint {
            EndpointHandle::Input(handle) => match handle {
                InputHandle::Stream(stream) => EndpointKind::Stream(
                    match stream {
                        InputStreamHandle::MonoFloat32(_) => StreamType::Float32,
                        InputStreamHandle::StereoFloat32(_) => StreamType::Float32,
                    }
                ),
                InputHandle::Value(value) => EndpointKind::Value(
                    match value {
                        InputValueHandle::Float32(_) => ValueType::Float32,
                        InputValueHandle::Float64(_) => ValueType::Float64,
                        InputValueHandle::Int32(_) => ValueType::Int32,
                        InputValueHandle::Int64(_) => ValueType::Int64,
                        InputValueHandle::Bool(_) => ValueType::Bool,
                    }
                ),
                InputHandle::Event(e) => EndpointKind::Event(
                    EventType::Void
                ),
            },
            EndpointHandle::Output(handle) => match handle {
                OutputHandle::Stream(stream) => EndpointKind::Stream(
                    match stream {
                        OutputStreamHandle::MonoFloat32(_) => StreamType::Float32,
                        OutputStreamHandle::StereoFloat32(_) => StreamType::Float32,
                    }
                ),
                OutputHandle::Value(value) => EndpointKind::Value(
                    match value {
                        OutputValueHandle::Float32(_) => ValueType::Float32,
                        OutputValueHandle::Float64(_) => ValueType::Float64,
                        OutputValueHandle::Int32(_) => ValueType::Int32,
                        OutputValueHandle::Int64(_) => ValueType::Int64,
                        OutputValueHandle::Bool(_) => ValueType::Bool,
                    }
                ),
                OutputHandle::Event(e) => EndpointKind::Event(
                    EventType::Void
                ),
            },
            EndpointHandle::Widget { .. } => EndpointKind::Event(EventType::Void),
            EndpointHandle::ExternalInput { handle, channel } => EndpointKind::Stream(StreamType::Float32),
            EndpointHandle::ExternalOutput { handle, channel } => EndpointKind::Stream(StreamType::Float32),
        }
    }
}

#[derive(Copy, Clone)]
pub enum PrimitiveType {
    Float32,
    Float64,
    Int32,
    Int64,
    Void,
    Bool
}

#[derive(Copy, Clone)]
pub enum StreamType {
    Float32,
    Float64,
    Int32,
    Int64,
}

#[derive(Copy, Clone)]
pub enum ValueType {
    Float32,
    Float64,
    Int32,
    Int64,
    Void,
    Bool,
}

#[derive(Copy, Clone)]
pub enum EventType {
    Float32,
    Float64,
    Int32,
    Int64,
    Void,
    Bool,
}

#[derive(Copy, Clone)]
pub enum EndpointKind {
    Stream(StreamType),
    Value(ValueType),
    Event(EventType),
}
