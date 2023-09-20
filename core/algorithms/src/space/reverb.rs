use pa_dsp::*;

fn test() {

}

pub struct AllPass<S: Sample> {
    v: S
}

pub struct Delay<S: Sample> {
    value: S
}

impl<S: Sample> Delay<S> {
    pub fn new() -> Self {
        Self {
            value: S::EQUILIBRIUM
        }
    }
}

pub struct Feedback<S: Sample, const C: usize> {
    delay_ms: S::Float,
    decay_gain: S::Float,
    delay_samples: [S; C],
    delay: Delay<S>,
}

impl<S: Sample, const C: usize> Feedback<S, C> {
    pub fn new() -> Self {
        Self {
            delay_ms: S::Float::from(80.0),
            decay_gain: S::Float::from(0.85),
            delay_samples: [S::EQUILIBRIUM; C],
            delay: Delay::new(),
        }
    }
}

impl<S: Sample, const C: usize> Processor for Feedback<S, C> {
    type Input = S;
    type Output = S;

    fn reset(&mut self) {
        // *self = Self::new()
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        let delay_samples_base = self.delay_ms * S::Float::from(0.001) * S::Float::from_usize(sample_rate as usize);
        for i in 0..C {
            let r = S::Float::from(i as f32 * (1.0 / C as f32));
            self.delay_samples[i] = S::from(S::Float::powf(S::Float::from(2.0), r) * delay_samples_base);

            // self.delays[i].resize(self.delay_samples[i] + 1);
            // self.delays[i].reset();
        }
    }

    fn process(&mut self, input: Self::Input) -> Self::Output {
        todo!()
    }
}