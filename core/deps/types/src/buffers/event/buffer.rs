use std::mem;
use std::slice;

use crate::buffers::event::event::*;
pub use crate::math::FloatBuffer;

unsafe impl Send for NoteBuffer {}
unsafe impl Sync for NoteBuffer {}

pub struct NoteBuffer {
    data: *mut Event,
    capacity: usize,
    owned: bool,
}

impl NoteBuffer {
    pub fn new(capacity: usize) -> Self {
        let mut data = Vec::with_capacity(capacity);

        for _ in 0..capacity {
            data.push(Event::None);
        }

        let data_ptr = data.as_mut_ptr();

        mem::forget(data);

        Self {
            data: data_ptr,
            capacity,
            owned: true,
        }
    }

    pub fn push(&mut self, event: Event) {
        for e in self {
            if *e == Event::None {
                *e = event;
                return;
            }
        }

        println!("Couldn't fit note in event buffer");
    }

    pub fn from_raw(events: *mut Event, count: usize) -> Self {
        Self {
            data: events,
            capacity: count,
            owned: true,
        }
    }

    pub fn as_ptr(&self) -> *mut Event {
        self.data
    }

    pub fn capacity(&self) -> usize {
        self.capacity
    }

    pub fn as_ref<'a>(&self) -> &'a [Event] {
        unsafe { slice::from_raw_parts(self.data as *const Event, self.capacity) }
    }

    pub fn as_mut(&mut self) -> &mut [Event] {
        unsafe { slice::from_raw_parts_mut(self.data as *mut Event, self.capacity) }
    }

    pub fn forget(&mut self) {
        self.owned = false;
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

    pub fn unowned(&self) -> NoteBuffer {
        NoteBuffer {
            data: self.data,
            capacity: self.capacity,
            owned: false,
        }
    }

    pub fn clear(&mut self) {
        for note in self.as_mut() {
            if *note != Event::None {
                *note = Event::None;
            } else {
                break;
            }
        }
    }

    pub fn len(&self) -> usize {
        let mut i = 0;
        for event in self {
            match event {
                Event::None => (),
                _ => i += 1
            }
        }

        return i;
    }
}

impl Drop for NoteBuffer {
    fn drop(&mut self) {
        unsafe {
            if self.owned {
                let _ = Vec::from_raw_parts(self.data, 0, self.capacity);
            }
        }
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

    fn into_iter(self) -> slice::IterMut<'a, Event> {
        self.as_mut().into_iter()
    }
}

impl std::ops::Index<usize> for NoteBuffer {
    type Output = Event;

    fn index(&self, index: usize) -> &Self::Output {
        unsafe { &*self.data.offset(index as isize) }
    }
}

impl std::ops::IndexMut<usize> for NoteBuffer {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        unsafe { &mut *self.data.offset(index as isize) }
    }
}
