use crate::buffers::AudioBuffer;
use crate::buffers::GraphAudioBuffer;
use crate::{AudioChannel, AudioChannelMut};

pub trait AudioChannels {
    fn new(capacity: usize) -> Self;
    fn unowned(&self) -> Self;
    fn channel(&self, index: usize) -> Option<&AudioBuffer>;
    fn channel_mut(&mut self, index: usize) -> Option<&mut AudioBuffer>;
    fn channels_iter(&self) -> ChannelsIter<'_, Self>
    where
        Self: Sized;
    fn channels_iter_mut(&mut self) -> ChannelsIterMut<'_, Self>
    where
        Self: Sized;
    unsafe fn forget(&mut self);
}

/* ========== Mono ========== */

#[repr(transparent)]
pub struct GraphMono {
    pub buffer: GraphAudioBuffer,
}

impl GraphMono {
    pub fn as_array<'a>(&'a self) -> [&'a [f32]; 1] {
        [self.buffer.as_slice()]
    }

    pub fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; 1] {
        [self.buffer.as_slice_mut()]
    }
}

impl AudioChannel<1> for GraphMono {
    fn as_array<'a>(&'a self) -> [&'a [f32]; 1] {
        [self.buffer.as_slice()]
    }
}

impl AudioChannelMut<1> for GraphMono {
    fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; 1] {
        [self.buffer.as_slice_mut()]
    }
}

impl AudioChannels for GraphMono {
    fn new(capacity: usize) -> Self {
        Self {
            buffer: GraphAudioBuffer::new(capacity),
        }
    }

    fn channel(&self, index: usize) -> Option<&AudioBuffer> {
        match index {
            0 => Some(self.buffer.buffer()),
            _ => None,
        }
    }

    fn channel_mut(&mut self, index: usize) -> Option<&mut AudioBuffer> {
        match index {
            0 => Some(self.buffer.buffer_mut()),
            _ => None,
        }
    }

    fn channels_iter<'a>(&'a self) -> ChannelsIter<'a, GraphMono> {
        ChannelsIter::new(self)
    }

    fn channels_iter_mut<'a>(&'a mut self) -> ChannelsIterMut<'a, GraphMono> {
        ChannelsIterMut::new(self)
    }

    fn unowned(&self) -> GraphMono {
        GraphMono {
            buffer: self.buffer.unowned(),
        }
    }

    unsafe fn forget(&mut self) {
        self.buffer.forget();
    }
}

/*impl FloatBuffer for Mono {
    fn fill(&mut self, value: f32) {
        self.buffer.fill(value);
    }

    fn delay(&mut self, _samples: usize) {
        println!("Delay not implemented");
    }

    fn copy_from(&mut self, source: &Self) where Self: Sized {
        self.buffer.copy_from(&source.buffer);
    }

    fn add_from(&mut self, source: &Self) where Self: Sized {
        self.buffer.add_from(&source.buffer);
    }

    fn zero(&mut self) {
        self.buffer.zero();
    }

    fn gain(&mut self, decibals: f32) {
        self.buffer.gain(decibals);
    }
}*/

/* ========== Stereo ========== */

pub struct Stereo {
    pub left: GraphAudioBuffer,
    pub right: GraphAudioBuffer,
}

impl Stereo {}

impl AudioChannel<2> for Stereo {
    fn as_array<'a>(&'a self) -> [&'a [f32]; 2] {
        [self.left.as_slice(), self.right.as_slice()]
    }
}

impl AudioChannelMut<2> for Stereo {
    fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; 2] {
        [self.left.as_slice_mut(), self.right.as_slice_mut()]
    }
}

impl AudioChannels for Stereo {
    fn new(capacity: usize) -> Self {
        Self {
            left: GraphAudioBuffer::new(capacity),
            right: GraphAudioBuffer::new(capacity),
        }
    }

    fn channel(&self, index: usize) -> Option<&AudioBuffer> {
        match index {
            0 => Some(self.left.buffer()),
            1 => Some(self.right.buffer()),
            _ => None,
        }
    }

    fn channel_mut(&mut self, index: usize) -> Option<&mut AudioBuffer> {
        match index {
            0 => Some(self.left.buffer_mut()),
            1 => Some(self.right.buffer_mut()),
            _ => None,
        }
    }

    fn channels_iter(&self) -> ChannelsIter<'_, Stereo> {
        ChannelsIter::new(self)
    }

    fn channels_iter_mut(&mut self) -> ChannelsIterMut<'_, Stereo> {
        ChannelsIterMut::new(self)
    }

    fn unowned(&self) -> Stereo {
        /*Stereo {
            left: AudioBuffer {
                data: unsafe { std::ptr::NonNull::new_unchecked(self.left.as_ptr()) },
                capacity: self.left.capacity(),
                owned: false
            },
            right: AudioBuffer {
                data: unsafe { std::ptr::NonNull::new_unchecked(self.right.as_ptr()) },
                capacity: self.left.capacity(),
                owned: false
            }
        }*/

        Stereo {
            left: self.left.unowned(),
            right: self.right.unowned(),
        }
    }

    unsafe fn forget(&mut self) {
        self.left.forget();
        self.right.forget();
    }
}

/*impl FloatBuffer for Stereo {
    fn fill(&mut self, value: f32) {
        self.left.fill(value);
        self.right.fill(value);
    }

    fn delay(&mut self, _samples: usize) {
        println!("Delay not implemented");
    }

    fn copy_from(&mut self, source: &Self) where Self: Sized {
        self.left.copy_from(&source.left);
        self.right.copy_from(&source.right);
    }

    fn add_from(&mut self, source: &Self) where Self: Sized {
        self.left.add_from(&source.left);
        self.right.add_from(&source.right);
    }

    fn zero(&mut self) {
        self.left.zero();
        self.right.zero();
    }

    fn gain(&mut self, decibals: f32) {
        self.left.gain(decibals);
        self.right.gain(decibals);
    }
}*/

impl<'a> IntoIterator for &'a Stereo {
    type Item = (&'a f32, &'a f32);
    type IntoIter = std::iter::Zip<std::slice::Iter<'a, f32>, std::slice::Iter<'a, f32>>;

    fn into_iter(self) -> Self::IntoIter {
        self.left.as_slice().iter().zip(self.right.as_slice())
    }
}

impl<'a> IntoIterator for &'a mut Stereo {
    type Item = (&'a mut f32, &'a mut f32);
    type IntoIter = std::iter::Zip<std::slice::IterMut<'a, f32>, std::slice::IterMut<'a, f32>>;

    fn into_iter(self) -> Self::IntoIter {
        self.left
            .as_slice_mut()
            .iter_mut()
            .zip(self.right.as_slice_mut())
    }
}

/* ========== Surround ========== */

/*
pub struct Surround (
    AudioBuffer,
    AudioBuffer,
    AudioBuffer,
    AudioBuffer,
    AudioBuffer,
    AudioBuffer,
    AudioBuffer,
    AudioBuffer,
);

impl Surround {
    pub fn as_array<'a>(&'a self) -> [&'a [f32]; 8] {
        [
            self.0.as_slice(),
            self.1.as_slice(),
            self.2.as_slice(),
            self.3.as_slice(),
            self.4.as_slice(),
            self.5.as_slice(),
            self.6.as_slice(),
            self.7.as_slice(),
        ]
    }

    pub fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; 8] {
        [
            self.0.as_slice_mut(),
            self.1.as_slice_mut(),
            self.2.as_slice_mut(),
            self.3.as_slice_mut(),
            self.4.as_slice_mut(),
            self.5.as_slice_mut(),
            self.6.as_slice_mut(),
            self.7.as_slice_mut(),
        ]
    }
}

impl AudioChannel<8> for Surround {
    fn as_array<'a>(&'a self) -> [&'a [f32]; 8] {
        [
            self.0.as_slice(),
            self.1.as_slice(),
            self.2.as_slice(),
            self.3.as_slice(),
            self.4.as_slice(),
            self.5.as_slice(),
            self.6.as_slice(),
            self.7.as_slice(),
        ]
    }
}

impl AudioChannelMut<8> for Surround {
    fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; 8] {
        [
            self.0.as_slice_mut(),
            self.1.as_slice_mut(),
            self.2.as_slice_mut(),
            self.3.as_slice_mut(),
            self.4.as_slice_mut(),
            self.5.as_slice_mut(),
            self.6.as_slice_mut(),
            self.7.as_slice_mut(),
        ]
    }
}

impl AudioChannels for Surround {
    fn new(capacity: usize) -> Self {
        Self (
            AudioBuffer::new(capacity),
            AudioBuffer::new(capacity),
            AudioBuffer::new(capacity),
            AudioBuffer::new(capacity),
            AudioBuffer::new(capacity),
            AudioBuffer::new(capacity),
            AudioBuffer::new(capacity),
            AudioBuffer::new(capacity)
        )
    }

    fn channel(&self, index: usize) -> Option<&AudioBuffer> {
        match index {
            0 => Some(&self.0),
            1 => Some(&self.1),
            2 => Some(&self.2),
            3 => Some(&self.3),
            4 => Some(&self.4),
            5 => Some(&self.5),
            6 => Some(&self.6),
            7 => Some(&self.7),
            _ => None
        }
    }

    fn channel_mut(&mut self, index: usize) -> Option<&mut AudioBuffer> {
        match index {
            0 => Some(&mut self.0),
            1 => Some(&mut self.1),
            2 => Some(&mut self.2),
            3 => Some(&mut self.3),
            4 => Some(&mut self.4),
            5 => Some(&mut self.5),
            6 => Some(&mut self.6),
            7 => Some(&mut self.7),
            _ => None
        }
    }

    fn channels_iter(&self) -> ChannelsIter<'_, Surround> {
        ChannelsIter::new(self)
    }

    fn channels_iter_mut(&mut self) -> ChannelsIterMut<'_, Surround> {
        ChannelsIterMut::new(self)
    }

    fn unowned(&self) -> Surround {
        Surround (
            AudioBuffer {
                data: unsafe { std::ptr::NonNull::new_unchecked(self.0.as_ptr()) },
                capacity: self.0.capacity(),
                owned: false
            },
            AudioBuffer {
                data: unsafe { std::ptr::NonNull::new_unchecked(self.1.as_ptr()) },
                capacity: self.1.capacity(),
                owned: false
            },
            AudioBuffer {
                data: unsafe { std::ptr::NonNull::new_unchecked(self.2.as_ptr()) },
                capacity: self.2.capacity(),
                owned: false
            },
            AudioBuffer {
                data: unsafe { std::ptr::NonNull::new_unchecked(self.3.as_ptr()) },
                capacity: self.3.capacity(),
                owned: false
            },
            AudioBuffer {
                data: unsafe { std::ptr::NonNull::new_unchecked(self.4.as_ptr()) },
                capacity: self.4.capacity(),
                owned: false
            },
            AudioBuffer {
                data: unsafe { std::ptr::NonNull::new_unchecked(self.5.as_ptr()) },
                capacity: self.5.capacity(),
                owned: false
            },
            AudioBuffer {
                data: unsafe { std::ptr::NonNull::new_unchecked(self.6.as_ptr()) },
                capacity: self.6.capacity(),
                owned: false
            },
            AudioBuffer {
                data: unsafe { std::ptr::NonNull::new_unchecked(self.7.as_ptr()) },
                capacity: self.7.capacity(),
                owned: false
            },
        )
    }

    unsafe fn forget(&mut self) {
        self.0.forget();
        self.1.forget();
        self.2.forget();
        self.3.forget();
        self.4.forget();
        self.5.forget();
        self.6.forget();
        self.7.forget();
    }
}
*/

/*impl FloatBuffer for Surround {
    fn fill(&mut self, value: f32) {
        self.0.fill(value);
        self.1.fill(value);
        self.2.fill(value);
        self.3.fill(value);
        self.4.fill(value);
        self.5.fill(value);
        self.6.fill(value);
        self.7.fill(value);
    }

    fn delay(&mut self, _samples: usize) {
        println!("Delay not implemented");
    }

    fn copy_from(&mut self, source: &Self) where Self: Sized {
        self.0.copy_from(&source.0);
        self.1.copy_from(&source.1);
        self.2.copy_from(&source.2);
        self.3.copy_from(&source.3);
        self.4.copy_from(&source.4);
        self.5.copy_from(&source.5);
        self.6.copy_from(&source.6);
        self.7.copy_from(&source.7);
    }

    fn add_from(&mut self, source: &Self) where Self: Sized {
        self.0.add_from(&source.0);
        self.1.add_from(&source.1);
        self.2.add_from(&source.2);
        self.3.add_from(&source.3);
        self.4.add_from(&source.4);
        self.5.add_from(&source.5);
        self.6.add_from(&source.6);
        self.7.add_from(&source.7);
    }

    fn zero(&mut self) {
        self.0.zero();
        self.1.zero();
        self.2.zero();
        self.3.zero();
        self.4.zero();
        self.5.zero();
        self.6.zero();
        self.7.zero();
    }

    fn gain(&mut self, decibals: f32) {
        self.0.gain(decibals);
        self.1.gain(decibals);
        self.2.gain(decibals);
        self.3.gain(decibals);
        self.4.gain(decibals);
        self.5.gain(decibals);
        self.6.gain(decibals);
        self.7.gain(decibals);
    }
}*/

/* ========== Channel iterators ========== */

/*
pub struct ChannelsIter<'a, T: AudioChannels> {
    channels: &'a T,
    index: usize,
}

impl<'a, T: AudioChannels> ChannelsIter<'a, T> {
    #[inline]
    pub fn new(channels: &'a T) -> Self {
        Self {
            channels,
            index: 0
        }
    }
}

impl<'a, T: AudioChannels> Iterator for ChannelsIter<'a, T> {
    type Item = AudioBuffer;

    fn next(&mut self) -> Option<Self::Item> {
        let ret = self.channels.channel(self.index);
        self.index += 1;
        ret
    }
}*/

pub struct ChannelsIter<'a, T: AudioChannels> {
    channels: &'a T,
    index: usize,
}

impl<'a, T: AudioChannels> ChannelsIter<'a, T> {
    #[inline]
    pub fn new(channels: &'a T) -> Self {
        Self { channels, index: 0 }
    }
}

impl<'a, T: AudioChannels> Iterator for ChannelsIter<'a, T> {
    type Item = &'a AudioBuffer;

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        let channel = self.channels.channel(self.index);
        self.index += 1;
        return channel;
    }
}

pub struct ChannelsIterMut<'a, T: AudioChannels> {
    channels: &'a mut T,
    index: usize,
}

impl<'a, T: AudioChannels> ChannelsIterMut<'a, T> {
    #[inline]
    pub fn new(channels: &'a mut T) -> Self {
        Self { channels, index: 0 }
    }
}

/*
impl<'a, T: AudioChannels> Iterator for ChannelsIterMut<'a, T> {
    type Item = &'a mut AudioBuffer;

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        let channel = self.channels.channel_mut(self.index);
        self.index += 1;
        return channel;
    }
}
*/
