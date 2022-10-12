use crate::buffers::audio::channels::*;

pub struct AudioBus<T: AudioChannels> {
    blocks: *mut T,
    channels: usize,
    size: usize,
    owned: bool,
}

impl<T: AudioChannels> AudioBus<T> {
    pub fn new(channels: usize, size: usize) -> Self {
        unsafe {
            let mut blocks = Vec::new();

            for _ in 0..channels {
                let mut buffer = T::new(size);
                buffer.forget();

                blocks.push(buffer);
            }

            let blocks_ptr: *mut T = blocks.as_mut_ptr();

            std::mem::forget(blocks);

            Self {
                blocks: blocks_ptr,
                channels,
                size,
                owned: true,
            }
        }
    }

    pub fn channels(&self) -> usize {
        self.channels
    }

    pub fn get_channel(&self, channel: usize) -> Option<&T> {
        if channel < self.channels {
            unsafe { Some(&*self.blocks.offset(channel as isize)) }
        } else {
            None
        }
    }

    pub fn get_channel_mut(&mut self, channel: usize) -> Option<&mut T> {
        if channel < self.channels {
            unsafe { Some(&mut *self.blocks.offset(channel as isize)) }
        } else {
            None
        }
    }

    pub fn iter(&self) -> BusChannelIter<'_, T> {
        unsafe { BusChannelIter::new(std::slice::from_raw_parts(self.blocks, self.channels)) }
    }

    pub fn iter_mut(&mut self) -> BusChannelIterMut<'_, T> {
        unsafe {
            BusChannelIterMut::new(std::slice::from_raw_parts_mut(self.blocks, self.channels))
        }
    }

    pub fn unowned(&self) -> AudioBus<T> {
        AudioBus {
            blocks: self.blocks,
            channels: self.channels,
            size: self.size,
            owned: false,
        }
    }

    pub unsafe fn forget(&mut self) {
        self.owned = false;
    }
}

//unsafe impl Send for AudioBus {}
//unsafe impl Sync for AudioBus {}

impl<T: AudioChannels> Drop for AudioBus<T> {
    fn drop(&mut self) {
        unsafe {
            if self.owned {
                let _ = Vec::from_raw_parts(self.blocks, self.channels, self.channels);
            }
        }
    }
}

impl<'a, T: AudioChannels> IntoIterator for &'a AudioBus<T> {
    type IntoIter = BusChannelIter<'a, T>;
    type Item = <Self::IntoIter as Iterator>::Item;

    fn into_iter(self) -> Self::IntoIter {
        self.iter()
    }
}

impl<'a, T: AudioChannels> IntoIterator for &'a mut AudioBus<T> {
    type IntoIter = BusChannelIterMut<'a, T>;
    type Item = <Self::IntoIter as Iterator>::Item;

    fn into_iter(self) -> Self::IntoIter {
        self.iter_mut()
    }
}

impl<T: AudioChannels> std::ops::Index<usize> for AudioBus<T> {
    type Output = T;

    fn index(&self, index: usize) -> &Self::Output {
        match self.get_channel(index) {
            Some(channel) => channel,
            None => panic!("index `{}` is not a channel", index),
        }
    }
}

impl<T: AudioChannels> std::ops::IndexMut<usize> for AudioBus<T> {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        match self.get_channel_mut(index) {
            Some(channel) => channel,
            None => panic!("index `{}` is not a channel", index),
        }
    }
}

pub struct BusChannelIter<'a, T: AudioChannels> {
    iter: std::slice::Iter<'a, T>,
}

impl<'a, T: AudioChannels> BusChannelIter<'a, T> {
    #[inline]
    pub(super) unsafe fn new(data: &'a [T]) -> Self {
        Self { iter: data.iter() }
    }
}

impl<'a, T: AudioChannels> Iterator for BusChannelIter<'a, T> {
    type Item = &'a T;

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        Some(self.iter.next()?)
    }
}

pub struct BusChannelIterMut<'a, T: AudioChannels> {
    iter: std::slice::IterMut<'a, T>,
}

impl<'a, T: AudioChannels> BusChannelIterMut<'a, T> {
    #[inline]
    pub(super) unsafe fn new(data: &'a mut [T]) -> Self {
        Self {
            iter: data.iter_mut(),
        }
    }
}

impl<'a, T: AudioChannels> Iterator for BusChannelIterMut<'a, T> {
    type Item = &'a mut T;

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        Some(self.iter.next()?)
    }
}
