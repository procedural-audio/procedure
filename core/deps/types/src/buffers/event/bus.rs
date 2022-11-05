use crate::buffers::event::buffer::*;

/*pub struct NotesBus {
    pub buffers: *mut NoteBuffer,
    pub channels: usize,
    owned: bool,
}

impl NotesBus {
    pub fn new(channels: usize, size: usize) -> Self {
        let mut buffers = Vec::new();

        for _ in 0..channels {
            let mut buffer = NoteBuffer::new(size);
            buffer.forget();
            buffers.push(buffer);
        }

        let buffers_ptr = buffers.as_mut_ptr();

        std::mem::forget(buffers);

        Self {
            buffers: buffers_ptr,
            channels,
            owned: true,
        }
    }

    pub fn channels(&self) -> usize {
        self.channels
    }

    pub fn get_channel(&self, channel: usize) -> Option<&NoteBuffer> {
        if channel < self.channels {
            unsafe { Some(&*self.buffers.offset(channel as isize)) }
        } else {
            None
        }
    }

    pub fn get_channel_mut(&self, channel: usize) -> Option<&mut NoteBuffer> {
        if channel < self.channels {
            unsafe { Some(&mut *self.buffers.offset(channel as isize)) }
        } else {
            None
        }
    }

    pub fn iter(&self) -> ChannelIter<'_> {
        unsafe { ChannelIter::new(std::slice::from_raw_parts(self.buffers, self.channels)) }
    }

    pub fn iter_mut(&mut self) -> ChannelIterMut<'_> {
        unsafe { ChannelIterMut::new(std::slice::from_raw_parts_mut(self.buffers, self.channels)) }
    }

    pub fn as_ref(&self) -> &[NoteBuffer] {
        unsafe { std::slice::from_raw_parts(self.buffers, self.channels) }
    }

    pub fn as_mut(&mut self) -> &mut [NoteBuffer] {
        unsafe { std::slice::from_raw_parts_mut(self.buffers, self.channels) }
    }

    pub fn unowned(&self) -> NotesBus {
        NotesBus {
            buffers: self.buffers,
            channels: self.channels,
            owned: false,
        }
    }
}

impl Drop for NotesBus {
    fn drop(&mut self) {
        unsafe {
            if self.owned {
                let _ = Vec::from_raw_parts(self.buffers, 0, self.channels);
            }
        }
    }
}

impl<'a> IntoIterator for &'a NotesBus {
    type IntoIter = ChannelIter<'a>;
    type Item = <Self::IntoIter as Iterator>::Item;

    fn into_iter(self) -> Self::IntoIter {
        self.iter()
    }
}

impl<'a> IntoIterator for &'a mut NotesBus {
    type IntoIter = ChannelIterMut<'a>;
    type Item = <Self::IntoIter as Iterator>::Item;

    fn into_iter(self) -> Self::IntoIter {
        self.iter_mut()
    }
}

pub struct ChannelIter<'a> {
    iter: std::slice::Iter<'a, NoteBuffer>,
}

impl<'a> ChannelIter<'a> {
    #[inline]
    pub(super) unsafe fn new(data: &'a [NoteBuffer]) -> Self {
        Self { iter: data.iter() }
    }
}

impl<'a> Iterator for ChannelIter<'a> {
    type Item = &'a NoteBuffer;

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        Some(self.iter.next()?)
    }
}

pub struct ChannelIterMut<'a> {
    iter: std::slice::IterMut<'a, NoteBuffer>,
}

impl<'a> ChannelIterMut<'a> {
    #[inline]
    pub(super) unsafe fn new(data: &'a mut [NoteBuffer]) -> Self {
        Self {
            iter: data.iter_mut(),
        }
    }
}

impl<'a> Iterator for ChannelIterMut<'a> {
    type Item = &'a mut NoteBuffer;

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        Some(self.iter.next()?)
    }
}

impl std::ops::Index<usize> for NotesBus {
    type Output = NoteBuffer;

    fn index(&self, index: usize) -> &Self::Output {
        match self.get_channel(index) {
            Some(channel) => channel,
            None => panic!("index `{}` is not a channel", index),
        }
    }
}

impl std::ops::IndexMut<usize> for NotesBus {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        match self.get_channel_mut(index) {
            Some(channel) => channel,
            None => panic!("index `{}` is not a channel", index),
        }
    }
}
*/