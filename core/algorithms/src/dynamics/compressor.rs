use pa_dsp::*;

pub const fn compressor<S: Sample>(amp: S) -> AudioNode<Compressor<S>> {
    AudioNode(Compressor(amp))
}

pub struct Compressor<S: Sample>(S);

impl<S: Sample> Compressor<S> {
    pub fn from(max: S) -> Compressor<S> {
        Compressor(max)
    }
}

impl<S: Sample> Processor for Compressor<S> {
    type Input = S;
    type Output = S;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _input: Self::Input) -> Self::Output {
        todo!()
    }
}
