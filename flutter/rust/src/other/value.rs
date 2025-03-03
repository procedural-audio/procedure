use std::sync::Arc;
use std::sync::Mutex;

use cmajor::*;

use crossbeam::atomic::AtomicCell;
use crossbeam_queue::ArrayQueue;
use performer::Endpoint;
use performer::InputValue;
use performer::OutputValue;

use cmajor::performer::endpoints::value::{GetOutputValue, SetInputValue};
use value::Value;
use value::ValueRef;

use crate::other::voices::*;

use super::action::ExecuteAction;

pub struct CopyValue<T: Default> {
    pub src_voices: Arc<Mutex<Voices>>,
    pub src_handle: Endpoint<OutputValue<T>>,
    pub dst_voices: Arc<Mutex<Voices>>,
    pub dst_handle: Endpoint<InputValue<T>>,
    pub previous: T,
    pub feedback: Arc<AtomicCell<bool>>,
}

impl<T> ExecuteAction for CopyValue<T>
where
    T: Copy + Default + PartialEq + SetInputValue + for<'a> GetOutputValue<Output<'a> = T>,
{
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let mut src = self.src_voices
            .try_lock()
            .unwrap();
        let mut dst = self.dst_voices
            .try_lock()
            .unwrap();
        
        match *src {
            Voices::Mono(ref mut src_voice) => {
                let value = src_voice.get(self.src_handle);

                if self.previous != value {
                    self.feedback.store(true);
                } else {
                    self.feedback.store(false);
                }

                self.previous = value;

                match *dst {
                    Voices::Mono(ref mut dst_voice) => {
                        dst_voice.set(self.dst_handle, value);
                    }
                    Voices::Poly(ref mut dst_voices) => {
                        /*for dst_voice in dst_voices.iter_mut() {
                            dst_voice.set(self.dst_handle, value);
                        }*/
                    }
                }
            }
            Voices::Poly(ref mut src_voices) => {
                match *dst {
                    Voices::Mono(ref mut dst_voice) => {
                        // let value = src_voices[0].get(self.src_handle);
                        // dst_voice.set(self.dst_handle, value);
                    }
                    Voices::Poly(ref mut dst_voices) => {
                        for (src_voice, dst_voice) in src_voices.iter_mut().zip(dst_voices.iter_mut()) {
                            let value = src_voice.get(self.src_handle);
                            dst_voice.set(self.dst_handle, value);
                        }
                    }
                }
            }
        }
        // src.copy_values_to(self.src_handle, &mut dst, self.dst_handle);
    }
}

pub struct ClearValue<T> {
    pub voices: Arc<Mutex<Voices>>,
    pub handle: Endpoint<InputValue<T>>,
}

impl<T: Copy + Default + SetInputValue> ExecuteAction for ClearValue<T> {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        self.voices
            .try_lock()
            .unwrap()
            .set(self.handle, T::default());
    }
}

/*pub struct SendValueTyped<T> {
    pub voices: Arc<Mutex<Voices>>,
    pub handle: Endpoint<OutputValue<T>>,
    pub queue: Arc<ArrayQueue<T>>
}

impl<T: Copy + for<'a> GetOutputValue<Output<'a> = T>> ExecuteAction for SendValueTyped<T> {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let mut voices = self.voices
            .try_lock()
            .unwrap();

        // voices.copy_values_to(self.handle, dst_voices, dst_endpoint);
        // let v = voices.get(self.handle);
        // self.queue.force_push(v);
    }
}*/

pub struct SendValue {
    pub voices: Arc<Mutex<Voices>>,
    pub handle: Endpoint<OutputValue<Value>>,
    pub queue: Arc<ArrayQueue<Value>>
}

impl ExecuteAction for SendValue {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let mut voices = self.voices
            .try_lock()
            .unwrap();

        // let v = voices.get(self.handle);
        // self.queue.force_push(v);
    }
}

pub struct ReceiveValue<T> {
    pub voices: Arc<Mutex<Voices>>,
    pub handle: Endpoint<InputValue<T>>,
    pub queue: Arc<ArrayQueue<Value>>
}

impl<T> ExecuteAction for ReceiveValue<T>
    where
        T: Copy + SetInputValue + for <'a> TryFrom<ValueRef<'a>> {

    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let mut voices = self.voices
            .try_lock()
            .unwrap();

        while let Some(value) = self.queue.pop() {
            if let Ok(v) = value.as_ref().try_into() {
                voices.set(self.handle, v);
            }
        }
    }
}