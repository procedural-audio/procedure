use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;

use crate::api::endpoint::NodeEndpoint;
use crate::api::node::*;

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

pub struct CopyEvent {
    pub src_voices: Arc<Mutex<Voices>>,
    pub src_handle: Endpoint<OutputEvent>,
    pub dst_voices: Arc<Mutex<Voices>>,
    pub dst_handle: Endpoint<InputEvent>,
    pub feedback: Arc<AtomicCell<Value>>,
}

impl ExecuteAction for CopyEvent {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let mut src = self.src_voices
            .try_lock()
            .unwrap();
        let mut dst = self.dst_voices
            .try_lock()
            .unwrap();

        src.copy_events_to(self.src_handle, &mut dst, self.dst_handle);
    }
}

pub struct CopyConvertEvent {}

pub struct CopyPrimitiveEventToValue<T> {
    pub src_voices: Arc<Mutex<Voices>>,
    pub src_handle: Endpoint<OutputEvent>,
    pub dst_voices: Arc<Mutex<Voices>>,
    pub dst_handle: Endpoint<InputValue<T>>,
}

impl<T> ExecuteAction for CopyPrimitiveEventToValue<T>
    where
        T: Copy + SetInputValue + for<'a> TryFrom<ValueRef<'a>> {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
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
}

pub struct SendEvents {
    pub voices: Arc<Mutex<Voices>>,
    pub handle: Endpoint<OutputEvent>,
    pub queue: Arc<ArrayQueue<Value>>
}

impl ExecuteAction for SendEvents {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let mut voices = self.voices
            .try_lock()
            .unwrap();

        // let v = voices.get(self.handle);
        // self.queue.force_push(v);
    }
}

pub struct ReceiveEvents {
    pub voices: Arc<Mutex<Voices>>,
    pub handle: Endpoint<InputEvent>,
    pub queue: Arc<ArrayQueue<Value>>
}

impl ExecuteAction for ReceiveEvents {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let mut voices = self.voices
            .try_lock()
            .unwrap();

        while let Some(event) = self.queue.pop() {
            let _ = voices.post(self.handle, &event);
        }
    }
}

pub struct EventFeedback {
    pub voices: Arc<Mutex<Voices>>,
    pub handle: Endpoint<InputEvent>,
    pub queue: AtomicCell<u32>
}

impl ExecuteAction for EventFeedback {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let mut voices = self.voices
            .try_lock()
            .unwrap();

    }
}