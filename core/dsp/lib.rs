pub mod buffers;
pub mod dsp;
pub mod math;
pub mod sample;
pub mod voice;
pub mod loadable;

pub use crate::buffers::*;
pub use crate::math::*;
pub use crate::sample::*;

pub use buffers::*;
pub use dsp::*;

extern crate lazy_static;

/* DSP Traits */

/*

Buffer Tree
 - Buffer (copy_from, add_from). Self::Element type.
 - AudioBuffer, AudioBufferMut, EventsBuffer, EventsBufferMut, ControlBuffer, ControlBufferMut
 - AudioProcessor
 - Source, Effect, Sink
 - AudioSource, AudioEffect, AudioSink

Set of simple user types, set of abstract backend types

*/

pub trait Voice: Source {
    fn play(&mut self);
    fn note_on(&mut self, id: Id, offset: u16, note: NoteMessage, pressure: f32);
    fn note_off(&mut self);

    fn set_pitch(&mut self, freq: f32);
    fn set_pressure(&mut self, pressure: f32);

    fn position(&self) -> usize;

    fn is_active(&self) -> bool;
    fn id(&self) -> Id;
}

pub trait Source {
    type Output;

    fn new() -> Self;
    fn reset(&mut self);
    fn prepare(&mut self, sample_rate: u32, block_size: usize);
    fn process(&mut self, output: &mut Self::Output);
}

pub trait Effect {
    type Input;
    type Output;

    fn new() -> Self;
    fn reset(&mut self);
    fn prepare(&mut self, sample_rate: u32, block_size: usize);
    fn process(&mut self, input: &Self::Input, output: &mut Self::Output);
}

pub trait Sink {
    type Input;

    fn new() -> Self;
    fn reset(&mut self);
    fn prepare(&mut self, sample_rate: u32, block_size: usize);
    fn process(&mut self, output: &Self::Input);
}

/* DSP Structs */

/*pub struct ADSR<T: Source> {
    pub source: T,
    index: usize,
    sample_rate: u32,
    attack: Duration,
    decay: Duration,
    sustain: f32,
    release: Duration,
}

impl<T: Source> ADSR<T> {
    pub fn set_attack(&mut self, duration: Duration) {
        self.attack = duration;
    }

    pub fn set_decay(&mut self, duration: Duration) {
        self.decay = duration;
    }

    pub fn set_sustain(&mut self, sustain: f32) {
        self.sustain = sustain;
    }

    pub fn set_release(&mut self, duration: Duration) {
        self.release = duration;
    }
}

impl<T: Source> Source for ADSR<T> {
    type Output = <T as Source>::Output;

    fn new() -> Self {
        Self {
            source: T::new(),
            index: 0,
            sample_rate: 0,
            attack: Duration::from_millis(0),
            decay: Duration::from_millis(0),
            sustain: 1.0,
            release: Duration::from_millis(0),
        }
    }

    fn reset(&mut self) {
        self.index = 0;
    }

    fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
        self.sample_rate = sample_rate;
    }

    fn process(&mut self, output: &mut Self::Output) {
        self.source.process(output);
    }
}*/

/* Other */

#[derive(Clone, PartialEq)]
pub struct SoundRegion<T> {
    pub low_note: u32,
    pub high_note: u32,
    pub low_velocity: f32,
    pub high_velocity: f32,
    pub sounds: Vec<T>,
    pub index: usize,
}

/*

 - Buffer, BufferMut traits
 - AudioBuffer, AudioBufferMut traits
 - NoteBuffer, NoteBufferMut traits
 - AudioBuffer, Mono, Stereo, and Surround types
 - AudioChannel<C>, AudioChannelMut<C> trait
 - Sound trait
   - Implement prepare, process, reset
 - Voice: Sound trait
   - Implement note_on, note_off, etc
 - Sequencer trait
 - ADSR<T: Voice> type
 - Oversample<T: Sound, C> type

*/
