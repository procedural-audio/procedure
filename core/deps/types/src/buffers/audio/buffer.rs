use std::mem::ManuallyDrop;
use std::slice;

pub use crate::math::FloatBuffer;
use crate::AudioChannel;
use crate::AudioChannelMut;

unsafe impl Send for AudioBuffer {}
unsafe impl Sync for AudioBuffer {}

pub struct AudioBuffer {
    buffer: Vec<f32>,
}

impl AudioBuffer {
    pub fn new(capacity: usize) -> Self {
        Self {
            buffer: vec![0.0; capacity],
        }
    }

    pub fn from(buffer: Vec<f32>) -> Self {
        Self { buffer }
    }

    pub fn from_raw(ptr: *mut f32, capacity: usize) -> Self {
        unsafe {
            Self {
                buffer: Vec::from_raw_parts(ptr, capacity, capacity),
            }
        }
    }

    pub fn capacity(&self) -> usize {
        self.buffer.capacity()
    }

    pub fn as_ptr(&self) -> *const f32 {
        self.buffer.as_ptr()
    }

    pub fn as_mut_ptr(&mut self) -> *mut f32 {
        self.buffer.as_mut_ptr()
    }

    pub fn as_slice<'a>(&'a self) -> &'a [f32] {
        self.as_array()[0]
    }

    pub fn as_slice_mut<'a>(&'a mut self) -> &'a mut [f32] {
        self.as_array_mut()[0]
    }
}

impl AudioChannel<1> for AudioBuffer {
    fn as_array<'a>(&'a self) -> [&'a [f32]; 1] {
        self.buffer.as_array()
    }
}

impl AudioChannelMut<1> for AudioBuffer {
    fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; 1] {
        self.buffer.as_array_mut()
    }
}

impl<'a> IntoIterator for &'a AudioBuffer {
    type Item = &'a f32;
    type IntoIter = slice::Iter<'a, f32>;

    fn into_iter(self) -> slice::Iter<'a, f32> {
        self.as_slice().into_iter()
    }
}

impl<'a> IntoIterator for &'a mut AudioBuffer {
    type Item = &'a mut f32;
    type IntoIter = slice::IterMut<'a, f32>;

    fn into_iter(self) -> slice::IterMut<'a, f32> {
        self.as_slice_mut().into_iter()
    }
}

// unsafe impl Send for GraphAudioBuffer {}
// unsafe impl Sync for GraphAudioBuffer {}

pub struct GraphAudioBuffer {
    buffer: ManuallyDrop<AudioBuffer>,
    owned: bool,
}

impl GraphAudioBuffer {
    pub fn new(capacity: usize) -> Self {
        Self {
            buffer: ManuallyDrop::new(AudioBuffer::new(capacity)),
            owned: true,
        }
    }

    pub fn from(buffer: Vec<f32>) -> Self {
        Self {
            buffer: ManuallyDrop::new(AudioBuffer::from(buffer)),
            owned: true,
        }
    }

    pub fn from_raw(ptr: *mut f32, capacity: usize) -> Self {
        Self {
            buffer: ManuallyDrop::new(AudioBuffer::from_raw(ptr, capacity)),
            owned: true,
        }
    }

    pub fn capacity(&self) -> usize {
        self.buffer.capacity()
    }

    pub fn buffer(&self) -> &AudioBuffer {
        &self.buffer
    }

    pub fn buffer_mut(&mut self) -> &mut AudioBuffer {
        &mut self.buffer
    }

    /*pub fn as_channel(&self) -> &Mono {
        unsafe { std::mem::transmute::<&GraphAudioBuffer, &Mono>(self) }
    }

    pub fn as_channel_mut(&mut self) -> &mut Mono {
        unsafe { std::mem::transmute::<&mut GraphAudioBuffer, &mut Mono>(self) }
    }*/

    pub fn as_ptr(&self) -> *const f32 {
        self.buffer.as_ptr()
    }

    pub fn as_mut_ptr(&mut self) -> *mut f32 {
        self.buffer.as_mut_ptr()
    }

    pub fn as_slice<'a>(&'a self) -> &'a [f32] {
        self.as_array()[0]
    }

    pub fn as_slice_mut<'a>(&'a mut self) -> &'a mut [f32] {
        self.as_array_mut()[0]
    }

    pub fn unowned(&self) -> GraphAudioBuffer {
        unsafe {
            Self {
                buffer: ManuallyDrop::new(AudioBuffer {
                    buffer: Vec::from_raw_parts(
                        self.as_ptr() as *mut f32,
                        self.capacity(),
                        self.capacity(),
                    ),
                }),
                owned: false,
            }
        }
    }

    pub unsafe fn forget(&mut self) {
        self.owned = false;
    }
}

impl Drop for GraphAudioBuffer {
    fn drop(&mut self) {
        if self.owned {
            unsafe {
                ManuallyDrop::drop(&mut self.buffer);
            }
        }
    }
}

impl AudioChannel<1> for GraphAudioBuffer {
    fn as_array<'a>(&'a self) -> [&'a [f32]; 1] {
        self.buffer.as_array()
    }
}

impl AudioChannelMut<1> for GraphAudioBuffer {
    fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; 1] {
        self.buffer.as_array_mut()
    }
}

impl<'a> IntoIterator for &'a GraphAudioBuffer {
    type Item = &'a f32;
    type IntoIter = slice::Iter<'a, f32>;

    fn into_iter(self) -> slice::Iter<'a, f32> {
        self.as_slice().into_iter()
    }
}

impl<'a> IntoIterator for &'a mut GraphAudioBuffer {
    type Item = &'a mut f32;
    type IntoIter = slice::IterMut<'a, f32>;

    fn into_iter(self) -> slice::IterMut<'a, f32> {
        self.as_slice_mut().into_iter()
    }
}
