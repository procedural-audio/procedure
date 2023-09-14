use pa_dsp::*;

pub const fn apply<S: Sample>(max: S) -> AudioNode<Apply<S>> {
    AudioNode(Apply(max))
}

pub struct Apply<S: Sample>(S);

impl<S: Sample> Apply<S> {
    pub fn from(max: S) -> Self {
        Self(max)
    }
}

impl<S: Sample> Processor for Apply<S> {
    type Input = S;
    type Output = S;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, input: Self::Input) -> Self::Output {
        todo!()
    }
}
