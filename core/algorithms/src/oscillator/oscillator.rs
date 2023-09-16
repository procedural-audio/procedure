use pa_dsp::{Float, Sample, Generator, Pitched};

pub struct Oscillator<S: Sample> {
    pitch: f32,
    rate: S::Float,
    phase: S::Float,
    function: fn(S::Float) -> S::Float
}

impl<S: Sample> Oscillator<S> {
    pub fn from(f: fn(S::Float) -> S::Float) -> Self {
        Self {
            pitch: 0.0,
            rate: S::Float::ZERO,
            phase: S::Float::ZERO,
            function: f
        }
    }
}

impl<S: Sample> Generator for Oscillator<S> {
    type Output = S;

    fn reset(&mut self) {
        self.phase = S::Float::ZERO;
    }

    fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
        self.rate = S::Float::from(sample_rate as f32);
    }

    fn generate(&mut self) -> Self::Output {
        let x: <S as Sample>::Float = S::Float::from(2.0) * S::Float::PI * self.phase;
        let y = (self.function)(x);
        self.phase += S::Float::from(self.pitch) / self.rate;
        return S::from(y);
    }
}

impl<S: Sample> Pitched for Oscillator<S> {
    fn get_pitch(&self) -> f32 {
        self.pitch
    }

    fn set_pitch(&mut self, hz: f32) {
        self.pitch = hz;
    }
}