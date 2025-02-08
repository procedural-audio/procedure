use std::sync::Arc;
use std::sync::Mutex;

use cmajor::*;

use crossbeam_queue::ArrayQueue;
use performer::Endpoint;
use performer::InputValue;
use performer::OutputValue;

use cmajor::performer::endpoints::value::{GetOutputValue, SetInputValue};
use value::Value;

use crate::other::voices::*;

use super::action::ExecuteAction;

pub struct CopyValue<T> {
    pub src_voices: Arc<Mutex<Voices>>,
    pub src_handle: Endpoint<OutputValue<T>>,
    pub dst_voices: Arc<Mutex<Voices>>,
    pub dst_handle: Endpoint<InputValue<T>>,
}

impl<T> ExecuteAction for CopyValue<T>
where
    T: Copy + SetInputValue + for<'a> GetOutputValue<Output<'a> = T>,
{
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let mut src = self.src_voices
            .try_lock()
            .unwrap();
        let mut dst = self.dst_voices
            .try_lock()
            .unwrap();

        src.copy_values_to(self.src_handle, &mut dst, self.dst_handle);
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

pub struct CopyConvertValue<A, B> {
    pub src_voices: Arc<Mutex<Voices>>,
    pub src_handle: Endpoint<OutputValue<A>>,
    pub dst_voices: Arc<Mutex<Voices>>,
    pub dst_handle: Endpoint<InputValue<B>>,
}

impl<A, B> ExecuteAction for CopyConvertValue<A, B>
where
    B: Copy + SetInputValue, A: Copy + for<'a> GetOutputValue<Output<'a> = A> + ConvertTo<B>,
{
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let mut src = self.src_voices
            .try_lock()
            .unwrap();
        let mut dst = self.dst_voices
            .try_lock()
            .unwrap();

        // let a = src.get(self.src_handle);
        // let b = a.convert_to();
        // dst.set(self.dst_handle, b);
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
    pub queue: Arc<ArrayQueue<T>>
}

impl<T: Copy + SetInputValue> ExecuteAction for ReceiveValue<T> {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let mut voices = self.voices
            .try_lock()
            .unwrap();

        while let Some(value) = self.queue.pop() {
            voices.set(self.handle, value);
        }
    }
}