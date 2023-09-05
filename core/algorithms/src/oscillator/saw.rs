use std::marker::PhantomData;

use pa_dsp::*;

pub struct Saw<S: Sample> {
	f_sample_rate: i32,
	f_const_0: f32,
	f_const_1: f32,
	f_const_2: f32,
	f_pitch: f32,
	f_const_3: f32,
	f_rec_2: [f32;2],
	f_rec_0: [f32;2],
    data: PhantomData<S>
}

impl<S: Sample> Saw<S> {
    pub fn new() -> Self {
        Self {
            f_sample_rate: 0,
            f_const_0: 0.0,
            f_const_1: 0.0,
            f_const_2: 0.0,
            f_pitch: 0.0,
            f_const_3: 0.0,
            f_rec_2: [0.0;2],
            f_rec_0: [0.0;2],
            data: PhantomData
        }
    }
}

impl<S: Sample> Pitched for Saw<S> {
    fn set_pitch(&mut self, pitch: f32) {
        self.f_pitch = pitch;
    }

    fn get_pitch(&self) -> f32 {
        self.f_pitch
    }
}

impl<S: Sample> Generator for Saw<S> {
    type Output = S;

    fn reset(&mut self) {
    }

    fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
        // instance constants
		self.f_sample_rate = sample_rate as i32;
		self.f_const_0 = f32::min(192000.0, f32::max(1.0, (self.f_sample_rate) as f32));
		self.f_const_1 = 1.0 / self.f_const_0;
		self.f_const_2 = 44.0999985 / self.f_const_0;
		self.f_const_3 = 1.0 - self.f_const_2;

        // initialize parameters
		self.f_pitch = 500.0;

        // instance clear
		for l0 in 0..2 {
			self.f_rec_2[(l0) as usize] = 0.0;
		}
		for l1 in 0..2 {
			self.f_rec_0[(l1) as usize] = 0.0;
		}
    }

    fn generate(&mut self) -> Self::Output {
		let f_slow_0: f32 = self.f_const_2 * self.f_pitch as f32;
        self.f_rec_2[0] = f_slow_0 + self.f_const_3 * self.f_rec_2[1];
        let f0: f32 = f32::max(1.1920929e-07, f32::abs(self.f_rec_2[0]));
        let f1: f32 = self.f_rec_0[1] + self.f_const_1 * f0;
        let f2: f32 = f1 + -1.0;
        let i1: i32 = (f2 < 0.0) as i32;
        self.f_rec_0[0] = if i1 as i32 != 0 { f1 } else { f2 };
        let f3: f32 = f1 + (1.0 - self.f_const_0 / f0) * f2;
        let f_rec_1: f32 = if i1 as i32 != 0 { f1 } else { f3 };
        let output = 2.0 * f_rec_1 + -1.0;
        self.f_rec_2[1] = self.f_rec_2[0];
        self.f_rec_0[1] = self.f_rec_0[0];
        return S::from_f32(output);
    }
}
