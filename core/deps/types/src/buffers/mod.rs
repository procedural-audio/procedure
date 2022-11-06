use std::ops::{Deref, DerefMut};
use std::slice;

pub mod audio;
pub mod control;
pub mod event;
pub mod time;

pub use crate::buffers::audio::*;
pub use crate::buffers::control::*;
pub use crate::buffers::event::*;
pub use crate::buffers::time::*;

use crate::dsp::{Generator, Processor};

use std::borrow::BorrowMut;
use std::ops::{Index, IndexMut};

pub struct IO {
    pub audio: AudioBus<Stereo>,
    pub events: Bus<NoteBuffer>,
    pub control: Bus<ControlBuffer>,
    pub time: Bus<TimeBuffer>,
}

/* Individual Buffer Types */

pub type NoteBuffer = Buffer<Event>;

/* Buffer Type */

pub struct Buffer<T: Copy + Clone> {
    items: Vec<T>,
}

impl<T: Copy + Clone> Buffer<T> {
    pub fn new() -> Self {
        Self {
            items: Vec::new()
        }
    }

    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            items: Vec::with_capacity(capacity)
        }
    }

    pub fn from(items: Vec<T>) -> Self {
        Self { items }
    }

    pub unsafe fn from_raw_parts(ptr: *mut T, length: usize, capacity: usize) -> Self {
        Self {
            items: Vec::from_raw_parts(ptr, length, capacity),
        }
    }

    pub fn len(&self) -> usize {
        self.items.len()
    }

    pub fn capacity(&self) -> usize {
        self.items.capacity()
    }

    pub fn as_ref(&self) -> &[T] {
        self.items.as_ref()
    }

    pub fn as_mut(&mut self) -> &mut [T] {
        self.items.as_mut()
    }

    pub fn as_slice<'a>(&'a self) -> &'a [T] {
        self.items.as_slice()
    }

    pub fn as_slice_mut<'a>(&'a mut self) -> &'a mut [T] {
        self.items.as_mut_slice()
    }

    pub fn as_ptr(&self) -> *const T {
        self.items.as_ptr()
    }

    pub fn as_mut_ptr(&mut self) -> *mut T {
        self.items.as_mut_ptr()
    }

    /* Operations */

    pub fn push(&mut self, item: T) {
        self.items.push(item);
    }

    pub fn clear(&mut self) {
        self.items.clear();
    }

    pub fn fill<G: Generator<Item = T>>(&mut self, src: &mut G) {
        for d in &mut self.items {
            *d = src.gen();
        }
    }

    pub fn copy_from(&mut self, src: &Buffer<T>) {
        // self.items.as_mut_slice().copy_from_slice(src.as_slice())

        self.items.clear();
        
        for item in src {
            self.items.push(*item);
        }
    }

    pub fn append_from(&mut self, src: &Buffer<T>) {
        for s in src.as_slice() {
            self.items.push(*s);
        }
    }

    pub fn process<P: Processor<Item = T>>(&mut self, src: &mut P) {
        for d in &mut self.items {
            *d = src.process(*d);
        }
    }
}

impl<T: Copy + Clone + std::ops::Add<Output = T>> Buffer<T> {
    pub fn add_from(&mut self, src: &Buffer<T>) {
        for (d, s) in self.items.iter_mut().zip(src.as_slice()) {
            *d = *d + *s;
        }
    }
}

impl<T: Copy + Clone> Index<usize> for Buffer<T> {
    type Output = T;

    fn index(&self, index: usize) -> &Self::Output {
        &self.items[index]
    }
}

impl<T: Copy + Clone> IndexMut<usize> for Buffer<T> {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        &mut self.items[index]
    }
}

impl<'a, T: Copy + Clone> IntoIterator for &'a Buffer<T> {
    type Item = &'a T;
    type IntoIter = slice::Iter<'a, T>;

    fn into_iter(self) -> slice::Iter<'a, T> {
        self.as_ref().into_iter()
    }
}

impl<'a, T: Copy + Clone> IntoIterator for &'a mut Buffer<T> {
    type Item = &'a mut T;
    type IntoIter = slice::IterMut<'a, T>;

    fn into_iter(mut self) -> slice::IterMut<'a, T> {
        self.as_mut().into_iter()
    }
}

pub struct Bus<T> {
    channels: Vec<Channel<T>>,
}

impl<T> Bus<T> {
    pub fn new() -> Self {
        Self {
            channels: Vec::new(),
        }
    }

    pub fn add_channel(&mut self, channel: Channel<T>) {
        self.channels.push(channel);
    }

    pub fn channel(&self, index: usize) -> &Channel<T> {
        &self.channels[index]
    }

    pub fn channel_mut(&mut self, index: usize) -> &mut Channel<T> {
        &mut self.channels[index]
    }

    pub fn num_channels(&self) -> usize {
        self.channels.len()
    }
}

impl<T> Index<usize> for Bus<T> {
    type Output = T;

    fn index(&self, index: usize) -> &Self::Output {
        self.channel(index).deref()
    }
}

impl<T> IndexMut<usize> for Bus<T> {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        self.channel_mut(index).deref_mut()
    }
}

pub struct Channel<T> {
    buffer: T,
    connected: bool,
}

impl<T> Channel<T> {
    pub fn new(buffer: T, connected: bool) -> Self {
        Self { buffer, connected }
    }

    pub fn is_connected(&self) -> bool {
        self.connected
    }

    pub fn set_connected(&mut self, connected: bool) {
        self.connected = connected;
    }
}

impl<T> Deref for Channel<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.buffer
    }
}

impl<T> DerefMut for Channel<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.buffer
    }
}

pub trait AudioChannel<const C: usize> {
    fn as_array<'a>(&'a self) -> [&'a [f32]; C];

    fn as_ptr(&self) -> *mut f32 {
        self.as_array()[0].as_ptr() as *mut f32
    }

    fn len(&self) -> usize {
        self.as_array()[0].len()
    }

    fn channels(&self) -> usize {
        C
    }

    fn rms(&self) -> f32 {
        let mut sample_count = 0;
        let mut sum = 0.0;

        for slice in self.as_array() {
            sample_count += slice.len();
            for sample in slice {
                sum += *sample * *sample;
            }
        }

        let avg = sum / sample_count as f32;
        return f32::sqrt(avg);
    }

    fn peak(&self) -> f32 {
        let mut max = 0.0;

        for slice in self.as_array() {
            for sample in slice {
                if f32::abs(*sample) > max {
                    max = f32::abs(*sample);
                }
            }
        }

        max
    }
}

pub trait AudioChannelMut<const C: usize>: AudioChannel<C> {
    fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; C];

    fn fill(&mut self, value: f32) {
        for slice in self.as_array_mut() {
            for sample in slice {
                *sample = value;
            }
        }
    }

    fn delay(&mut self, _samples: usize) {
        panic!("Delay not implemented");
    }

    fn zero(&mut self) {
        for slice in self.as_array_mut() {
            for sample in slice {
                *sample = 0.0;
            }
        }
    }

    fn gain(&mut self, decibals: f32) {
        for slice in self.as_array_mut() {
            for sample in slice {
                *sample *= decibals;
            }
        }
    }

    fn clip(&mut self) {
        for slice in self.as_array_mut() {
            for sample in slice {
                if *sample > 1.0 {
                    *sample = 1.0;
                }

                if *sample < -1.0 {
                    *sample = -1.0;
                }
            }
        }
    }

    fn copy_from<T: AudioChannel<C> + ?Sized>(&mut self, buffer: &T) {
        for (dest, src) in self.as_array_mut().iter_mut().zip(buffer.as_array()) {
            if dest.len() == src.len() {
                dest.copy_from_slice(src);
            } else {
                dest[0..src.len()].copy_from_slice(src);
            }
        }
    }

    fn add_from<T: AudioChannel<C> + ?Sized>(&mut self, buffer: &T) {
        for (dest, src) in self.as_array_mut().iter_mut().zip(buffer.as_array()) {
            for (d, s) in dest.iter_mut().zip(src) {
                *d += *s;
            }
        }
    }
}

impl<'s> AudioChannel<1> for Vec<f32> {
    fn as_array<'a>(&'a self) -> [&'a [f32]; 1] {
        [self.as_slice()]
    }
}

impl<'s> AudioChannelMut<1> for Vec<f32> {
    fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; 1] {
        [self.as_mut_slice()]
    }
}

impl<'s> AudioChannel<1> for [f32] {
    fn as_array<'a>(&'a self) -> [&'a [f32]; 1] {
        [self]
    }
}

impl<'s> AudioChannelMut<1> for [f32] {
    fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; 1] {
        [self]
    }
}

/*impl<T: AudioChannel<1>> Buffer for T {
    type Element = f32;

    fn as_slice<'a>(&'a self) -> &'a [Self::Element] {
        self.as_array()[0]
    }
}

impl<T: AudioChannelMut<1>> BufferMut for T {
    type Element = f32;

    fn as_slice_mut<'a>(&'a mut self) -> &'a mut [Self::Element] {
        self.as_array_mut()[0]
    }
}*/
