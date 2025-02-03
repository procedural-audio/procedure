use std::{f32::consts::E, primitive, sync::{Arc, Mutex}};

use cmajor::{endpoint::{self, EndpointDirection, EndpointInfo, StreamEndpoint, ValueEndpoint}, engine::{Engine, Loaded}, performer::{Endpoint, EndpointType, InputEvent, InputStream, InputValue, OutputEvent, OutputStream, OutputValue}, value::types::{Array, Primitive, Type}};
use cmajor::value::Value;
use crossbeam_queue::ArrayQueue;
use crossbeam::atomic::AtomicCell;

use flutter_rust_bridge::*;

#[derive(Copy, Clone, PartialEq)]
#[frb(ignore)]
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
#[frb(ignore)]
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
#[frb(ignore)]
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

#[derive(Clone)]
#[frb(ignore)]
pub enum InputWidgetHandle {
    Event {
        handle: Endpoint<InputEvent>,
        queue: Arc<ArrayQueue<Value>>,
    },
    Value {
        handle: Endpoint<InputValue<Value>>,
        queue: Arc<ArrayQueue<Value>>,
    },
}

impl InputWidgetHandle {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Result<Self, &'static str> {
        let id = info.id();

        let handle = match info {
            EndpointInfo::Event(_) => Self::Event {
                handle: engine.endpoint(id).unwrap(),
                queue: Arc::new(
                    ArrayQueue::new(32)
                ),
            },
            EndpointInfo::Value(_) => Self::Value {
                handle: engine.endpoint(id).unwrap(),
                queue: Arc::new(
                    ArrayQueue::new(1)
                ),
            },
            _ => return Err("unsupported widget endpoint type")
        };

        Ok(handle)
    }
}

impl PartialEq for InputWidgetHandle {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::Event { handle, .. }, Self::Event { handle: other, .. }) => handle == other,
            (Self::Value { handle, .. }, Self::Value { handle: other, .. }) => handle == other,
            _ => false
        }
    }
}

#[derive(Copy, Clone, PartialEq)]
#[frb(ignore)]
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

#[derive(Clone)]
#[frb(ignore)]
pub enum OutputWidgetHandle {
    Event {
        handle: Endpoint<OutputEvent>,
        queue: Arc<ArrayQueue<Value>>,
    },
    Value {
        handle: Endpoint<OutputValue<Value>>,
        queue: Arc<ArrayQueue<Value>>,
    },
}

impl OutputWidgetHandle {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Result<Self, &'static str> {
        let id = info.id();

        let handle = match info {
            EndpointInfo::Event(_) => Self::Event {
                handle: engine.endpoint(id).unwrap(),
                queue: Arc::new(
                    ArrayQueue::new(32)
                ),
            },
            EndpointInfo::Value(_) => Self::Value {
                handle: engine.endpoint(id).unwrap(),
                queue: Arc::new(
                    ArrayQueue::new(1)
                ),
            },
            _ => return Err("unsupported widget endpoint type")
        };

        Ok(handle)
    }
}

impl PartialEq for OutputWidgetHandle {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::Event { handle, .. }, Self::Event { handle: other, .. }) => handle == other,
            (Self::Value { handle, .. }, Self::Value { handle: other, .. }) => handle == other,
            _ => false
        }
    }
}

#[derive(PartialEq, Clone)]
#[frb(ignore)]
pub enum InputHandle {
    Stream(InputStreamHandle),
    Value(InputValueHandle),
    Event(Endpoint<InputEvent>),
    Widget(InputWidgetHandle),
}

impl InputHandle {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Result<Self, &'static str> {
        // Get the endpoint annotation
        let annotation = info.annotation();

        // Build widget endpoint
        if annotation.contains_key("widget") {
            return Ok(
                Self::Widget(
                    InputWidgetHandle::from_info(engine, info)?
                )
            );
        }

        // Build normal endpoint
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

#[derive(PartialEq, Clone)]
#[frb(ignore)]
pub enum OutputHandle {
    Stream(OutputStreamHandle),
    Value(OutputValueHandle),
    Event(Endpoint<OutputEvent>),
    Widget(OutputWidgetHandle),
}

impl OutputHandle {
    fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Result<Self, &'static str> {
        // Get the endpoint annotation
        let annotation = info.annotation();

        // Build widget endpoint
        if annotation.contains_key("widget") {
            return Ok(
                Self::Widget(
                    OutputWidgetHandle::from_info(engine, info)?
                )
            );
        }

        // Build normal endpoint
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
#[frb(ignore)]
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
}

impl EndpointHandle {
    #[frb(ignore)]
    pub fn from_info(engine: &mut Engine<Loaded>, info: &EndpointInfo) -> Result<Self, &'static str> {
        // Get the endpoint annotation
        let annotation = info.annotation();

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