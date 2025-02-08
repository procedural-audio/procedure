use std::collections::HashMap;
use std::sync::Arc;
use std::sync::Mutex;

use crate::api::endpoint::NodeEndpoint;
use crate::api::node::*;

use cmajor::*;

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

/*
// Input stream
        Action::InputStreamMonoFloat32 { voices, handle, channel } => {
            if let Some(channel) = audio.get(*channel) {
                voices
                    .try_lock()
                    .unwrap()
                    .write(*handle, channel);
            }
        }
        Action::OutputStreamMonoFloat32 { voices, handle, channel } => {
            if let Some(channel) = audio.get_mut(*channel) {
                voices
                    .try_lock()
                    .unwrap()
                    .read(*handle, channel);
            }
        }
        Action::InputStreamStereoFloat32 { voices, handle, channel, buffer } => {
            // Copy the left channel
            if let Some(left) = audio.get(*channel * 2) {
                for (b, l) in buffer.iter_mut().zip(left.iter()) {
                    b[0] = *l;
                }
            }

            // Copy the right channel
            if let Some(right) = audio.get(*channel * 2 + 1) {
                for (b, r) in buffer.iter_mut().zip(right.iter()) {
                    b[0] = *r;
                }
            }

            // Write the samples
            voices
                .try_lock()
                .unwrap()
                .write(*handle, buffer);
        }
        Action::OutputStreamStereoFloat32 { voices, handle, channel, buffer} => {
            // Read the samples
            voices
                .try_lock()
                .unwrap()
                .read(*handle, buffer);

            // Copy the left channel
            if let Some(left) = audio.get_mut(*channel * 2) {
                for (l, b) in left.iter_mut().zip(buffer.iter()) {
                    *l = b[0];
                }
            }

            // Copy the right channel
            if let Some(right) = audio.get_mut(*channel * 2 + 1) {
                for (r, b) in right.iter_mut().zip(buffer.iter()) {
                    *r = b[1];
                }
            }
        }

*/

pub struct ExternalInputStream<T: StreamType> {
    pub voices: Arc<Mutex<Voices>>,
    pub handle: Endpoint<OutputStream<T>>,
    pub buffer: Vec<T>,
    pub channel: usize,
}

impl ExecuteAction for ExternalInputStream<f32> {
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

/*impl ExecuteAction for ExternalInputStream<[f32; 2]> {
    fn execute(&mut self, audio: &mut [&mut [f32]], midi: &mut [u8]) {
        let num_frames = get_num_frames(audio);
        if let Some(channel) = audio.get_mut(self.channel) {
            self
                .voices
                .try_lock()
                .unwrap()
                .read(self.handle, &mut channel[num_frames..]);
        }
    }
}*/
