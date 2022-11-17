use crate::dsp::*;

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
    type Item = f32;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    #[inline]
    fn gen(&mut self) -> f32 {
        self.rng.sample(Uniform::new(-1.0, 1.0))
    }
}

pub struct Lfo {
    f: fn(f32) -> f32,
    phase: f32,
    hz: f32,
    rate: u32,
}

impl Lfo {
    pub fn from(f: fn(f32) -> f32) -> Self {
        Self {
            f,
            phase: 0.0,
            hz: 440.0,
            rate: 44100,
        }
    }
}

impl Generator for Lfo {
    type Item = f32;

    fn reset(&mut self) {
        self.phase = 0.0;
    }

    fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
        self.rate = sample_rate;
    }

    fn gen(&mut self) -> Self::Item {
        let phase = self.phase;
        let delta = (1.0 / self.rate as f32) * self.hz;

        self.phase += delta;

        (self.f)(phase)
    }
}

impl Pitched for Lfo {
    fn get_pitch(&self) -> f32 {
        self.hz
    }

    fn set_pitch(&mut self, hz: f32) {
        self.hz = hz;
    }
}
