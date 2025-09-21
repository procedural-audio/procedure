use std::sync::Arc;

use cmajor::value::Value;
use cmajor::{
    endpoint::EndpointInfo,
    engine::{Engine, Loaded},
    performer::OutputStream,
};

use flutter_rust_bridge::*;

use crate::other::handle::*;

#[derive(Clone)]
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
        if let EndpointHandle::Output(handle) = &self.endpoint {
            if let OutputEndpoint::Widget { queue, .. } = handle {
                return queue.pop();
            }
        }

        None
    }

    #[frb(sync)]
    pub fn read_float(&self) -> Option<f64> {
        match self.read_value() {
            Some(value) => match value {
                Value::Float32(v) => Some(v as f64),
                Value::Float64(v) => Some(v),
                _ => None,
            },
            None => None,
        }
    }

    #[frb(sync)]
    pub fn read_int(&self) -> Option<i64> {
        match self.read_value() {
            Some(value) => match value {
                Value::Int32(v) => Some(v as i64),
                Value::Int64(v) => Some(v),
                _ => None,
            },
            None => None,
        }
    }

    #[frb(sync)]
    pub fn read_bool(&self) -> Option<bool> {
        if let Some(value) = self.read_value() {
            match value {
                Value::Bool(v) => Some(v),
                _ => None,
            }
        } else {
            None
        }
    }

    #[frb(ignore)]
    fn write_value(&self, value: Value) -> Result<(), &'static str> {
        if let EndpointHandle::Input(handle) = &self.endpoint {
            if let InputEndpoint::Widget { queue, .. } = handle {
                queue.force_push(value);
            }
        }

        Ok(())
    }

    #[frb(sync)]
    pub fn write_float(&self, v: f64) -> Result<(), String> {
        self.write_value(Value::Float32(v as f32))
            .map_err(|e| e.to_string())
    }

    #[frb(sync)]
    pub fn write_int(&self, v: i64) -> Result<(), String> {
        self.write_value(Value::Int32(v as i32)).map_err(|e| e.to_string())
    }

    #[frb(sync)]
    pub fn write_bool(&self, b: bool) -> Result<(), String> {
        self.write_value(Value::Bool(b)).map_err(|e| e.to_string())
    }

    #[frb(sync)]
    pub fn feedback_value(&self) -> bool {
        // If it's an output
        if let EndpointHandle::Output(handle) = &self.endpoint {
            // If it's an endpoint
            if let OutputEndpoint::Endpoint(handle) = handle {
                // If it's a value
                if let OutputHandle::Value {feedback, .. } = handle {
                    return feedback.load();
                }
            }
        }

        false
    }

    #[frb(sync, getter)]
    pub fn is_input(&self) -> bool {
        self.endpoint.is_input()
    }

    #[frb(sync, getter)]
    pub fn is_external(&self) -> bool {
        self.endpoint.is_external()
    }

    #[frb(sync, getter)]
    pub fn get_kind(&self) -> EndpointKind {
        self.endpoint.get_kind()
    }

    #[frb(sync, getter)]
    pub fn get_type(&self) -> String {
        self.endpoint.get_type().to_string()
    }
}

#[derive(Copy, Clone)]
pub enum EndpointKind {
    Stream,
    Value,
    Event,
}
