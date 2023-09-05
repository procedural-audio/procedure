use std::ops::{Deref, DerefMut};

use pa_dsp::Generator;

pub const fn player<G: Generator>(dsp: G) -> Player<G> {
    Player::from(dsp)
}

pub struct Player<G: Generator> {
    dsp: G,
    active: bool
}

impl<G: Generator> Player<G> {
    pub const fn from(dsp: G) -> Self {
        Player {
            dsp,
            active: false
        }
    }

    pub fn play(&mut self) {
        self.active = true;
    }

    pub fn stop(&mut self) {
        self.active = false;
    }
}

impl<G: Generator> Generator for Player<G> where G::Output: Default {
    type Output = G::Output;

    fn reset(&mut self) {
        self.dsp.reset();
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        self.dsp.prepare(sample_rate, block_size);
    }

    fn generate(&mut self) -> Self::Output {
        if self.active {
            self.dsp.generate()
        } else {
            G::Output::default()
        }
    }
}

impl<G: Generator> Deref for Player<G> {
    type Target = G;

    fn deref(&self) -> &Self::Target {
        &self.dsp
    }
}

impl<G: Generator> DerefMut for Player<G> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.dsp
    }
}
