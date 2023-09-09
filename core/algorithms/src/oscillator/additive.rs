use std::marker::PhantomData;
use std::f32::consts::PI;

use pa_dsp::{Generator, Sample, Float, Pitched, Complex};

pub struct Additive<S: Sample> {
    pitch: f32,
    multiplier: Complex<f32>,
    value: Complex<f32>,
    rate: f32,
    data: PhantomData<S>,
}

impl<S: Sample> Additive<S> {
    pub fn new() -> Self {
        Self {
            pitch: 440.0,
            multiplier: Complex::from(1.0, 0.0),
            value: Complex::from(1.0, 0.0),
            rate: 44100.0,
            data: PhantomData
        }
    }
}

impl<S: Sample> Pitched for Additive<S> {
    fn get_pitch(&self) -> f32 {
        self.pitch
    }

    fn set_pitch(&mut self, hz: f32) {
        self.pitch = hz;
        let phase_increment = self.pitch * 2.0 * PI * self.rate;
        self.multiplier.real = f32::cos(phase_increment);
        self.multiplier.imaginary = f32::sin(phase_increment);
    }
}

impl<S: Sample> Generator for Additive<S> {
    type Output = S;

    fn reset(&mut self) {
        self.pitch = 440.0;
        self.multiplier = Complex::from(1.0, 0.0);
        self.value = Complex::from(1.0, 0.0);
    }

    fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
        self.rate = sample_rate as f32;
    }

    fn generate(&mut self) -> Self::Output {
        self.value = self.value * self.multiplier;
        S::from_f32(self.value.imaginary)
    }
}
