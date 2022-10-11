use std::ops::Deref;
use std::ops::DerefMut;

mod dynamics;
mod envelopes;
mod oscillator;
mod wavetable;

pub use dynamics::*;
pub use envelopes::*;
pub use oscillator::*;
pub use wavetable::*;

use crate::buffers::*;

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

fn test() {
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
}

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
    type Item;

    fn reset(&mut self);
    fn prepare(&mut self, sample_rate: u32, block_size: usize);
    fn gen(&mut self) -> Self::Item;
}

pub trait Processor {
    type Item;

    fn process(&mut self, v: Self::Item) -> Self::Item;

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

pub struct GeneratorIterator {}

pub trait Player: Generator {
    fn play(&mut self);
    fn pause(&mut self);
    fn stop(&mut self);
}

pub trait Playable {
    type Player: Generator;

    fn player(self) -> Self::Player;
    // fn at(sample: usize) -> f32;
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
    type Item = T::Item;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn gen(&mut self) -> Self::Item {
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
    type Item = f32;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    #[inline]
    fn gen(&mut self) -> f32 {
        *self
    }
}
