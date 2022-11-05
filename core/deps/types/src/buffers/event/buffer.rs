use std::mem;
use std::slice;

use crate::buffers::event::event::*;
pub use crate::math::FloatBuffer;

unsafe impl Send for NoteBuffer {}
unsafe impl Sync for NoteBuffer {}

pub struct NoteBuffer {
    buffer: Vec<Event>
}

impl NoteBuffer {
    pub fn new() -> Self {
        Self {
            buffer: Vec::new()
        }
    }

    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            buffer: Vec::with_capacity(capacity)
        }
    }

    pub fn from_raw_parts(events: *mut Event, length: usize, capacity: usize) -> Self {
        unsafe {
            Self {
                buffer: Vec::from_raw_parts(events, length, capacity)
            }
        }
    }

    pub fn push(&mut self, event: Event) {
        self.buffer.push(event);
    }

    /*pub fn from_raw(events: *mut Event, count: usize) -> Self {
        Self {
            buffer: Vec::from_raw_parts(events, length, capacity)
        }
    }*/

    pub fn as_ptr(&self) -> *const Event {
        self.buffer.as_ptr()
    }

    pub fn as_mut_ptr(&mut self) -> *mut Event {
        self.buffer.as_mut_ptr()
    }

    pub fn capacity(&self) -> usize {
        self.buffer.capacity()
    }

    pub fn as_ref(&self) -> &[Event] {
        self.buffer.as_ref()
    }

    pub fn as_mut(&mut self) -> &mut [Event] {
        self.buffer.as_mut()
    }

    pub fn copy_from(&mut self, source: &NoteBuffer) {
        for (dest, src) in self.into_iter().zip(source) {
            *dest = *src;
        }
    }

    pub fn add_from(&mut self, source: &NoteBuffer) {
        let mut i = 0;

        for dest in self {
            if *dest != Event::None {
                if source[i] == Event::None || i >= source.capacity() {
                    return;
                }

                *dest = source[i];
                i += 1;
            }
        }
    }

    /*pub fn unowned(&self) -> NoteBuffer {
        NoteBuffer {
            data: self.data,
            capacity: self.capacity,
            owned: false,
        }
    }*/

    pub fn clear(&mut self) {
        self.buffer.clear();
    }

    pub fn len(&self) -> usize {
        self.buffer.len()
    }
}

impl<'a> IntoIterator for &'a NoteBuffer {
    type Item = &'a Event;
    type IntoIter = slice::Iter<'a, Event>;

    fn into_iter(self) -> slice::Iter<'a, Event> {
        self.as_ref().into_iter()
    }
}

impl<'a> IntoIterator for &'a mut NoteBuffer {
    type Item = &'a mut Event;
    type IntoIter = slice::IterMut<'a, Event>;

    fn into_iter(mut self) -> slice::IterMut<'a, Event> {
        self.as_mut().into_iter()
    }
}

impl std::ops::Index<usize> for NoteBuffer {
    type Output = Event;

    fn index(&self, index: usize) -> &Self::Output {
        self.buffer.index(index)
    }
}

impl std::ops::IndexMut<usize> for NoteBuffer {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        self.buffer.index_mut(index)
    }
}
