use pa_dsp::*;

pub const fn constant<S: Sample>(max: S) -> AudioNode<Constant<S>> {
    AudioNode(Constant(max))
}

pub struct Constant<S: Sample>(S);

impl<S: Sample> Constant<S> {
    pub fn from(max: S) -> Self {
        Self(max)
    }
}

impl<S: Sample> Generator for Constant<S> {
    type Output = S;

    fn reset(&mut self) {}

    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn generate(&mut self) -> Self::Output {
        self.0
    }
}
