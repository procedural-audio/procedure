use std::ops::Deref;
use std::ops::DerefMut;

pub mod dynamics;
mod envelopes;
mod oscillator;
mod wavetable;
mod interpolators;

pub use dynamics::*;
pub use envelopes::*;
pub use oscillator::*;
pub use wavetable::*;

use crate::Block;
use crate::BlockMut;
use crate::buffers::Buffer;

use crate::Frame;

/*

Implement like https://github.com/RustAudio/dasp/blob/master/dasp_signal/src/lib.rs

Processor
 - Basic: amp(f32)
 - Intermediate: apply(| s | { s * 2.0 })
 - Advanced: convolve(T)
 - Iterator: take(), collect(), rev() (try not to need to re-implement these)
 - Sources: Oscillator<T>, Sine, Saw, Square, Triangle
 - Converters: rate(f32)
 - Analysis: rms()
*/

/* ========== Test Function ========== */

/*fn test() {
    let mut buffer = Buffer::<f32>::new(512);

    let mut stack: Amplifier<Clipper<Noise>> = Amplifier::default();

    stack.gen();
    stack.gen();
    stack.gen();

    stack.set_gain(-3.0);
    stack.set_clip(3.0);

    buffer.fill(stack);

    let mut effects: Amplifier<Clipper<Source>> = Amplifier::default();
    effects.process(0.5);

    /*for s in &mut buffer {
        *s = amp(*s, 3.0);
    }*/

    /*
    buffer.fill(0.0)
    buffer.fill(&mut stack);

    buffer += self.oscillator.amp(6.0).clip(0.0);

    */

    /*let wavetable = Wavetable::generate(f32::sin);
    let stack = wavetable.gain(10.0).clip(1.0);*/

    //buffer.copy_from(stack.take(512));
}*/

/*
use std::ops::Add;
use std::ops::Sub;
use std::ops::Mul;
use std::ops::Div;
use std::ops::Neg;

pub trait Frame: Copy + Clone + PartialEq + Add + Sub + Mul + Div + Neg {
    const Channels: usize;
}

impl Frame for f32 {
    const Channels: usize = 1;
}
*/

pub trait Generator {
    type Output;

    fn reset(&mut self);
    fn prepare(&mut self, sample_rate: u32, block_size: usize);
    fn gen(&mut self) -> Self::Output;
}

pub trait Processor {
    type Item: Clone + Copy;

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {}

    fn process(&mut self, input: Self::Item) -> Self::Item;

    fn process_block(&mut self, input: &Buffer<Self::Item>, output: &mut Buffer<Self::Item>) {
        for (dest, src) in output.as_slice_mut().iter_mut().zip(input.as_slice()) {
            *dest = self.process(*src);
        }
    }

    /*#[inline]
    fn clip(self, db: f32) -> Clipper<Self> where Self: Sized {
        Clipper {
            src: self,
            db
        }
    }

    #[inline]
    fn gain(self, db: f32) -> Amplifier<Self> where Self: Sized {
        Amplifier {
            src: self,
            db
        }
    }*/
}

/*pub trait Playable {
    fn player<T: Generator>(&self) -> Player<T>;
}

impl<T: Generator> Playable for T {
    fn player(&self) -> Player<T> {
        Player {

        }
    }
}*/

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

    fn gen(&mut self) -> Self::Output {
        self.source.gen()
    }

    /*fn generate_block(&mut self, output: &mut Buffer<Self::Output>) {
        self.source.generate_block(output);
    }*/
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

    fn gen(&mut self) -> Self::Output {
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

/* ========== Pitch ========== */

pub trait Pitched: Generator {
    fn get_pitch(&self) -> f32;
    fn set_pitch(&mut self, hz: f32);
    fn pitch(self, hz: f32) -> Pitch<Self>
    where
        Self: Sized,
    {
        Pitch { src: self, hz }
    }
}

pub struct Pitch<T: Generator + Pitched> {
    pub src: T,
    pub hz: f32,
}

impl<T: Generator + Pitched + Default> Default for Pitch<T> {
    fn default() -> Self {
        Self {
            src: T::default(),
            hz: 100.0,
        }
    }
}

impl<T: Generator + Pitched> Generator for Pitch<T> {
    type Output = T::Output;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn gen(&mut self) -> Self::Output{
        self.src.gen()
    }
}

impl<T: Processor + Pitched> Deref for Pitch<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.src
    }
}

impl<T: Processor + Pitched> DerefMut for Pitch<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.src
    }
}

/* ========== Closure ========== */

/* ========== Generator Implementations ========== */

/*impl<I: Default, T: Processor<Item = I>> Generator for T {
    type Item = I;

    fn gen(&mut self) -> Self::Item {
        self.process(I::default())
    }
}*/

/*impl<'a, T: Generator> Generator for &'a mut T {
    type Item = T::Item;

    fn gen(&mut self) -> Self::Item {
        self.deref_mut().gen()
    }
}*/

/*impl<'a, T: Processor> Processor for &'a mut T {
    type Item = T::Item;

    fn process(&mut self, src: Self::Item) -> Self::Item {
        self.deref_mut().process(src)
    }
}*/

impl Generator for f32 {
    type Output = f32;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    #[inline]
    fn gen(&mut self) -> f32 {
        *self
    }
}
