use std::ops::{Deref, DerefMut};

use crate::buffers::time::Time;

pub struct TimeBuffer {
    data: Box<Time>,
}

impl TimeBuffer {
    pub fn new() -> Self {
        Self {
            data: Box::new(Time::from(0.0, 0.0)),
        }
    }

    pub fn get(&self) -> Time {
        *self.data
    }

    pub fn set(&mut self, time: Time) {
        *self.data = time;
    }
}

unsafe impl Send for TimeBuffer {}
unsafe impl Sync for TimeBuffer {}

impl Deref for TimeBuffer {
    type Target = Time;

    fn deref(&self) -> &Self::Target {
        &self.data
    }
}

impl DerefMut for TimeBuffer {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.data
    }
}
