use std::{
    f32::consts::E,
    primitive,
    sync::{Arc, Mutex},
};

use cmajor::value::Value;
use cmajor::{
    endpoint::{EndpointDirection, EndpointInfo, EventEndpoint, StreamEndpoint, ValueEndpoint},
    engine::{Engine, Loaded},
    performer::{
        Endpoint, InputEvent, InputStream, InputValue, OutputEvent, OutputStream, OutputValue,
    },
    value::types::{Array, Object, Primitive, Type},
};
use crossbeam::atomic::AtomicCell;
use crossbeam_queue::ArrayQueue;

use crate::api::endpoint::{EndpointKind};

#[derive(Clone, PartialEq)]
pub enum InputStreamHandle {
    MonoFloat32(Endpoint<InputStream<f32>>),
    StereoFloat32(Endpoint<InputStream<[f32; 2]>>),
    Err(&'static str),
}

impl InputStreamHandle {
    fn from_endpoint(engine: &mut Engine<Loaded>, endpoint: &StreamEndpoint) -> Self {
        let id = endpoint.id();
        match endpoint.ty() {
            Type::Primitive(Primitive::Float32) => Self::MonoFloat32(engine.endpoint(id).unwrap()),
            Type::Array(array) => match array.elem_ty() {
                Type::Primitive(Primitive::Float32) => match array.len() {
                    2 => Self::StereoFloat32(engine.endpoint(id).unwrap()),
                    _ => Self::Err("unsupported endpoint type array stream"),
                },
                Type::Primitive(_) => Self::Err("unsupported endpoint type stream"),
                Type::Array(_) => Self::Err("unsupported endpoint type array stream"),
                Type::Object(_) => Self::Err("unsupported endpoint type array stream"),
                Type::String => Self::Err("unsupported endpoint type array stream"),
            },
            Type::Primitive(_) => Self::Err("unsupported endpoint type stream"),
            Type::String => Self::Err("unsupported endpoint type string stream"),
            Type::Object(_) => Self::Err("unsupported endpoint type object stream"),
        }
    }

    pub fn get_type(&self) -> &str {
        match self {
            Self::MonoFloat32(_) => "float32",
            Self::StereoFloat32(_) => "float32<2>",
            Self::Err(_) => "unknown"
        }
    }
}

#[derive(Clone, PartialEq)]
pub enum OutputStreamHandle {
    MonoFloat32(Endpoint<OutputStream<f32>>),
    StereoFloat32(Endpoint<OutputStream<[f32; 2]>>),
    Err(&'static str),
}

impl OutputStreamHandle {
    fn from_endpoint(engine: &mut Engine<Loaded>, endpoint: &StreamEndpoint) -> Self {
        let id = endpoint.id();
        match endpoint.ty() {
            Type::Primitive(Primitive::Float32) => Self::MonoFloat32(engine.endpoint(id).unwrap()),
            Type::Array(array) => match array.elem_ty() {
                Type::Primitive(Primitive::Float32) => match array.len() {
                    2 => Self::StereoFloat32(engine.endpoint(id).unwrap()),
                    _ => Self::Err("unsupported endpoint type array stream"),
                },
                Type::Primitive(_) => Self::Err("unsupported endpoint type stream"),
                Type::Array(_) => Self::Err("unsupported endpoint type array stream"),
                Type::Object(_) => Self::Err("unsupported endpoint type array stream"),
                Type::String => Self::Err("unsupported endpoint type array stream"),
            },
            Type::Primitive(_) => Self::Err("unsupported endpoint type stream"),
            Type::String => Self::Err("unsupported endpoint type string stream"),
            Type::Object(_) => Self::Err("unsupported endpoint type object stream"),
        }
    }

    pub fn get_type(&self) -> &str {
        match self {
            Self::MonoFloat32(_) => "float32",
            Self::StereoFloat32(_) => "float32<2>",
            Self::Err(_) => "unknown"
        }
    }
}

#[derive(Clone, PartialEq)]
pub enum InputValueHandle {
    Float32(Endpoint<InputValue<f32>>),
    Float64(Endpoint<InputValue<f64>>),
    Int32(Endpoint<InputValue<i32>>),
    Int64(Endpoint<InputValue<i64>>),
    Bool(Endpoint<InputValue<bool>>),
    Object {
        handle: Endpoint<OutputValue<Object>>,
        object: Box<Object>,
    },
    Err(&'static str),
}

impl InputValueHandle {
    fn from_endpoint(engine: &mut Engine<Loaded>, endpoint: &ValueEndpoint) -> Self {
        // Get the endpoint id
        let id = endpoint.id();

        // Ensure it's a primitive otherwise error
        let primitive = match endpoint.ty() {
            Type::Primitive(p) => p,
            Type::String => return Self::Err("unsupported endpoint type string value"),
            Type::Array(_) => return Self::Err("unsupported endpoint type array value"),
            Type::Object(object) => {
                return Self::Object {
                    handle: engine.endpoint(id).unwrap(),
                    object: object.clone(),
                };
            }
        };

        // Match on the specific primitive variant
        match primitive {
            Primitive::Float32 => Self::Float32(engine.endpoint(id).unwrap()),
            Primitive::Float64 => Self::Float64(engine.endpoint(id).unwrap()),
            Primitive::Int32 => Self::Int32(engine.endpoint(id).unwrap()),
            Primitive::Int64 => Self::Int64(engine.endpoint(id).unwrap()),
            Primitive::Bool => Self::Bool(engine.endpoint(id).unwrap()),
            Primitive::Void => return Self::Err("unsupported endpoint type void value"),
        }
    }

    pub fn get_type(&self) -> &str {
        match self {
            Self::Float32(_) => "float32",
            Self::Float64(_) => "float64",
            Self::Int32(_) => "int32",
            Self::Int64(_) => "int64",
            Self::Bool(_) => "bool",
            Self::Object { object, .. } => object.class(),
            Self::Err(_) => "unknown"
        }
    }
}

#[derive(Clone, PartialEq)]
pub enum OutputValueHandle {
    Float32(Endpoint<OutputValue<f32>>),
    Float64(Endpoint<OutputValue<f64>>),
    Int32(Endpoint<OutputValue<i32>>),
    Int64(Endpoint<OutputValue<i64>>),
    Bool(Endpoint<OutputValue<bool>>),
    Object {
        handle: Endpoint<OutputValue<Object>>,
        object: Box<Object>,
    },
    Err(&'static str),
}

impl OutputValueHandle {
    fn from_endpoint(engine: &mut Engine<Loaded>, endpoint: &ValueEndpoint) -> Self {
        // Get the endpoint id
        let id = endpoint.id();

        // Ensure it's a primitive otherwise error
        let primitive = match endpoint.ty() {
            Type::Primitive(p) => p,
            Type::String => return Self::Err("unsupported endpoint type string value"),
            Type::Array(_) => return Self::Err("unsupported endpoint type array value"),
            Type::Object(object) => {
                return Self::Object {
                    handle: engine.endpoint(id).unwrap(),
                    object: object.clone(),
                };
            }
        };

        // Match on the specific primitive variant
        match primitive {
            Primitive::Float32 => Self::Float32(engine.endpoint(id).unwrap()),
            Primitive::Float64 => Self::Float64(engine.endpoint(id).unwrap()),
            Primitive::Int32 => Self::Int32(engine.endpoint(id).unwrap()),
            Primitive::Int64 => Self::Int64(engine.endpoint(id).unwrap()),
            Primitive::Bool => Self::Bool(engine.endpoint(id).unwrap()),
            Primitive::Void => return Self::Err("unsupported endpoint type void value"),
        }
    }

    pub fn get_type(&self) -> &str {
        match self {
            Self::Float32(_) => "float32",
            Self::Float64(_) => "float64",
            Self::Int32(_) => "int32",
            Self::Int64(_) => "int64",
            Self::Bool(_) => "bool",
            Self::Object { object, .. } => object.class(),
            Self::Err(_) => "unknown"
        }
    }
}

#[derive(Clone, PartialEq)]
pub struct InputEventHandle {
    pub handle: Endpoint<InputEvent>,
    pub types: Vec<Type>,
}

impl InputEventHandle {
    fn from_endpoint(engine: &mut Engine<Loaded>, endpoint: &EventEndpoint) -> Result<Self, &'static str> {
        // Get the endpoint id
        let id = endpoint.id();

        match engine.endpoint(id) {
            Ok(handle) => {
                let types = endpoint.types().to_vec();
                Ok(Self {
                    handle,
                    types,
                })
            }
            Err(_) => Err("unsupported endpoint type")
        }
    }

    pub fn get_type(&self) -> &str {
        "event"
    }
}

#[derive(Clone, PartialEq)]
pub struct OutputEventHandle {
    pub handle: Endpoint<OutputEvent>,
    pub types: Vec<Type>,
}

impl OutputEventHandle {
    fn from_endpoint(engine: &mut Engine<Loaded>, endpoint: &EventEndpoint) -> Result<Self, &'static str> {
        // Get the endpoint id
        let id = endpoint.id();

        match engine.endpoint(id) {
            Ok(handle) => {
                let types = endpoint.types().to_vec();
                Ok(Self {
                    handle,
                    types,
                })
            }
            Err(_) => Err("unsupported endpoint type")
        }
    }

    pub fn get_type(&self) -> &str {
        "event"
    }
}

#[derive(PartialEq, Clone)]
pub enum InputHandle {
    Stream(InputStreamHandle),
    Value(InputValueHandle),
    Event(InputEventHandle),
}

impl InputHandle {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Self {
        // Build normal endpoint
        match info {
            EndpointInfo::Stream(stream) => {
                InputHandle::Stream(InputStreamHandle::from_endpoint(engine, stream))
            }
            EndpointInfo::Event(event) => {
                InputHandle::Event(
                    InputEventHandle::from_endpoint(engine, event).unwrap()
                )
            }
            EndpointInfo::Value(value) => {
                InputHandle::Value(InputValueHandle::from_endpoint(engine, value))
            }
        }
    }

    pub fn get_kind(&self) -> EndpointKind {
        match self {
            Self::Stream(_) => EndpointKind::Stream,
            Self::Value(_) => EndpointKind::Value,
            Self::Event(_) => EndpointKind::Event,
        }
    }

    pub fn get_type(&self) -> &str {
        match self {
            Self::Stream(handle) => handle.get_type(),
            Self::Value(handle) => handle.get_type(),
            Self::Event(handle) => handle.get_type(),
        }
    }
}

#[derive(Clone)]
pub enum OutputHandle {
    Stream {
        handle: OutputStreamHandle,
        feedback: Arc<AtomicCell<f32>>,
    },
    Value {
        handle: OutputValueHandle,
        feedback: Arc<AtomicCell<bool>>,
    },
    Event {
        handle: OutputEventHandle,
        feedback: Arc<AtomicCell<usize>>
    },
}

impl OutputHandle {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Self {
        // Build normal endpoint
        match info {
            EndpointInfo::Stream(stream) => {
                OutputHandle::Stream {
                    handle: OutputStreamHandle::from_endpoint(engine, stream),
                    feedback: Arc::new(AtomicCell::new(0.0)),
                }
            }
            EndpointInfo::Event(event) => {
                OutputHandle::Event {
                    handle: OutputEventHandle::from_endpoint(engine, event).unwrap(),
                    feedback: Arc::new(AtomicCell::new(0)),
                }
            }
            EndpointInfo::Value(value) => {
                OutputHandle::Value {
                    handle: OutputValueHandle::from_endpoint(engine, value),
                    feedback: Arc::new(AtomicCell::new(false)),
                }
            }
        }
    }

    pub fn get_kind(&self) -> EndpointKind {
        match self {
            Self::Stream { .. } => EndpointKind::Stream,
            Self::Value { .. } => EndpointKind::Value,
            Self::Event { .. } => EndpointKind::Event,
        }
    }

    pub fn get_type(&self) -> &str {
        match self {
            Self::Stream { handle, ..} => handle.get_type(),
            Self::Value{ handle, ..} => handle.get_type(),
            Self::Event{ handle, .. } => handle.get_type(),
        }
    }
}

impl PartialEq for OutputHandle {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (OutputHandle::Stream { handle: a, .. }, OutputHandle::Stream { handle: b, .. }) => a == b,
            (OutputHandle::Value { handle: a, .. }, OutputHandle::Value { handle: b, .. }) => a == b,
            (OutputHandle::Event { handle: a, .. }, OutputHandle::Event { handle: b, .. }) => a == b,
            _ => false,
        }
    }
}

#[derive(Clone)]
pub enum InputEndpoint {
    Endpoint(InputHandle),
    External {
        handle: InputHandle,
        channel: usize,
    },
    Widget {
        handle: InputHandle,
        queue: Arc<ArrayQueue<Value>>,
    }
}

impl InputEndpoint {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Self {
        // Get the endpoint annotation
        let annotation = info.annotation();

        // Build widget endpoints
        if let Some(_) = annotation.get("widget") {
            return Self::Widget {
                handle: InputHandle::from_info(engine, info),
                queue: Arc::new(ArrayQueue::new(32)),
            };
        }

        // Build external endpoints
        if let Some(channel) = annotation.get("external") {
            let channel = channel.as_u64().unwrap_or(0) as usize;
            return Self::External {
                handle: InputHandle::from_info(engine, info),
                channel,
            };
        }

        // Build regular endpoints
        return Self::Endpoint(
            InputHandle::from_info(engine, info),
        );
    }

    fn is_external(&self) -> bool {
        match self {
            InputEndpoint::External { .. } => true,
            _ => false,
        }
    }

    fn get_kind(&self) -> EndpointKind {
        match self {
            InputEndpoint::Endpoint(handle) => handle.get_kind(),
            InputEndpoint::External { handle, .. } => handle.get_kind(),
            InputEndpoint::Widget { handle, .. } => handle.get_kind(),
        }
    }

    fn get_type(&self) -> &str {
        match self {
            InputEndpoint::Endpoint(handle) => handle.get_type(),
            InputEndpoint::External { handle, .. } => handle.get_type(),
            InputEndpoint::Widget { handle, .. } => handle.get_type(),
        }
    }
}

impl PartialEq for InputEndpoint {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (InputEndpoint::Endpoint(a), InputEndpoint::Endpoint(b)) => a == b,
            (InputEndpoint::External { handle, .. }, InputEndpoint::External { handle: other, .. }) => handle == other,
            (InputEndpoint::Widget { handle, .. }, InputEndpoint::Widget { handle: other, .. }) => handle == other,
            _ => false,
        }
    }
}

#[derive(Clone)]
pub enum OutputEndpoint {
    Endpoint(OutputHandle),
    External {
        handle: OutputHandle,
        channel: usize,
    },
    Widget {
        handle: OutputHandle,
        queue: Arc<ArrayQueue<Value>>,
    }
}

impl OutputEndpoint {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Self {
        // Get the endpoint annotation
        let annotation = info.annotation();

        // Build widget endpoints
        if let Some(_) = annotation.get("widget") {
            return Self::Widget {
                handle: OutputHandle::from_info(engine, info),
                queue: Arc::new(ArrayQueue::new(32)),
            };
        }

        // Build external endpoints
        if let Some(channel) = annotation.get("external") {
            let channel = channel.as_u64().unwrap_or(0) as usize;
            return Self::External {
                handle: OutputHandle::from_info(engine, info),
                channel,
            };
        }

        // Build regular endpoints
        return Self::Endpoint(
            OutputHandle::from_info(engine, info),
        );
    }

    fn is_external(&self) -> bool {
        match self {
            OutputEndpoint::External { .. } => true,
            _ => false,
        }
    }

    fn get_kind(&self) -> EndpointKind {
        match self {
            OutputEndpoint::Endpoint(handle) => handle.get_kind(),
            OutputEndpoint::External { handle, .. } => handle.get_kind(),
            OutputEndpoint::Widget { handle, .. } => handle.get_kind(),
        }
    }

    fn get_type(&self) -> &str {
        match self {
            OutputEndpoint::Endpoint(handle) => handle.get_type(),
            OutputEndpoint::External { handle, .. } => handle.get_type(),
            OutputEndpoint::Widget { handle, .. } => handle.get_type(),
        }
    }
}

impl PartialEq for OutputEndpoint {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (OutputEndpoint::Endpoint(h1), OutputEndpoint::Endpoint(h2)) => h1 == h2,
            (OutputEndpoint::External { handle, .. }, OutputEndpoint::External { handle: other, .. }) => handle == other,
            (OutputEndpoint::Widget { handle, .. }, OutputEndpoint::Widget { handle: other, .. }) => handle == other,
            _ => false,
        }
    }
}

#[derive(PartialEq, Clone)]
pub enum EndpointHandle {
    Input(InputEndpoint),
    Output(OutputEndpoint),
}

impl EndpointHandle {
    pub fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Self {
        return match info.direction() {
            EndpointDirection::Input => Self::Input(
                InputEndpoint::from_info(engine, info),
            ),
            EndpointDirection::Output => Self::Output(
                OutputEndpoint::from_info(engine, info),
            ),
        };
    }

    pub fn is_input(&self) -> bool {
        match self {
            EndpointHandle::Input(_) => true,
            EndpointHandle::Output(_) => false,
        }
    }

    pub fn is_external(&self) -> bool {
        match self {
            EndpointHandle::Input(handle) => handle.is_external(),
            EndpointHandle::Output(handle) => handle.is_external(),
        }
    }

    pub fn get_kind(&self) -> EndpointKind {
        match self {
            EndpointHandle::Input(handle) => handle.get_kind(),
            EndpointHandle::Output(handle) => handle.get_kind(),
        }
    }

    pub fn get_type(&self) -> &str {
        match self {
            EndpointHandle::Input(handle) => handle.get_type(),
            EndpointHandle::Output(handle) => handle.get_type(),
        }
    }
}
