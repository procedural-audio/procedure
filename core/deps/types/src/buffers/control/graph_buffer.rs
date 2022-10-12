use std::ops::{Deref, DerefMut};

use crate::buffers::ControlBuffer;
pub use crate::math::Float;

unsafe impl Send for ControlBufferGraph {}
unsafe impl Sync for ControlBufferGraph {}

pub struct ControlBufferGraph {
    buffer: ControlBuffer,
    connected: bool,
}

impl ControlBufferGraph {
    pub fn new() -> Self {
        let buffer = ControlBuffer::new();

        println!("New ControlBufferGraph {:p}", buffer.as_ptr());

        Self {
            buffer,
            connected: false,
        }
    }

    pub fn as_ptr(&self) -> *const f32 {
        self.buffer.as_ptr()
    }

    pub fn as_mut_ptr(&mut self) -> *mut f32 {
        self.buffer.as_mut_ptr()
    }

    pub fn connected(&self) -> bool {
        self.connected
    }

    /*pub fn from(buffer: &ControlBuffer) -> Self {
            ControlBufferGraph {
                data: std::ptr::NonNull::<f32>::new_unchecked(buffer.as_ptr() as *mut f32),
            }
    }*/

    /*pub fn from_raw_parts(ptr: *mut f32) -> Self {
        unsafe {
            ControlBufferGraph {
                buffer: ControlBuffer::from
                owned: false
            }
        }
    }*/

    /*pub fn as_ptr(&self) -> *mut f32 {
        self.data.as_ptr()
    }*/

    pub fn get(&self) -> f32 {
        // println!("Getting ControlBufferGraph {:p}", self.as_ptr());
        self.buffer.get()
    }

    pub fn set(&mut self, value: f32) {
        // println!("Setting ControlBufferGraph {:p}", self.as_ptr());
        self.buffer.set(value);
    }

    /*pub fn as_array<'a>(&'a self) -> [&'a [f32]; 1] {
        unsafe { [ slice::from_raw_parts(self.data.as_ref(), 1) ] }
    }

    pub fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; 1] {
        unsafe { [ slice::from_raw_parts_mut(self.data.as_mut(), 1) ] }
    }*/
}

impl Drop for ControlBufferGraph {
    fn drop(&mut self) {
        println!("Dropping ControlBufferGraph {:p}", self.as_ptr());
    }
}

/*impl Clone for ControlBufferGraph {
    fn clone(&self) -> Self {
        Self {
            buffer: ManuallyDrop::new(ControlBuffer::from_raw(self.buffer.as_ptr() as *mut f32)),
            owned: self.owned.clone()
        }
    }
}*/

/*impl std::ops::AddAssign for ControlBufferGraph {
    fn add_assign(&mut self, source: ControlBufferGraph) {
        self.add_from(&source);
    }
}*/

impl Deref for ControlBufferGraph {
    type Target = f32;

    fn deref(&self) -> &Self::Target {
        self.buffer.deref()
    }
}

impl DerefMut for ControlBufferGraph {
    fn deref_mut(&mut self) -> &mut Self::Target {
        self.buffer.deref_mut()
    }
}
