use std::ops::{Deref, DerefMut};

use crate::buffers::time::Time;
use crate::buffers::time::TimeBuffer;

pub struct TimeBufferGraph {
    buffer: TimeBuffer,
    connected: bool,
}

impl TimeBufferGraph {
    pub fn new() -> Self {
        let buffer = TimeBuffer::new();

        Self {
            buffer,
            connected: false,
        }
    }

    pub fn connected(&self) -> bool {
        self.connected
    }

    pub fn get(&self) -> Time {
        self.buffer.get()
    }

    pub fn set(&mut self, time: Time) {
        self.buffer.set(time);
    }
}

unsafe impl Send for TimeBufferGraph {}
unsafe impl Sync for TimeBufferGraph {}

impl Deref for TimeBufferGraph {
    type Target = Time;

    fn deref(&self) -> &Self::Target {
        self.buffer.deref()
    }
}

impl DerefMut for TimeBufferGraph {
    fn deref_mut(&mut self) -> &mut Self::Target {
        self.buffer.deref_mut()
    }
}
