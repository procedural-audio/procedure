use pa_dsp::*;

pub const fn clip<S: Sample>(max: S::Float) -> AudioNode<Clip<S>> {
    AudioNode(Clip(max))
}

pub struct Clip<S: Sample>(S::Float);

impl<S: Sample> Clip<S> {
    pub fn from(max: S::Float) -> Clip<S> {
        Clip(max)
    }
}

impl<S: Sample> Processor for Clip<S> {
    type Input = S;
    type Output = S;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, input: Self::Input) -> Self::Output {
        input.apply(
            | v | {
                if v > self.0 {
                    self.0
                } else {
                    v
                }
            }
        )
    }
}
