pub use pa_dsp::*;

pub const fn waveshaper<F: Frame>(f: fn(F) -> F) -> AudioNode<Waveshaper<F>> {
    AudioNode(Waveshaper(f))
}

pub struct Waveshaper<F: Frame>(fn (F) -> F);

impl<F: Frame> Waveshaper<F> {
    pub fn from(f: fn(F) -> F) -> Waveshaper<F> {
        Self(f)
    }
}

impl<F: Frame> Processor for Waveshaper<F> {
    type Input = F;
    type Output = F;

    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, input: Self::Input) -> Self::Output {
        (self.0)(input)
    }
}
