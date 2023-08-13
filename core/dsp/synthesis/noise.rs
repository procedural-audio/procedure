use rand::distributions::Uniform;
use rand::prelude::ThreadRng;
use rand::Rng;

use crate::traits::*;

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
    fn generate(&mut self) -> f32 {
        self.rng.sample(Uniform::new(-1.0, 1.0))
    }
}
