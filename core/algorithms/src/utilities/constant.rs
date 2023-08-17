use pa_dsp::*;

pub const fn constant<F: Frame>(max: F) -> AudioNode<Constant<F>> {
    AudioNode(Constant(max))
}

pub struct Constant<F: Frame>(F);

impl<F: Frame> Constant<F> {
    pub fn from(max: F) -> Self {
        Self(max)
    }
}

impl<F: Frame> Generator for Constant<F> {
    type Output = F;

    fn reset(&mut self) {}

    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn generate(&mut self) -> Self::Output {
        self.0
    }
}
