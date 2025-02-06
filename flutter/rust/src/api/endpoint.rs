use cmajor::{endpoint::EndpointInfo, engine::{Engine, Loaded}, performer::OutputStream};
use cmajor::value::Value;

use flutter_rust_bridge::*;

use crate::other::handle::*;

#[derive(PartialEq, Clone)]
#[frb(opaque)]
pub struct NodeEndpoint {
    endpoint: EndpointHandle,
    pub annotation: String,
}

impl NodeEndpoint {
    #[frb(ignore)]
    pub fn from(engine: &mut Engine<Loaded>, info: EndpointInfo, node_id: u32) -> Self {
        let endpoint = EndpointHandle::from_info(engine, &info);
        let annotation = serde_json::ser::to_string(info.annotation()).unwrap();

        Self {
            endpoint,
            annotation,
        }
    }

    #[frb(ignore)]
    pub fn handle(&self) -> &EndpointHandle {
        &self.endpoint
    }

    #[frb(sync, getter)]
    pub fn is_input(&self) -> bool {
        match self.endpoint {
            EndpointHandle::Input(_) => true,
            EndpointHandle::Output(_) => false,
            EndpointHandle::ExternalInput { .. } => true,
            EndpointHandle::ExternalOutput { .. } => false,
        }
    }

    #[frb(ignore)]
    fn read_value(&self) -> Option<Value> {
        match &self.endpoint {
            EndpointHandle::Input(InputHandle::Widget(handle)) => {
                match handle {
                    InputWidgetHandle::Event { queue, .. } => {
                        queue.pop()
                    }
                    InputWidgetHandle::Value { queue, .. } => {
                        queue.pop()
                    }
                    InputWidgetHandle::Err(e) => None
                }
            }
            _ => None
        }
    }

    #[frb(sync)]
    pub fn read_float(&self) -> Option<f64> {
        match self.read_value() {
            Some(value) => {
                match value {
                    Value::Float32(v) => Some(v as f64),
                    Value::Float64(v) => Some(v),
                    _ => None
                }
            }
            None => None
        }
    }

    #[frb(sync)]
    pub fn read_int(&self) -> Option<i64> {
        match self.read_value() {
            Some(value) => {
                match value {
                    Value::Int32(v) => Some(v as i64),
                    Value::Int64(v) => Some(v),
                    _ => None
                }
            }
            None => None
        }
    }

    #[frb(sync)]
    pub fn read_bool(&self) -> Option<bool> {
        if let Some(value) = self.read_value() {
            match value {
                Value::Bool(v) => Some(v),
                _ => None
            }
        } else {
            None
        }
    }

    #[frb(ignore)]
    fn write_value(&self, value: Value) -> Result<(), &'static str> {
        match &self.endpoint {
            EndpointHandle::Input(InputHandle::Widget(handle)) => {
                match handle {
                    InputWidgetHandle::Event { queue, .. } => {
                        queue.force_push(value);
                    }
                    InputWidgetHandle::Value { queue, .. } => {
                        queue.force_push(value);
                    }
                    _ => return Err("endpoint is not a widget handle")
                }
            }
            _ => return Err("endpoint is not a widget input")
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
        match &self.endpoint {
            EndpointHandle::Input(handle) => match handle {
                InputHandle::Stream(stream) => EndpointKind::Stream(
                    match stream {
                        InputStreamHandle::MonoFloat32(_) => StreamType::Float32,
                        InputStreamHandle::StereoFloat32(_) => StreamType::Float32,
                        InputStreamHandle::Err(_) => StreamType::Void,
                    }
                ),
                InputHandle::Value(value) => EndpointKind::Value(
                    match value {
                        InputValueHandle::Float32(_) => ValueType::Float32,
                        InputValueHandle::Float64(_) => ValueType::Float64,
                        InputValueHandle::Int32(_) => ValueType::Int32,
                        InputValueHandle::Int64(_) => ValueType::Int64,
                        InputValueHandle::Bool(_) => ValueType::Bool,
                        InputValueHandle::Err(e) => ValueType::Void,
                    }
                ),
                InputHandle::Event(e) => EndpointKind::Event(
                    EventType::Void
                ),
                InputHandle::Widget(e) => EndpointKind::Event(
                    EventType::Void
                ),
            },
            EndpointHandle::Output(handle) => match handle {
                OutputHandle::Stream(stream) => EndpointKind::Stream(
                    match stream {
                        OutputStreamHandle::MonoFloat32(_) => StreamType::Float32,
                        OutputStreamHandle::StereoFloat32(_) => StreamType::Float32,
                        OutputStreamHandle::Err(e) => StreamType::Void,
                    }
                ),
                OutputHandle::Value(value) => EndpointKind::Value(
                    match value {
                        OutputValueHandle::Float32(_) => ValueType::Float32,
                        OutputValueHandle::Float64(_) => ValueType::Float64,
                        OutputValueHandle::Int32(_) => ValueType::Int32,
                        OutputValueHandle::Int64(_) => ValueType::Int64,
                        OutputValueHandle::Bool(_) => ValueType::Bool,
                        OutputValueHandle::Err(e) => ValueType::Void,
                    }
                ),
                OutputHandle::Event(e) => EndpointKind::Event(
                    EventType::Void
                ),
                OutputHandle::Widget(_) => EndpointKind::Value(
                    ValueType::Float32
                ),
            },
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
    Void
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