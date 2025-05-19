use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;

use crate::api::endpoint::NodeEndpoint;
use crate::api::node::*;

use cmajor::performer::Performer;
use cmajor::value::ObjectValueRef;
use cmajor::*;

use crossbeam::atomic::AtomicCell;
use crossbeam_queue::ArrayQueue;
use performer::endpoints::stream::StreamType;
use performer::Endpoint;
use performer::InputEvent;
use performer::InputStream;
use performer::InputValue;
use performer::OutputEvent;
use performer::OutputStream;
use performer::OutputValue;

use cmajor::performer::endpoints::value::{GetOutputValue, SetInputValue};
use value::Value;
use value::ValueRef;

use crate::api::graph::*;
use crate::other::handle::*;
use crate::other::voices::*;

use super::action::ExecuteAction;
use super::action::IO;

pub struct CopyEvent {
    pub src_voices: Arc<Mutex<Performer>>,
    pub src_handle: Endpoint<OutputEvent>,
    pub dst_voices: Arc<Mutex<Performer>>,
    pub dst_handle: Endpoint<InputEvent>,
    pub feedback: Arc<AtomicCell<usize>>,
}

impl ExecuteAction for CopyEvent {
    fn execute(&mut self, io: &mut IO) {
        let mut src = self.src_voices
            .try_lock()
            .unwrap();
        let mut dst = self.dst_voices
            .try_lock()
            .unwrap();

        src
            .fetch(self.src_handle, |_, event| {
                dst
                .post(self.dst_handle, event)
                .unwrap_or_else(| e | println!("Error posting event: {}", e));
            })
            .unwrap_or_else(| e | println!("Error fetching event: {}", e));
    }
}

/*pub struct CopyPrimitiveEventToValue<T> {
    pub src_voices: Arc<Mutex<Performer>>,
    pub src_handle: Endpoint<OutputEvent>,
    pub dst_voices: Arc<Mutex<Performer>>,
    pub dst_handle: Endpoint<InputValue<T>>,
}

impl<T> ExecuteAction for CopyPrimitiveEventToValue<T>
    where
        T: Copy + SetInputValue + for<'a> TryFrom<ValueRef<'a>> {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u32]) {
        let mut src = self.src_voices
            .try_lock()
            .unwrap();
        let mut dst = self.dst_voices
            .try_lock()
            .unwrap();

        src.fetch(self.src_handle, | _, v | {
            if let Ok(v) = v.try_into() {
                dst.set(self.dst_handle, v);
            }
        }).unwrap();
    }
}*/

pub struct SendEvents {
    pub voices: Arc<Mutex<Performer>>,
    pub handle: Endpoint<OutputEvent>,
    pub queue: Arc<ArrayQueue<Value>>
}

impl ExecuteAction for SendEvents {
    fn execute(&mut self, _io: &mut IO) {
        let mut voices = self.voices
            .try_lock()
            .unwrap();
        
        let _ = voices.fetch(self.handle, | _, event| {
            match event {
                // ValueRef::Void => todo!(),
                ValueRef::Bool(b) => {
                    self.queue.force_push(Value::Bool(b));
                },
                ValueRef::Int32(i) => {
                    self.queue.force_push(Value::Int32(i));
                },
                ValueRef::Int64(i) => {
                    self.queue.force_push(Value::Int64(i));
                },
                ValueRef::Float32(f) => {
                    self.queue.force_push(Value::Float32(f));
                },
                ValueRef::Float64(f) => {
                    self.queue.force_push(Value::Float64(f));
                },
                // ValueRef::String(string_handle) => todo!(),
                // ValueRef::Array(array_value_ref) => todo!(),
                // ValueRef::Object(object_value_ref) => todo!(),
                _ => println!("Unsupported sending event: {:?}", event),
            };
        });
    }
}

pub struct ReceiveEvents {
    pub voices: Arc<Mutex<Performer>>,
    pub handle: Endpoint<InputEvent>,
    pub queue: Arc<ArrayQueue<Value>>
}

impl ExecuteAction for ReceiveEvents {
    fn execute(&mut self, io: &mut IO) {
        let mut voices = self.voices
            .try_lock()
            .unwrap();

        while let Some(event) = self.queue.pop() {
            let _ = voices.post(self.handle, &event);
        }
    }
}

pub struct EventFeedback {
    pub voices: Arc<Mutex<Performer>>,
    pub handle: Endpoint<InputEvent>,
    pub queue: AtomicCell<u32>
}

impl ExecuteAction for EventFeedback {
    fn execute(&mut self, io: &mut IO) {
        let mut voices = self.voices
            .try_lock()
            .unwrap();

    }
}

pub struct ExternalInputEvent {
    pub voices: Arc<Mutex<Performer>>,
    pub handle: Endpoint<InputEvent>,
}

impl ExecuteAction for ExternalInputEvent {
    fn execute(&mut self, io: &mut IO) {
        for msg in io.midi_input.iter() {
            let event = Value::Int32(*msg as i32);
            self
                .voices
                .try_lock()
                .unwrap()
                .post(self.handle, &event)
                .unwrap_or_else(| e | println!("Error posting event: {:?}", e));
        }
    }
}

pub struct ExternalOutputEvent {
    pub voices: Arc<Mutex<Performer>>,
    pub handle: Endpoint<OutputEvent>,
}

impl ExecuteAction for ExternalOutputEvent {
    fn execute(&mut self, io: &mut IO) {
        self
            .voices
            .try_lock()
            .unwrap()
            .fetch(self.handle, | _, v | {
                if let ValueRef::Int32(v) = v {
                    io.midi_output.push(v as u32);
                } else {
                    println!("Error fetching event: {:?}", v);
                }
            }).unwrap_or_else(| e | println!("Error fetching event: {:?}", e));
    }
}