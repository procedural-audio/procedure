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

    #[frb(sync)]
    pub fn is_input(&self) -> bool {
        self.endpoint.is_input()
    }

    #[frb(sync)]
    pub fn is_external(&self) -> bool {
        self.endpoint.is_external()
    }

    #[frb(sync, getter)]
    pub fn get_kind(&self) -> EndpointKind {
        self.endpoint.get_kind()
    }

    #[frb(sync, getter)]
    pub fn get_type(&self) -> EndpointType {
        self.endpoint.get_type()
    }
}

#[derive(Clone)]
pub enum EndpointType {
    Float,
    Int,
    Bool,
    Void,
    Object(String),
    Unsupported
}

#[derive(Copy, Clone)]
pub enum EndpointKind {
    Stream,
    Value,
    Event
}