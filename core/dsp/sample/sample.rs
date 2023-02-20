use crate::buffers::*;

use std::sync::Arc;

pub use crate::cache::FileLoad;
use crate::Generator;
use crate::Pitched;
use std::ops::{Deref, DerefMut};

#[derive(Clone)]
pub struct SampleFile<T: Frame> {
    buffer: Arc<Buffer<T>>,
    path: String,
    pub start: usize,
    pub end: usize,
    pub pitch: Option<f32>
}

impl<T: Frame> SampleFile<T> {
    pub fn from(buffer: Arc<Buffer<T>>, pitch: Option<f32>, sample_rate: u32, path: String) -> Self {
        let start = 0;
        let end = buffer.len();

        return Self {
            buffer,
            start,
            end,
            path,
            pitch,
        };
    }

    pub fn path(&self) -> &str {
        &self.path
    }

    pub fn as_slice(&self) -> &[T] {
        self.buffer.as_slice()
    }

    pub fn len(&self) -> usize {
        self.buffer.len()
    }
}

/*impl<T: Frame> Playable for SampleFile<T> {
    type Player = SamplePlayer<T>;

    fn player(self) -> Self::Player {
        SamplePlayer::new()
    }
}*/

/*impl<T: Frame> Player for SamplePlayer<T> {
    fn play(&mut self) {
        self.playing = true;
    }

    fn pause(&mut self) {
        self.playing = false;
    }

    fn stop(&mut self) {
        self.playing = false;
        self.index = 0;
    }
}*/

/*impl<T: Frame> Generator for SamplePlayer<T> {
    type Item = T;

    fn reset(&mut self) {
        todo!()
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        todo!()
    }

    fn gen(&mut self) -> Self::Item {
        
    }
}*/

pub struct Converter<G: Generator, I: Interpolator<Item = G::Item>> {
    src: G,
    interpolator: I,
    interpolation_value: f32,
    ratio: f32
}

impl<G: Generator, I: Interpolator<Item = G::Item>> Converter<G, I> {
    pub fn from(src: G) -> Self {
        Self {
            src,
            interpolator: I::new(),
            interpolation_value: 0.0,
            ratio: 1.0
        }
    }

    pub fn set_ratio(&mut self, ratio: f32) {
        self.ratio = ratio;
    }
}

impl<G: Generator, I: Interpolator<Item = G::Item>> Generator for Converter<G, I> {
    type Item = G::Item;

    fn reset(&mut self) {
        self.interpolator.reset();
        self.src.reset();
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        self.src.prepare(sample_rate, block_size);
    }

    fn gen(&mut self) -> Self::Item {
        while self.interpolation_value >= 1.0 {
            self.interpolator.next_sample(self.src.gen());
            self.interpolation_value -= 1.0;
        }

        let out = self.interpolator.interpolate(self.interpolation_value);
        self.interpolation_value += self.ratio;
        return out;
    }
}

impl<G: Generator, I: Interpolator<Item = G::Item>> std::ops::Deref for Converter<G, I> {
    type Target = G;

    fn deref(&self) -> &Self::Target {
        &self.src
    }
}

impl<G: Generator, I: Interpolator<Item = G::Item>> std::ops::DerefMut for Converter<G, I> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.src
    }
}

pub trait Interpolator {
    type Item;

    fn new() -> Self;
    fn reset(&mut self);
    fn next_sample(&mut self, input: Self::Item);
    fn interpolate(&self, x: f32) -> Self::Item;
}

pub struct Linear<T: Frame> {
    last: T,
    prev: T
}

impl<T: Frame> Interpolator for Linear<T> {
    type Item = T;

    fn new() -> Self {
        Self {
            last: T::from(0.0),
            prev: T::from(0.0)
        }
    }

    fn reset(&mut self) {
        self.last = Self::Item::from(0.0);
        self.prev = Self::Item::from(0.0);
    }

    fn next_sample(&mut self, input: Self::Item) {
        self.last = self.prev;
        self.prev = input;
    }

    fn interpolate(&self, x: f32) -> Self::Item {
        // println!("Interpolation x {}", x);
        ((self.prev - self.last) * Self::Item::from(x)) + self.last
    }
}

/* ===== Sample Voice ===== */

// pub type PitchedSamplePlayer<T> = Converter<SamplePlayer<T>, Linear<T>>;

/*pub struct Pitcher<G: Generator<Item = Stereo2>> {
    base_pitch: f32,
    playing_pitch: f32,
    src: Converter<G, Linear<G::Item>>
}

impl<G: Generator<Item = Stereo2>> Pitcher<G> {
    pub fn set_pitch(&mut self, hz: f32) {
        self.playing_pitch = hz;
        self.src.set_ratio(self.playing_pitch / self.base_pitch);
    }

    pub fn set_source_pitch(&mut self, hz: f32) {
        self.base_pitch = hz;
        self.src.set_ratio(self.playing_pitch / self.base_pitch);
    }
}

impl<G: Generator<Item = Stereo2>> Generator for Pitcher<G> {
    type Item = G::Item;

    fn reset(&mut self) {
        self.src.reset()
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        self.src.prepare(sample_rate, block_size)
    }

    fn gen(&mut self) -> Self::Item {
        self.src.gen()
    }
}*/

pub struct SamplePlayer<T: Frame> {
    sample: Option<SampleFile<T>>,
    playing: bool,
    index: usize,
    sample_rate: u32
}

impl<T: Frame> SamplePlayer<T> {
    pub fn new() -> Self {
        Self {
            sample: None,
            playing: false,
            index: 0,
            sample_rate: 44100
        }
    }

    pub fn set_sample(&mut self, sample: SampleFile<T>) {
        self.index = sample.start;
        self.sample = Some(sample);
    }

    pub fn position(&self) -> usize {
        match &self.sample {
            Some(sample) => self.index - sample.start,
            None => self.index
        }
    }

    pub fn set_position(&mut self, position: usize) {
        match &self.sample {
            Some(sample) => self.index = position + sample.start,
            None => self.index = position
        }
    }

    pub fn progress(&self) -> f32 {
        match &self.sample {
            Some(sample) => {
                (self.index - sample.start) as f32 / (sample.end - sample.start) as f32
            },
            None => {
                0.0
            }
        }
    }

    /*pub fn play_length(&self) -> usize {
        match &self.sample {
            Some(sample) => sample.end - sample.start,
            None => 0
        }
    }*/

    pub fn playing(&self) -> bool {
        self.playing
    }

    /*pub fn set_time(&mut self, time: TimeRange) {
        time.start
    }*/

    pub fn play(&mut self) {
        self.playing = true;
    }

    pub fn pause(&mut self) {
        self.playing = false;
    }

    pub fn stop(&mut self) {
        self.playing = false;

        match &self.sample {
            Some(sample) => self.index = sample.start,
            None => self.index = 0
        }
    }
}

impl<T: Frame> Generator for SamplePlayer<T> {
    type Item = T;

    fn reset(&mut self) {}

    fn prepare(&mut self, sample_rate: u32, _: usize) {
        self.sample_rate = sample_rate;
    }

    fn gen(&mut self) -> Self::Item {
        if self.playing {
            if let Some(sample) = &self.sample {
                if self.index < sample.end {
                    self.index += 1;
                    return sample.buffer[self.index - 1];
                }
            }
        }

        Self::Item::from(0.0)
    }

    fn generate_block(&mut self, output: &mut Buffer<T>) {
        if self.playing {
            if let Some(sample) = &self.sample {
                if self.index + output.len() < sample.end {
                    let end = self.index + output.len();
                    for (buf, out) in sample.buffer.as_slice()[self.index..end].iter().zip(&mut output.into_iter()) {
                        *out = *buf;
                    }

                    self.index += output.len();
                }
            }
        }
    }
}

pub struct PitchedSamplePlayer<S: Frame> {
    pub player: Converter<SamplePlayer<S>, Linear<S>>,
    pitch: f32
}

impl<T: Frame> PitchedSamplePlayer<T> {
    pub fn new() -> Self {
        let player = Converter::from(SamplePlayer::new());
        
        Self {
            player,
            pitch: 440.0
        }
    }

    pub fn set_speed(&mut self, speed: f32) {
        self.player.set_ratio(speed);
    }
}

impl<T: Frame> Generator for PitchedSamplePlayer<T> {
    type Item = T;

    fn reset(&mut self) {}

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        self.player.prepare(sample_rate, block_size);
    }

    fn gen(&mut self) -> Self::Item {
        self.player.gen()
    }

    fn generate_block(&mut self, output: &mut Buffer<T>) {
        self.player.generate_block(output);
    }
}

impl<T: Frame> Pitched for PitchedSamplePlayer<T> {
    fn get_pitch(&self) -> f32 {
        self.pitch
    }

    fn set_pitch(&mut self, hz: f32) {
        match &self.sample {
            Some(sample) => {
                match sample.pitch {
                    Some(pitch) => self.player.set_ratio(hz / pitch),
                    None => self.player.set_ratio(1.0)
                }
            }
            None => ()
        }
    }
}

impl<T: Frame> Deref for PitchedSamplePlayer<T> {
    type Target = SamplePlayer<T>;

    fn deref(&self) -> &Self::Target {
        self.player.deref()
    }
}

impl<T: Frame> DerefMut for PitchedSamplePlayer<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        self.player.deref_mut()
    }
}
