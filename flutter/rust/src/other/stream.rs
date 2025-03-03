use std::collections::HashMap;
use std::iter::Sum;
use std::ops::Add;
use std::ops::Mul;
use std::sync::Arc;
use std::sync::Mutex;

use crate::api::endpoint::NodeEndpoint;
use crate::api::node::*;

use cmajor::value::Value;
use cmajor::*;

use crossbeam::atomic::AtomicCell;
use num_traits::Float;
use num_traits::FromPrimitive;
use performer::endpoints::stream::StreamType;
use performer::Endpoint;
use performer::InputEvent;
use performer::InputStream;
use performer::InputValue;
use performer::OutputEvent;
use performer::OutputStream;
use performer::OutputValue;

use cmajor::performer::endpoints::value::{GetOutputValue, SetInputValue};

use crate::api::graph::*;
use crate::other::handle::*;
use crate::other::voices::*;

use super::action::*;

pub struct CopyStream<T: StreamType> {
    pub src_voices: Arc<Mutex<Voices>>,
    pub src_handle: Endpoint<OutputStream<T>>,
    pub dst_voices: Arc<Mutex<Voices>>,
    pub dst_handle: Endpoint<InputStream<T>>,
    pub buffer: Vec<T>,
    pub feedback: Arc<AtomicCell<f32>>,
}

/*fn rms<T: Mul<Output = T> + Sum>(buffer: &[T]) -> T
where
    T: StreamType,
{
    buffer.iter().map(|x| *x * *x).sum::<T>() / T::from_usize(buffer.len())
}*/

fn rms<T>(values: &[T]) -> T
where
    T: Float + FromPrimitive + Sum,
{
    if values.is_empty() {
        return T::zero();
    }

    let sum_of_squares: T = values.iter().map(|&x| x * x).sum();
    let mean_square = sum_of_squares / T::from_usize(values.len()).unwrap();
    mean_square.sqrt()
}

impl<T: StreamType> ExecuteAction for CopyStream<T> {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let num_frames = get_num_frames(audio);
        let src = self.src_voices.try_lock().unwrap();
        let mut dst = self.dst_voices.try_lock().unwrap();

        src.copy_streams_to(
            self.src_handle,
            &mut dst,
            self.dst_handle,
            &mut self.buffer[..num_frames],
        );

        // let rms = rms(&self.buffer[..num_frames]);
        // self.feedback.store(Value::Float32(rms.to_f32().unwrap()));
    }
}

pub struct ConvertCopyStream<A: StreamType, B: StreamType> {
    pub src_voices: Arc<Mutex<Voices>>,
    pub src_handle: Endpoint<OutputStream<A>>,
    pub src_buffer: Vec<A>,
    pub dst_voices: Arc<Mutex<Voices>>,
    pub dst_handle: Endpoint<InputStream<B>>,
    pub dst_buffer: Vec<B>,
}

impl<B: StreamType, A: StreamType + ConvertTo<B>> ExecuteAction for ConvertCopyStream<A, B> {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let num_frames = get_num_frames(audio);
        let src = self.src_voices.try_lock().unwrap();
        let mut dst = self.dst_voices.try_lock().unwrap();

        src.convert_copy_streams_to(
            self.src_handle,
            &mut self.src_buffer[..num_frames],
            &mut dst,
            self.dst_handle,
            &mut self.dst_buffer[..num_frames],
        );
    }
}

pub struct ClearStream<T: StreamType + Default> {
    pub voices: Arc<Mutex<Voices>>,
    pub handle: Endpoint<InputStream<T>>,
    pub buffer: Vec<T>,
}

impl<T: StreamType + Default> ExecuteAction for ClearStream<T> {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let num_frames = get_num_frames(audio);
        self.voices
            .try_lock()
            .unwrap()
            .write(self.handle, &self.buffer.as_slice()[..num_frames]);
    }
}

pub struct ExternalOutputStream<T: StreamType> {
    pub voices: Arc<Mutex<Voices>>,
    pub handle: Endpoint<OutputStream<T>>,
    pub buffer: Vec<T>,
    pub channel: usize,
}

impl ExecuteAction for ExternalOutputStream<f32> {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let num_frames = get_num_frames(audio);
        if let Some(channel) = audio.get_mut(self.channel) {
            self.voices
                .try_lock()
                .unwrap()
                .read(self.handle, &mut channel[num_frames..]);
        }
    }
}

impl ExecuteAction for ExternalOutputStream<[f32; 2]> {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let num_frames = get_num_frames(audio);

        self
            .voices
            .try_lock()
            .unwrap()
            .read(self.handle, &mut self.buffer[..num_frames]);

        // Copy the left channel
        if let Some(left) = audio.get_mut(self.channel * 2) {
            for (l, b) in left.iter_mut().zip(self.buffer.iter()) {
                *l = b[0];
            }
        }

        // Copy the right channel
        if let Some(right) = audio.get_mut(self.channel * 2 + 1) {
            for (r, b) in right.iter_mut().zip(self.buffer.iter()) {
                *r = b[1];
            }
        }
    }
}