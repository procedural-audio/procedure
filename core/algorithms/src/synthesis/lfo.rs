use pa_dsp::*;

pub struct Lfo {
    shape: fn(f32) -> f32,
    pitch: f32,
    phase: f32,
    rate: u32,
}

impl Lfo {
    pub fn from(shape: fn(f32) -> f32, pitch: f32) -> Self {
        Self {
            shape,
            pitch,
            phase: 0.0,
            rate: 44100,
        }
    }
}

impl Generator for Lfo {
    type Output = f32;

    fn reset(&mut self) {
        self.phase = 0.0;
    }

    fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
        self.rate = sample_rate;
    }

    fn generate(&mut self) -> Self::Output {
        let phase = self.phase;
        let delta = (1.0 / self.rate as f32) * self.pitch.generate();
        self.phase += delta;
        (self.shape)(phase)
    }
}

impl Pitched for Lfo {
    fn get_pitch(&self) -> f32 {
        self.pitch
    }

    fn set_pitch(&mut self, hz: f32) {
        self.pitch = hz;
    }
}
