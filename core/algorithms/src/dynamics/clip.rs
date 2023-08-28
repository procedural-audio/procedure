use pa_dsp::*;

pub const fn clip<S: Sample>(max: S) -> AudioNode<Clip<S>> {
    AudioNode(Clip(max))
}

pub struct Clip<S: Sample>(S);

impl<S: Sample> Clip<S> {
    pub fn from(max: S) -> Clip<S> {
        Clip(max)
    }
}

impl<S: Sample> Processor for Clip<S> {
    type Input = S;
    type Output = S;

    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, input: Self::Input) -> Self::Output {
        todo!()
    }
}
