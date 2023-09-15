use std::ops::{Deref, DerefMut};

use pa_dsp::{Generator, Sample, Block, NoteMessage, BlockProcessor, BlockMut, BlockGenerator, Pitched, Event};

use crate::Playable;

pub const fn pitched_player<G: Generator + Pitched>(dsp: G) -> PitchedPlayer<G> {
    PitchedPlayer::from(dsp)
}

pub struct PitchedPlayer<G: Generator + Pitched> {
    dsp: G,
    active: bool
}

impl<G: Generator + Pitched> Playable for PitchedPlayer<G> {
    fn play(&mut self) {
        self.active = true;
    }

    fn stop(&mut self) {
        self.active = false;
    }
}

impl<G: Generator + Pitched> PitchedPlayer<G> {
    pub const fn from(dsp: G) -> Self {
        PitchedPlayer {
            dsp,
            active: false
        }
    }
}

impl<G: Generator + Pitched> Generator for PitchedPlayer<G> where G::Output: Sample {
    type Output = G::Output;

    fn reset(&mut self) {
        self.active = false;
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

impl<G: Generator + Pitched> BlockProcessor for PitchedPlayer<G> {
    type Input = NoteMessage;
    type Output = G::Output;

    fn process_block<InBuffer, OutBuffer>(&mut self, input: &InBuffer, output: &mut OutBuffer)
        where
            InBuffer: Block<Item = Self::Input>,
            OutBuffer: BlockMut<Item = Self::Output> {
        
        for msg in input.as_slice() {
            match msg.note {
                Event::NoteOn { pitch, pressure: _ } => {
                    self.set_pitch(pitch);
                    self.play();
                },
                Event::NoteOff => {
                    self.stop();
                },
                Event::Pitch(hz) => {
                    self.set_pitch(hz);
                },
                Event::Pressure(_) => (),
                Event::Other(_, _) => (),
            }
        }

        self.generate_block(output);
    }
}

impl<G: Generator + Pitched> Deref for PitchedPlayer<G> {
    type Target = G;

    fn deref(&self) -> &Self::Target {
        &self.dsp
    }
}

impl<G: Generator + Pitched> DerefMut for PitchedPlayer<G> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.dsp
    }
}