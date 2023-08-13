use crate::traits::*;
use crate::buffers::*;
use crate::float::*;

pub struct Player<T> {
    source: T,
    playing: bool
}

impl<T: Generator> Player<T> {
    pub fn from(source: T) -> Self {
        Player {
            source,
            playing: false
        }
    }

    pub fn play(&mut self) {
        self.playing = true;
    }

    pub fn pause(&mut self) {
        self.playing = false;
    }

    pub fn stop(&mut self) {
        self.source.reset();
        self.playing = false;
    }
}

impl<T: Generator> Generator for Player<T> {
    type Output = T::Output;

    fn reset(&mut self) {
        self.source.reset();
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        self.source.prepare(sample_rate, block_size);
    }

    fn generate(&mut self) -> Self::Output {
        self.source.generate()
    }
}

pub struct Playhead<T: Frame> {
    index: usize,
    src: Buffer<T>
} // impl this for all generators also?

impl<T: Frame> Playhead<T> {
    // Add transport methods here???    
}

impl<T: Frame> Generator for Playhead<T> {
    type Output = T;

    fn reset(&mut self) {
        self.index = 0;
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {}

    fn generate(&mut self) -> Self::Output {
        let item = self.src[self.index];
        self.index += 1;
        return item;
    }

    /*fn generate_block(&mut self, output: &mut Buffer<Self::Output>) {
        if self.index + output.len() < self.src.len() {
            let end = usize::min(self.index + output.len(), self.src.len());
            for (buf, out) in self.src.into_iter().zip(&mut output.as_slice_mut()[self.index..end]) {
                *out = *buf;
            }
        } // WON'T GET LAST BLOCK OF THE SAMPLE
    }*/
}
