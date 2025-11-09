use std::sync::{Arc, Mutex};

use cmajor::performer::{Endpoint, InputStream, OutputStream, Performer};
use crossbeam::atomic::AtomicCell;

use super::action::{ExecuteAction, IO};

const STREAM_BUFFER_SIZE: usize = 1024;

enum StreamCopyVariant {
    Float32 {
        src: Endpoint<OutputStream<f32>>,
        dst: Endpoint<InputStream<f32>>,
        buffer: Vec<f32>,
    },
    Float64 {
        src: Endpoint<OutputStream<f64>>,
        dst: Endpoint<InputStream<f64>>,
        buffer: Vec<f64>,
    },
    Int32 {
        src: Endpoint<OutputStream<i32>>,
        dst: Endpoint<InputStream<i32>>,
        buffer: Vec<i32>,
    },
    Int64 {
        src: Endpoint<OutputStream<i64>>,
        dst: Endpoint<InputStream<i64>>,
        buffer: Vec<i64>,
    },
    Float32x2 {
        src: Endpoint<OutputStream<[f32; 2]>>,
        dst: Endpoint<InputStream<[f32; 2]>>,
        buffer: Vec<[f32; 2]>,
    },
}

impl StreamCopyVariant {
    fn float32(src: Endpoint<OutputStream<f32>>, dst: Endpoint<InputStream<f32>>) -> Self {
        Self::Float32 {
            src,
            dst,
            buffer: vec![0.0; STREAM_BUFFER_SIZE],
        }
    }

    fn float64(src: Endpoint<OutputStream<f64>>, dst: Endpoint<InputStream<f64>>) -> Self {
        Self::Float64 {
            src,
            dst,
            buffer: vec![0.0; STREAM_BUFFER_SIZE],
        }
    }

    fn int32(src: Endpoint<OutputStream<i32>>, dst: Endpoint<InputStream<i32>>) -> Self {
        Self::Int32 {
            src,
            dst,
            buffer: vec![0; STREAM_BUFFER_SIZE],
        }
    }

    fn int64(src: Endpoint<OutputStream<i64>>, dst: Endpoint<InputStream<i64>>) -> Self {
        Self::Int64 {
            src,
            dst,
            buffer: vec![0; STREAM_BUFFER_SIZE],
        }
    }

    fn float32x2(
        src: Endpoint<OutputStream<[f32; 2]>>,
        dst: Endpoint<InputStream<[f32; 2]>>,
    ) -> Self {
        Self::Float32x2 {
            src,
            dst,
            buffer: vec![[0.0, 0.0]; STREAM_BUFFER_SIZE],
        }
    }

    fn copy(&mut self, src: &Performer, dst: &Performer, frames: usize) {
        match self {
            StreamCopyVariant::Float32 { src: s, dst: d, buffer } => {
                let frames = frames.min(buffer.len());
                src.read(*s, &mut buffer[..frames]);
                dst.write(*d, &buffer[..frames]);
            }
            StreamCopyVariant::Float64 { src: s, dst: d, buffer } => {
                let frames = frames.min(buffer.len());
                src.read(*s, &mut buffer[..frames]);
                dst.write(*d, &buffer[..frames]);
            }
            StreamCopyVariant::Int32 { src: s, dst: d, buffer } => {
                let frames = frames.min(buffer.len());
                src.read(*s, &mut buffer[..frames]);
                dst.write(*d, &buffer[..frames]);
            }
            StreamCopyVariant::Int64 { src: s, dst: d, buffer } => {
                let frames = frames.min(buffer.len());
                src.read(*s, &mut buffer[..frames]);
                dst.write(*d, &buffer[..frames]);
            }
            StreamCopyVariant::Float32x2 { src: s, dst: d, buffer } => {
                let frames = frames.min(buffer.len());
                src.read(*s, &mut buffer[..frames]);
                dst.write(*d, &buffer[..frames]);
            }
        }
    }
}

pub struct CopyStream {
    pub src_voices: Arc<Mutex<Performer>>,
    pub dst_voices: Arc<Mutex<Performer>>,
    variant: StreamCopyVariant,
    pub feedback: Arc<AtomicCell<f32>>,
}

impl CopyStream {
    pub fn new(
        src_voices: Arc<Mutex<Performer>>,
        dst_voices: Arc<Mutex<Performer>>,
        variant: StreamCopyVariant,
        feedback: Arc<AtomicCell<f32>>,
    ) -> Self {
        Self {
            src_voices,
            dst_voices,
            variant,
            feedback,
        }
    }

    pub fn float32(
        src_voices: Arc<Mutex<Performer>>,
        src: Endpoint<OutputStream<f32>>,
        dst_voices: Arc<Mutex<Performer>>,
        dst: Endpoint<InputStream<f32>>,
        feedback: Arc<AtomicCell<f32>>,
    ) -> Self {
        Self::new(src_voices, dst_voices, StreamCopyVariant::float32(src, dst), feedback)
    }

    pub fn float64(
        src_voices: Arc<Mutex<Performer>>,
        src: Endpoint<OutputStream<f64>>,
        dst_voices: Arc<Mutex<Performer>>,
        dst: Endpoint<InputStream<f64>>,
        feedback: Arc<AtomicCell<f32>>,
    ) -> Self {
        Self::new(src_voices, dst_voices, StreamCopyVariant::float64(src, dst), feedback)
    }

    pub fn int32(
        src_voices: Arc<Mutex<Performer>>,
        src: Endpoint<OutputStream<i32>>,
        dst_voices: Arc<Mutex<Performer>>,
        dst: Endpoint<InputStream<i32>>,
        feedback: Arc<AtomicCell<f32>>,
    ) -> Self {
        Self::new(src_voices, dst_voices, StreamCopyVariant::int32(src, dst), feedback)
    }

    pub fn int64(
        src_voices: Arc<Mutex<Performer>>,
        src: Endpoint<OutputStream<i64>>,
        dst_voices: Arc<Mutex<Performer>>,
        dst: Endpoint<InputStream<i64>>,
        feedback: Arc<AtomicCell<f32>>,
    ) -> Self {
        Self::new(src_voices, dst_voices, StreamCopyVariant::int64(src, dst), feedback)
    }

    pub fn float32x2(
        src_voices: Arc<Mutex<Performer>>,
        src: Endpoint<OutputStream<[f32; 2]>>,
        dst_voices: Arc<Mutex<Performer>>,
        dst: Endpoint<InputStream<[f32; 2]>>,
        feedback: Arc<AtomicCell<f32>>,
    ) -> Self {
        Self::new(
            src_voices,
            dst_voices,
            StreamCopyVariant::float32x2(src, dst),
            feedback,
        )
    }
}

impl ExecuteAction for CopyStream {
    fn execute(&mut self, io: &mut IO) {
        let frames = io.get_num_frames();
        let src = self.src_voices.try_lock().unwrap();
        let dst = self.dst_voices.try_lock().unwrap();
        self.variant.copy(&src, &dst, frames);
    }
}

enum StreamInputVariant {
    Float32 {
        handle: Endpoint<InputStream<f32>>,
        buffer: Vec<f32>,
    },
    Float64 {
        handle: Endpoint<InputStream<f64>>,
        buffer: Vec<f64>,
    },
    Int32 {
        handle: Endpoint<InputStream<i32>>,
        buffer: Vec<i32>,
    },
    Int64 {
        handle: Endpoint<InputStream<i64>>,
        buffer: Vec<i64>,
    },
    Float32x2 {
        handle: Endpoint<InputStream<[f32; 2]>>,
        buffer: Vec<[f32; 2]>,
    },
}

impl StreamInputVariant {
    fn float32(handle: Endpoint<InputStream<f32>>) -> Self {
        Self::Float32 {
            handle,
            buffer: vec![0.0; STREAM_BUFFER_SIZE],
        }
    }

    fn float64(handle: Endpoint<InputStream<f64>>) -> Self {
        Self::Float64 {
            handle,
            buffer: vec![0.0; STREAM_BUFFER_SIZE],
        }
    }

    fn int32(handle: Endpoint<InputStream<i32>>) -> Self {
        Self::Int32 {
            handle,
            buffer: vec![0; STREAM_BUFFER_SIZE],
        }
    }

    fn int64(handle: Endpoint<InputStream<i64>>) -> Self {
        Self::Int64 {
            handle,
            buffer: vec![0; STREAM_BUFFER_SIZE],
        }
    }

    fn float32x2(handle: Endpoint<InputStream<[f32; 2]>>) -> Self {
        Self::Float32x2 {
            handle,
            buffer: vec![[0.0, 0.0]; STREAM_BUFFER_SIZE],
        }
    }

    fn clear(&mut self, performer: &Performer, frames: usize) {
        match self {
            StreamInputVariant::Float32 { handle, buffer } => {
                let frames = frames.min(buffer.len());
                performer.write(*handle, &buffer[..frames]);
            }
            StreamInputVariant::Float64 { handle, buffer } => {
                let frames = frames.min(buffer.len());
                performer.write(*handle, &buffer[..frames]);
            }
            StreamInputVariant::Int32 { handle, buffer } => {
                let frames = frames.min(buffer.len());
                performer.write(*handle, &buffer[..frames]);
            }
            StreamInputVariant::Int64 { handle, buffer } => {
                let frames = frames.min(buffer.len());
                performer.write(*handle, &buffer[..frames]);
            }
            StreamInputVariant::Float32x2 { handle, buffer } => {
                let frames = frames.min(buffer.len());
                performer.write(*handle, &buffer[..frames]);
            }
        }
    }
}

pub struct ClearStream {
    pub voices: Arc<Mutex<Performer>>,
    variant: StreamInputVariant,
}

impl ClearStream {
    pub fn float32(voices: Arc<Mutex<Performer>>, handle: Endpoint<InputStream<f32>>) -> Self {
        Self {
            voices,
            variant: StreamInputVariant::float32(handle),
        }
    }

    pub fn float64(voices: Arc<Mutex<Performer>>, handle: Endpoint<InputStream<f64>>) -> Self {
        Self {
            voices,
            variant: StreamInputVariant::float64(handle),
        }
    }

    pub fn int32(voices: Arc<Mutex<Performer>>, handle: Endpoint<InputStream<i32>>) -> Self {
        Self {
            voices,
            variant: StreamInputVariant::int32(handle),
        }
    }

    pub fn int64(voices: Arc<Mutex<Performer>>, handle: Endpoint<InputStream<i64>>) -> Self {
        Self {
            voices,
            variant: StreamInputVariant::int64(handle),
        }
    }

    pub fn float32x2(
        voices: Arc<Mutex<Performer>>,
        handle: Endpoint<InputStream<[f32; 2]>>,
    ) -> Self {
        Self {
            voices,
            variant: StreamInputVariant::float32x2(handle),
        }
    }
}

impl ExecuteAction for ClearStream {
    fn execute(&mut self, io: &mut IO) {
        let frames = io.get_num_frames();
        let performer = self.voices.try_lock().unwrap();
        self.variant.clear(&performer, frames);
    }
}

enum ExternalStreamVariant {
    Float32 {
        handle: Endpoint<OutputStream<f32>>,
    },
    Float32x2 {
        handle: Endpoint<OutputStream<[f32; 2]>>,
        buffer: Vec<[f32; 2]>,
    },
}

impl ExternalStreamVariant {
    fn float32(handle: Endpoint<OutputStream<f32>>) -> Self {
        Self::Float32 { handle }
    }

    fn float32x2(handle: Endpoint<OutputStream<[f32; 2]>>) -> Self {
        Self::Float32x2 {
            handle,
            buffer: vec![[0.0, 0.0]; STREAM_BUFFER_SIZE],
        }
    }
}

pub struct ExternalOutputStream {
    pub voices: Arc<Mutex<Performer>>,
    pub channel: usize,
    variant: ExternalStreamVariant,
}

impl ExternalOutputStream {
    pub fn float32(
        voices: Arc<Mutex<Performer>>,
        handle: Endpoint<OutputStream<f32>>,
        channel: usize,
    ) -> Self {
        Self {
            voices,
            channel,
            variant: ExternalStreamVariant::float32(handle),
        }
    }

    pub fn float32x2(
        voices: Arc<Mutex<Performer>>,
        handle: Endpoint<OutputStream<[f32; 2]>>,
        channel: usize,
    ) -> Self {
        Self {
            voices,
            channel,
            variant: ExternalStreamVariant::float32x2(handle),
        }
    }
}

impl ExecuteAction for ExternalOutputStream {
    fn execute(&mut self, io: &mut IO) {
        let frames = io.get_num_frames();
        match &mut self.variant {
            ExternalStreamVariant::Float32 { handle } => {
                if let Some(channel) = io.audio.get_mut(self.channel) {
                    let frames = frames.min(channel.len());
                    self.voices
                        .try_lock()
                        .unwrap()
                        .read(*handle, &mut channel[..frames]);
                }
            }
            ExternalStreamVariant::Float32x2 { handle, buffer } => {
                let frames = frames.min(buffer.len());
                {
                    let voices = self.voices.try_lock().unwrap();
                    voices.read(*handle, &mut buffer[..frames]);
                }

                if let Some(left) = io.audio.get_mut(self.channel * 2) {
                    for (l, sample) in left.iter_mut().zip(buffer.iter()) {
                        *l = sample[0];
                    }
                }

                if let Some(right) = io.audio.get_mut(self.channel * 2 + 1) {
                    for (r, sample) in right.iter_mut().zip(buffer.iter()) {
                        *r = sample[1];
                    }
                }
            }
        }
    }
}
