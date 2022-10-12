pub use crate::math::FloatBuffer;
use std::ops::{Deref, DerefMut};

pub struct ControlBuffer {
    data: Box<f32>,
}

impl ControlBuffer {
    pub fn new() -> Self {
        Self {
            data: Box::new(0.0),
        }
    }

    pub unsafe fn from_raw(buffer: *mut f32) -> Self {
        Self {
            data: Box::from_raw(buffer),
        }
    }

    pub fn as_ptr(&self) -> *const f32 {
        &*self.data
    }

    pub fn as_mut_ptr(&mut self) -> *mut f32 {
        &mut *self.data as *mut f32
    }

    pub fn get(&self) -> f32 {
        *self.data
    }

    pub fn set(&mut self, value: f32) {
        *self.data = value;
    }
}

unsafe impl Send for ControlBuffer {}
unsafe impl Sync for ControlBuffer {}

impl Deref for ControlBuffer {
    type Target = f32;

    fn deref(&self) -> &Self::Target {
        &self.data
    }
}

impl DerefMut for ControlBuffer {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.data
    }
}
