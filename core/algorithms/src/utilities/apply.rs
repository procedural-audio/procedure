use pa_dsp::*;

pub const fn apply<F: Frame>(max: F) -> AudioNode<Apply<F>> {
    AudioNode(Apply(max))
}

pub struct Apply<F: Frame>(F);

impl<F: Frame> Apply<F> {
    pub fn from(max: F) -> Self {
        Self(max)
    }
}

impl<F: Frame> Processor for Apply<F> {
    type Input = F;
    type Output = F;

    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, input: Self::Input) -> Self::Output {
        todo!()
    }
}
