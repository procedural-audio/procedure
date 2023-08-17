use pa_dsp::*;

pub const fn clip<F: Frame>(amp: F) -> AudioNode<Clip<F>> {
    AudioNode(Clip(amp))
}

pub struct Clip<F: Frame>(F);

impl<F: Frame> Clip<F> {
    pub fn from(max: F) -> Clip<F> {
        Clip(max)
    }
}

impl<F: Frame> Processor for Clip<F> {
    type Input = F;
    type Output = F;

    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _input: Self::Input) -> Self::Output {
        todo!()
    }
}
