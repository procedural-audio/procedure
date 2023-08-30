use crate::traits::*;

pub struct Player<G: Generator> {
    source: G,
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

    fn generate(&mut self) -> Self::Output {
        self.source.generate()
    }
}
