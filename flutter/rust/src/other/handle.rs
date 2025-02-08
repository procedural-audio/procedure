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
use crossbeam_queue::ArrayQueue;

use crate::api::endpoint::{EndpointKind, EndpointType};

#[derive(Copy, Clone, PartialEq)]
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

    pub fn get_type(&self) -> EndpointType {
        match self {
            Self::MonoFloat32(_) => EndpointType::Float,
            Self::StereoFloat32(_) => EndpointType::Float,
            Self::Err(_) => EndpointType::Unsupported,
        }
    }
}

#[derive(Copy, Clone, PartialEq)]
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

    pub fn get_type(&self) -> EndpointType {
        match self {
            Self::MonoFloat32(_) => EndpointType::Float,
            Self::StereoFloat32(_) => EndpointType::Float,
            Self::Err(_) => EndpointType::Unsupported,
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

    pub fn get_type(&self) -> EndpointType {
        match self {
            Self::Float32(_) => EndpointType::Float,
            Self::Float64(_) => EndpointType::Float,
            Self::Int32(_) => EndpointType::Int,
            Self::Int64(_) => EndpointType::Int,
            Self::Bool(_) => EndpointType::Bool,
            Self::Object { object, .. } => EndpointType::Object(object.class().to_string()),
            Self::Err(_) => EndpointType::Unsupported,
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

    pub fn get_type(&self) -> EndpointType {
        match self {
            Self::Float32(_) => EndpointType::Float,
            Self::Float64(_) => EndpointType::Float,
            Self::Int32(_) => EndpointType::Int,
            Self::Int64(_) => EndpointType::Int,
            Self::Bool(_) => EndpointType::Bool,
            Self::Object { object, .. } => EndpointType::Object(object.class().to_string()),
            Self::Err(_) => EndpointType::Unsupported,
        }
    }
}

#[derive(Clone, PartialEq)]
pub enum InputEventHandle {
    Primitive(Endpoint<InputEvent>),
    Object {
        handle: Endpoint<InputEvent>,
        object: Box<Object>,
    },
    Err(&'static str),
}

impl InputEventHandle {
    fn from_endpoint(engine: &mut Engine<Loaded>, endpoint: &EventEndpoint) -> Self {
        // Get the endpoint id
        let id = endpoint.id();

        let types = endpoint.types();

        if types.len() == 1 {
            let ty = &types[0];
            // Ensure it's a primitive otherwise error
            let primitive = match ty {
                Type::Primitive(p) => Self::Primitive(
                    engine.endpoint(id).unwrap()
                ),
                Type::String => return Self::Err("unsupported endpoint type string value"),
                Type::Array(_) => return Self::Err("unsupported endpoint type array value"),
                Type::Object(object) => {
                    return Self::Object {
                        handle: engine.endpoint(id).unwrap(),
                        object: object.clone(),
                    };
                }
            };
        }

        Self::Err("unsupported event endpoint type")
    }

    pub fn get_type(&self) -> EndpointType {
        match self {
            Self::Primitive(_) => EndpointType::Bool,
            Self::Object { object, .. } => EndpointType::Object(object.class().to_string()),
            Self::Err(_) => EndpointType::Unsupported,
        }
    }
}

#[derive(Clone, PartialEq)]
pub enum OutputEventHandle {
    Primitive(Endpoint<OutputEvent>),
    Object {
        handle: Endpoint<OutputEvent>,
        object: Box<Object>,
    },
    Err(&'static str),
}

impl OutputEventHandle {
    fn from_endpoint(engine: &mut Engine<Loaded>, endpoint: &EventEndpoint) -> Self {
        // Get the endpoint id
        let id = endpoint.id();

        let types = endpoint.types();

        if types.len() == 1 {
            let ty = &types[0];
            // Ensure it's a primitive otherwise error
            let primitive = match ty {
                Type::Primitive(p) => Self::Primitive(
                    engine.endpoint(id).unwrap(),
                ),
                Type::String => return Self::Err("unsupported endpoint type string value"),
                Type::Array(_) => return Self::Err("unsupported endpoint type array value"),
                Type::Object(object) => {
                    return Self::Object {
                        handle: engine.endpoint(id).unwrap(),
                        object: object.clone(),
                    };
                }
            };
        }

        Self::Err("unsupported event endpoint type")
    }

    pub fn get_type(&self) -> EndpointType {
        match self {
            Self::Primitive(_) => EndpointType::Bool,
            Self::Object { object, .. } => EndpointType::Object(object.class().to_string()),
            Self::Err(_) => EndpointType::Unsupported,
        }
    }
}

#[derive(Clone)]
pub enum InputWidgetHandle {
    Event {
        handle: Endpoint<InputEvent>,
        queue: Arc<ArrayQueue<Value>>,
    },
    Value {
        handle: Endpoint<InputValue<Value>>,
        queue: Arc<ArrayQueue<Value>>,
    },
    Err(&'static str),
}

impl InputWidgetHandle {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Self {
        let id = info.id();
        match info {
            EndpointInfo::Event(_) => Self::Event {
                handle: engine.endpoint(id).unwrap(),
                queue: Arc::new(ArrayQueue::new(32)),
            },
            EndpointInfo::Value(_) => Self::Value {
                handle: engine.endpoint(id).unwrap(),
                queue: Arc::new(ArrayQueue::new(1)),
            },
            _ => Self::Err("unsupported widget endpoint type"),
        }
    }
}

impl PartialEq for InputWidgetHandle {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::Event { handle, .. }, Self::Event { handle: other, .. }) => handle == other,
            (Self::Value { handle, .. }, Self::Value { handle: other, .. }) => handle == other,
            _ => false,
        }
    }
}

#[derive(Clone)]
pub enum OutputWidgetHandle {
    Event {
        handle: Endpoint<OutputEvent>,
        queue: Arc<ArrayQueue<Value>>,
    },
    Value {
        handle: Endpoint<OutputValue<Value>>,
        queue: Arc<ArrayQueue<Value>>,
    },
    Err(&'static str),
}

impl OutputWidgetHandle {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Self {
        let id = info.id();
        match info {
            EndpointInfo::Event(_) => Self::Event {
                handle: engine.endpoint(id).unwrap(),
                queue: Arc::new(ArrayQueue::new(32)),
            },
            EndpointInfo::Value(_) => Self::Value {
                handle: engine.endpoint(id).unwrap(),
                queue: Arc::new(ArrayQueue::new(1)),
            },
            _ => Self::Err("unsupported widget endpoint type"),
        }
    }
}

impl PartialEq for OutputWidgetHandle {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::Event { handle, .. }, Self::Event { handle: other, .. }) => handle == other,
            (Self::Value { handle, .. }, Self::Value { handle: other, .. }) => handle == other,
            _ => false,
        }
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
                InputHandle::Event(InputEventHandle::from_endpoint(engine, event))
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

    pub fn get_type(&self) -> EndpointType {
        match self {
            Self::Stream(handle) => handle.get_type(),
            Self::Value(handle) => handle.get_type(),
            Self::Event(handle) => handle.get_type(),
        }
    }
}

#[derive(PartialEq, Clone)]
pub enum OutputHandle {
    Stream(OutputStreamHandle),
    Value(OutputValueHandle),
    Event(OutputEventHandle),
}

impl OutputHandle {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Self {
        // Build normal endpoint
        match info {
            EndpointInfo::Stream(stream) => {
                OutputHandle::Stream(OutputStreamHandle::from_endpoint(engine, stream))
            }
            EndpointInfo::Event(event) => {
                OutputHandle::Event(OutputEventHandle::from_endpoint(engine, event))
            }
            EndpointInfo::Value(value) => {
                OutputHandle::Value(OutputValueHandle::from_endpoint(engine, value))
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

    pub fn get_type(&self) -> EndpointType {
        match self {
            Self::Stream(handle) => handle.get_type(),
            Self::Value(handle) => handle.get_type(),
            Self::Event(handle) => handle.get_type(),
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
        if let Some(channel) = annotation.get("widget") {
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

    fn get_type(&self) -> EndpointType {
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
        if let Some(channel) = annotation.get("widget") {
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

    fn get_type(&self) -> EndpointType {
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
            (OutputEndpoint::Endpoint(a), OutputEndpoint::Endpoint(b)) => a == b,
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

    pub fn get_type(&self) -> EndpointType {
        match self {
            EndpointHandle::Input(handle) => handle.get_type(),
            EndpointHandle::Output(handle) => handle.get_type(),
        }
    }
}

