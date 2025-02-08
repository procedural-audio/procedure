use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;

use crate::api::endpoint::NodeEndpoint;
use crate::api::node::*;

use cmajor::*;

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

use crate::api::graph::*;
use crate::other::handle::*;
use crate::other::voices::*;

use super::action::ExecuteAction;

pub struct CopyEvent {
    pub src_voices: Arc<Mutex<Voices>>,
    pub src_handle: Endpoint<OutputEvent>,
    pub dst_voices: Arc<Mutex<Voices>>,
    pub dst_handle: Endpoint<InputEvent>,
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

pub struct SendEvent {
    pub voices: Arc<Mutex<Voices>>,
    pub handle: Endpoint<OutputEvent>,
    pub queue: Arc<ArrayQueue<Value>>
}

impl ExecuteAction for SendEvent {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let mut voices = self.voices
            .try_lock()
            .unwrap();

        // let v = voices.get(self.handle);
        // self.queue.force_push(v);
    }
}