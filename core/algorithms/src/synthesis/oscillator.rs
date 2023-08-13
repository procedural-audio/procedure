use pa_dsp::*;

pub const fn osc<F: Frame, Pitch: Generator<Output = f32>>(f: fn(f32) -> F, hz: Pitch) -> AudioNode<Oscillator<F, Pitch>> {
    AudioNode(Oscillator { f, pitch: hz, x: 0.0, rate: 44100.0 })
}

#[derive(Copy, Clone)]
pub struct Oscillator<F: Frame, Pitch: Generator<Output = f32>> {
    f: fn(f32) -> F,
    pitch: Pitch,
    x: f32,
    rate: f32
}

impl<F: Frame, Pitch: Generator<Output = f32>> Generator for Oscillator<F, Pitch> {
    type Output = F;

    fn reset(&mut self) {}

    fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
        self.rate = sample_rate as f32;
    }

    #[inline]
    fn generate(&mut self) -> Self::Output {
        let out = (self.f)(self.x);
        let pitch = self.pitch.generate();
        self.x += 2.0 * std::f32::consts::PI / self.rate * pitch;
        return out;
    }
}
