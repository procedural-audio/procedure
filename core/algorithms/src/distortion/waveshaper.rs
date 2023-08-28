pub use pa_dsp::*;

pub const fn waveshaper<S: Sample>(f: fn(S) -> S) -> AudioNode<Waveshaper<S>> {
    AudioNode(Waveshaper(f))
}

pub const fn waveshaper_sin<S: Sample>() -> AudioNode<Waveshaper<S>> {
    AudioNode(Waveshaper(S::sin))
}

pub const fn waveshaper_cos<S: Sample>() -> AudioNode<Waveshaper<S>> {
    AudioNode(Waveshaper(S::cos))
}

pub const fn waveshaper_tan<S: Sample>() -> AudioNode<Waveshaper<S>> {
    AudioNode(Waveshaper(S::tan))
}

pub struct Waveshaper<S: Sample>(fn (S) -> S);

impl<S: Sample> Waveshaper<S> {
    pub fn from(f: fn(S) -> S) -> Waveshaper<S> {
        Self(f)
    }
}

impl<S: Sample> Processor for Waveshaper<S> {
    type Input = S;
    type Output = S;

    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, input: Self::Input) -> Self::Output {
        (self.0)(input)
    }
}
