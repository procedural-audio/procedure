use std::ops::{Deref, DerefMut};

use pa_dsp::{Generator, Sample, Block, NoteMessage, BlockProcessor, BlockGenerator};

pub trait Playable {
    fn play(&mut self);
    fn stop(&mut self);
}

pub const fn player<G: Generator>(dsp: G) -> Player<G> {
    Player::from(dsp)
}

pub struct Player<G: Generator> {
    dsp: G,
    active: bool
}

impl<G: Generator> Playable for Player<G> {
    fn play(&mut self) {
        self.active = true;
    }

    fn stop(&mut self) {
        self.active = false;
    }
}

impl<G: Generator> Player<G> {
    pub const fn from(dsp: G) -> Self {
        Player {
            dsp,
            active: false
        }
    }
}

impl<G: Generator> Generator for Player<G> where G::Output: Sample {
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
            G::Output::EQUILIBRIUM
        }
    }
}

impl<G: Generator> BlockProcessor for Player<G> {
    type Input = NoteMessage;
    type Output = G::Output;

    fn process_block<InBuffer, OutBuffer>(&mut self, input: &InBuffer, output: &mut OutBuffer)
        where
            InBuffer: Block<Item = Self::Input>,
            OutBuffer: Block<Item = Self::Output> {
        
        for msg in input.as_slice() {
            match msg.note {
                crate::Event::NoteOn { pitch: _, pressure: _ } => {
                    self.play();
                },
                crate::Event::NoteOff => {
                    self.stop();
                },
                crate::Event::Pitch(_hz) => {},
                crate::Event::Pressure(_) => (),
                crate::Event::Other(_, _) => (),
            }
        }

        self.generate_block(output);
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