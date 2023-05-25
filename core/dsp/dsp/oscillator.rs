use crate::dsp::*;
use crate::Processor2;

use rand::distributions::Uniform;
use rand::prelude::ThreadRng;
use rand::Rng;

pub struct Noise {
    rng: ThreadRng,
}

impl Default for Noise {
    fn default() -> Self {
        Self {
            rng: rand::thread_rng(),
        }
    }
}

impl Generator for Noise {
    type Output = f32;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    #[inline]
    fn gen(&mut self) -> f32 {
        self.rng.sample(Uniform::new(-1.0, 1.0))
    }
}

pub struct Lfo {
    shape: fn(f32) -> f32,
    pitch: f32,
    phase: f32,
    rate: u32,
}

impl Lfo {
    pub fn from(shape: fn(f32) -> f32, pitch: f32) -> Self {
        Self {
            shape,
            pitch,
            phase: 0.0,
            rate: 44100,
        }
    }
}

impl Generator for Lfo {
    type Output = f32;

    fn reset(&mut self) {
        self.phase = 0.0;
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        self.rate = sample_rate;
    }

    fn gen(&mut self) -> Self::Output {
        let phase = self.phase;
        let delta = (1.0 / self.rate as f32) * self.pitch.gen();
        self.phase += delta;
        (self.shape)(phase)
    }
}

/*impl<F: Fn(f32) -> f32> Processor2 for F {
    type Input = f32;
    type Output = f32;

    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, input: Self::Input) -> Self::Output {
        self(input)
    }
}*/

impl Pitched for Lfo {
    fn get_pitch(&self) -> f32 {
        self.pitch
    }

    fn set_pitch(&mut self, hz: f32) {
        self.pitch = hz;
    }
}
