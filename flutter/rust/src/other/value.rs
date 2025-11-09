use std::sync::Arc;
use std::sync::Mutex;

use cmajor::performer::Performer;
use cmajor::*;

use crossbeam::atomic::AtomicCell;
use crossbeam_queue::ArrayQueue;
use performer::Endpoint;
use performer::InputValue;
use performer::OutputValue;
use value::Value;
use value::ValueRef;

use super::action::ExecuteAction;
use super::action::IO;

pub trait ValueSample:
    Copy + Default + PartialEq + Send + Sync + 'static
{
    fn read_output(performer: &mut Performer, endpoint: Endpoint<OutputValue<Self>>) -> Self;
    fn write_input(performer: &mut Performer, endpoint: Endpoint<InputValue<Self>>, value: Self);
}

macro_rules! impl_value_sample {
    ($ty:ty) => {
        impl ValueSample for $ty {
            fn read_output(
                performer: &mut Performer,
                endpoint: Endpoint<OutputValue<Self>>,
            ) -> Self {
                performer.get(endpoint)
            }

            fn write_input(
                performer: &mut Performer,
                endpoint: Endpoint<InputValue<Self>>,
                value: Self,
            ) {
                performer.set(endpoint, value);
            }
        }
    };
}

impl_value_sample!(f32);
impl_value_sample!(f64);
impl_value_sample!(i32);
impl_value_sample!(i64);
impl_value_sample!(bool);

pub struct CopyValue<T: ValueSample> {
    pub src_voices: Arc<Mutex<Performer>>,
    pub src_handle: Endpoint<OutputValue<T>>,
    pub dst_voices: Arc<Mutex<Performer>>,
    pub dst_handle: Endpoint<InputValue<T>>,
    pub previous: T,
    pub feedback: Arc<AtomicCell<bool>>,
}

impl<T: ValueSample> ExecuteAction for CopyValue<T> {
    fn execute(&mut self, io: &mut IO) {
        let mut src = self.src_voices
            .try_lock()
            .unwrap();
        let mut dst = self.dst_voices
            .try_lock()
            .unwrap();
        
        let value = T::read_output(&mut src, self.src_handle);

        if self.previous != value {
            self.feedback.store(true);
        } else {
            self.feedback.store(false);
        }
        
        T::write_input(&mut dst, self.dst_handle, value);
        self.previous = value;
    }
}

pub struct ClearValue<T: ValueSample> {
    pub voices: Arc<Mutex<Performer>>,
    pub handle: Endpoint<InputValue<T>>,
}

impl<T: ValueSample> ExecuteAction for ClearValue<T> {
    fn execute(&mut self, io: &mut IO) {
        let mut performer = self.voices.try_lock().unwrap();
        T::write_input(&mut performer, self.handle, T::default());
    }
}

/*pub struct SendValueTyped<T> {
    pub voices: Arc<Mutex<Performer>>,
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
    pub voices: Arc<Mutex<Performer>>,
    pub handle: Endpoint<OutputValue<Value>>,
    pub queue: Arc<ArrayQueue<Value>>
}

impl ExecuteAction for SendValue {
    fn execute(&mut self, io: &mut IO) {
        let mut voices = self.voices
            .try_lock()
            .unwrap();

        // let v = voices.get(self.handle);
        // self.queue.force_push(v);
    }
}

pub struct ReceiveValue<T: ValueSample> {
    pub voices: Arc<Mutex<Performer>>,
    pub handle: Endpoint<InputValue<T>>,
    pub queue: Arc<ArrayQueue<Value>>
}

impl<T> ExecuteAction for ReceiveValue<T>
where
    T: ValueSample + for<'a> TryFrom<ValueRef<'a>>,
{
    fn execute(&mut self, io: &mut IO) {
        let mut voices = self.voices
            .try_lock()
            .unwrap();

        while let Some(value) = self.queue.pop() {
            if let Ok(v) = value.as_ref().try_into() {
                T::write_input(&mut voices, self.handle, v);
            }
        }
    }
}
