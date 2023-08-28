use pa_dsp::*;

pub const fn gain<S: Sample>(db: S) -> AudioNode<Gain<S>> {
    AudioNode(Gain(db))
}

pub struct Gain<S: Sample>(S);

impl<S: Sample> Gain<S> {
    pub fn from(db: S) -> Gain<S> {
        Gain(db)
    }
}

impl<S: Sample> Processor for Gain<S> {
    type Input = S;
    type Output = S;

    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, input: Self::Input) -> Self::Output {
        // input * self.0
        todo!()
    }
}
