use std::{f32::consts::E, sync::{Arc, Mutex}};

use cmajor::{endpoint::{self, EndpointDirection, EndpointInfo}, engine::{Engine, Loaded}, performer::{Endpoint, EndpointType, InputEvent, InputStream, InputValue, OutputEvent, OutputStream, OutputValue}, value::types::{Array, Primitive, Type}};
use cmajor::value::Value;
use crossbeam::channel::*;
use crossbeam_queue::ArrayQueue;

use flutter_rust_bridge::*;

#[derive(Copy, Clone)]
pub enum InputStreamHandle {
    Float32(Endpoint<InputStream<f32>>),
    Float64(Endpoint<InputStream<f64>>),
    Int32(Endpoint<InputStream<i32>>),
    Int64(Endpoint<InputStream<i64>>),
    Input {
        endpoint: Endpoint<InputStream<f32>>,
        channel: usize
    },
}

#[derive(Copy, Clone)]
pub enum OutputStreamHandle {
    Float32(Endpoint<OutputStream<f32>>),
    Float64(Endpoint<OutputStream<f64>>),
    Int32(Endpoint<OutputStream<i32>>),
    Int64(Endpoint<OutputStream<i64>>),
    Output {
        endpoint: Endpoint<OutputStream<f32>>,
        channel: usize
    },
}

#[derive(Copy, Clone)]
pub enum InputValueHandle {
    Float32(Endpoint<InputValue<f32>>),
    Float64(Endpoint<InputValue<f64>>),
    Int32(Endpoint<InputValue<i32>>),
    Int64(Endpoint<InputValue<i64>>),
    Bool(Endpoint<InputValue<bool>>),
}

#[derive(Copy, Clone)]
pub enum OutputValueHandle {
    Float32(Endpoint<OutputValue<f32>>),
    Float64(Endpoint<OutputValue<f64>>),
    Int32(Endpoint<OutputValue<i32>>),
    Int64(Endpoint<OutputValue<i64>>),
    Bool(Endpoint<OutputValue<bool>>),
}

#[derive(Copy, Clone)]
pub enum InputHandle {
    Stream(InputStreamHandle),
    Value(InputValueHandle),
    Event(Endpoint<InputEvent>),
}

#[derive(Copy, Clone)]
pub enum OutputHandle {
    Stream(OutputStreamHandle),
    Value(OutputValueHandle),
    Event(Endpoint<OutputEvent>),
}

#[derive(Clone)]
pub enum EndpointHandle {
    Input(InputHandle),
    Output(OutputHandle),
    Widget {
        handle: Endpoint<InputEvent>,
        queue: Arc<ArrayQueue<Value>>,
    },
}

#[derive(Clone)]
#[frb(opaque)]
pub struct NodeEndpoint {
    pub endpoint: EndpointHandle,
    pub annotation: String,
}

impl NodeEndpoint {
    #[frb(ignore)]
    pub fn from(engine: &mut Engine<Loaded>, info: EndpointInfo) -> Result<Self, &'static str> {
        let id = info.id();
        let annotation = info.annotation();

        let endpoint = match &info {
            EndpointInfo::Stream(endpoint) => {
                match endpoint.direction() {
                    EndpointDirection::Input => EndpointHandle::Input(
                        match endpoint.ty() {
                            Type::Primitive(primitive) => match primitive {
                                Primitive::Float32 => {
                                    if let Some(channel) = annotation.get("inputChannel") {
                                        InputHandle::Stream(
                                            InputStreamHandle::Input {
                                                endpoint: engine
                                                    .endpoint(id)
                                                    .unwrap(),
                                                channel: channel
                                                    .as_u64()
                                                    .unwrap() as usize
                                            }
                                        )
                                    } else {
                                        InputHandle::Stream(
                                            InputStreamHandle::Float32(
                                                engine.endpoint(id).unwrap()
                                            )
                                        )
                                    }
                                },
                                Primitive::Float64 => InputHandle::Stream(
                                    InputStreamHandle::Float64(
                                        engine.endpoint(id).unwrap()
                                    )
                                ),
                                Primitive::Int32 => InputHandle::Stream(
                                    InputStreamHandle::Int32(
                                        engine.endpoint(id).unwrap()
                                    )
                                ),
                                Primitive::Int64 => InputHandle::Stream(
                                    InputStreamHandle::Int64(
                                        engine.endpoint(id).unwrap()
                                    )
                                ),
                                _ => return Err("unsupported input stream type"),
                            },
                            _ => return Err("unsupported input stream type"),
                        }
                    ),
                    EndpointDirection::Output => EndpointHandle::Output(
                        match endpoint.ty() {
                            Type::Primitive(primitive) => match primitive {
                                Primitive::Float32 => {
                                    if let Some(channel) = annotation.get("outputChannel") {
                                        OutputHandle::Stream(
                                            OutputStreamHandle::Output {
                                                endpoint: engine
                                                    .endpoint(id)
                                                    .unwrap(),
                                                channel: channel
                                                    .as_u64()
                                                    .unwrap() as usize
                                            }
                                        )
                                    } else {
                                        OutputHandle::Stream(
                                            OutputStreamHandle::Float32(
                                                engine.endpoint(id).unwrap()
                                            )
                                        )
                                    }
                                },
                                Primitive::Float64 => OutputHandle::Stream(
                                    OutputStreamHandle::Float64(
                                        engine.endpoint(id).unwrap()
                                    )
                                ),
                                Primitive::Int32 => OutputHandle::Stream(
                                    OutputStreamHandle::Int32(
                                        engine.endpoint(id).unwrap()
                                    )
                                ),
                                Primitive::Int64 => OutputHandle::Stream(
                                    OutputStreamHandle::Int64(
                                        engine.endpoint(id).unwrap()
                                    )
                                ),
                                _ => return Err("unsupported output stream type"),
                            },
                            _ => return Err("unsupported output stream type"),
                        }
                    ),
                }
            },
            EndpointInfo::Event(endpoint) => {
                match endpoint.direction() {
                    EndpointDirection::Input => {
                        if annotation.contains_key("widget") {
                            println!("Creating queue");
                            let queue = ArrayQueue::new(100);
                            EndpointHandle::Widget {
                                handle: engine.endpoint(id).unwrap(),
                                queue: Arc::new(queue)
                            }
                        } else {
                            EndpointHandle::Input(
                                InputHandle::Event(
                                    engine.endpoint(id).unwrap()
                                )
                            )
                        }
                    },
                    EndpointDirection::Output => EndpointHandle::Output(
                        OutputHandle::Event(
                            engine.endpoint(id).unwrap()
                        )
                    )
                }
            },
            EndpointInfo::Value(endpoint) => {
                match endpoint.direction() {
                    EndpointDirection::Input => EndpointHandle::Input(
                        match endpoint.ty() {
                            Type::Primitive(primitive) => match primitive {
                                Primitive::Float32 => InputHandle::Value(
                                    InputValueHandle::Float32(engine.endpoint(id).unwrap())
                                ),
                                Primitive::Float64 => InputHandle::Value(
                                    InputValueHandle::Float64(engine.endpoint(id).unwrap())
                                ),
                                Primitive::Int32 => InputHandle::Value(
                                    InputValueHandle::Int32(engine.endpoint(id).unwrap())
                                ),
                                Primitive::Int64 => InputHandle::Value(
                                    InputValueHandle::Int64(engine.endpoint(id).unwrap())
                                ),
                                Primitive::Void => return Err("unsupported endpoint type void stream"),
                                Primitive::Bool => return Err("unsupported endpoint type bool stream"),
                            },
                            Type::String => return Err("unsupported endpoint type string stream"),
                            Type::Array(array) => return Err("unsupported endpoint type array stream"),
                            Type::Object(object) => return Err("unsupported endpoint type object stream"),
                        }
                    ),
                    EndpointDirection::Output => EndpointHandle::Output(
                        match endpoint.ty() {
                            Type::Primitive(primitive) => match primitive {
                                Primitive::Float32 => OutputHandle::Value(
                                    OutputValueHandle::Float32(engine.endpoint(id).unwrap())
                                ),
                                Primitive::Float64 => OutputHandle::Value(
                                    OutputValueHandle::Float64(engine.endpoint(id).unwrap())
                                ),
                                Primitive::Int32 => OutputHandle::Value(
                                    OutputValueHandle::Int32(engine.endpoint(id).unwrap())
                                ),
                                Primitive::Int64 => OutputHandle::Value(
                                    OutputValueHandle::Int64(engine.endpoint(id).unwrap())
                                ),
                                Primitive::Void => return Err("unsupported endpoint type void stream"),
                                Primitive::Bool => return Err("unsupported endpoint type bool stream"),
                            },
                            Type::String => return Err("unsupported endpoint type string stream"),
                            Type::Array(array) => return Err("unsupported endpoint type array stream"),
                            Type::Object(object) => return Err("unsupported endpoint type object stream"),
                        }
                    ),
                }
            },
        };

        let annotation = serde_json::ser::to_string(annotation).unwrap();

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
            EndpointHandle::Widget { .. } => true
        }
    }

    #[frb(ignore)]
    pub fn write_value(&self, value: Value) -> Result<(), &'static str> {
        match &self.endpoint {
            EndpointHandle::Widget { queue, .. } => {
                match queue.force_push(value) {
                    Some(_) => {
                        println!("Replaced the oldest value in the queue");
                        Ok(())
                    },
                    None => Ok(())
                }
            }
            _ => Err("endpoint is not a widget")
        }
    }

    #[frb(sync)]
    pub fn write_float(&self, v: f64) -> Result<(), String> {
        self
            .write_value(Value::Float64(v))
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
                        InputStreamHandle::Float32(_) => StreamType::Float32,
                        InputStreamHandle::Float64(_) => StreamType::Float64,
                        InputStreamHandle::Int32(_) => StreamType::Int32,
                        InputStreamHandle::Int64(_) => StreamType::Int64,
                        InputStreamHandle::Input { .. } => StreamType::Float32,
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
                        OutputStreamHandle::Float32(_) => StreamType::Float32,
                        OutputStreamHandle::Float64(_) => StreamType::Float64,
                        OutputStreamHandle::Int32(_) => StreamType::Int32,
                        OutputStreamHandle::Int64(_) => StreamType::Int64,
                        OutputStreamHandle::Output { .. } => StreamType::Float32
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
            EndpointHandle::Widget { .. } => EndpointKind::Event(EventType::Void)
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
