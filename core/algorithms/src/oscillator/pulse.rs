use std::marker::PhantomData;

use pa_dsp::*;

pub struct Pulse<S: Sample> {
	fSampleRate: i32,
	fConst0: f32,
	fConst1: f32,
	fHslider0: f32,
	iVec0: [i32;2],
	fConst2: f32,
	fRec0: [f32;2],
	fVec1: [f32;2],
	IOTA0: i32,
	fVec2: Box<[f32;4096]>,
	fHslider1: f32,
    data: PhantomData<S>
}

impl<S: Sample> Pulse<S> {
	pub fn new() -> Self { 
		Self {
			fSampleRate: 0,
			fConst0: 0.0,
			fConst1: 0.0,
			fHslider0: 0.0,
			iVec0: [0;2],
			fConst2: 0.0,
			fRec0: [0.0;2],
			fVec1: [0.0;2],
			IOTA0: 0,
			fVec2: Box::new([0.0;4096]),
			fHslider1: 0.0,
            data: PhantomData
		}
	}
	
	fn instance_reset_params(&mut self) {
		self.fHslider0 = 0.0;
		self.fHslider1 = 0.0;
	}

	fn instance_clear(&mut self) {
		for l0 in 0..2 {
			self.iVec0[(l0) as usize] = 0;
		}
		for l1 in 0..2 {
			self.fRec0[(l1) as usize] = 0.0;
		}
		for l2 in 0..2 {
			self.fVec1[(l2) as usize] = 0.0;
		}
		self.IOTA0 = 0;
		for l3 in 0..4096 {
			self.fVec2[(l3) as usize] = 0.0;
		}
	}

	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		self.fConst0 = f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32)));
		self.fConst1 = 0.25 * self.fConst0;
		self.fConst2 = 1.0 / self.fConst0;
	}

    pub fn set_duty(&mut self, duty: f32) {
        self.fHslider1 = duty;
    }
}

impl<S: Sample> Generator for Pulse<S> {
    type Output = S;

    fn reset(&mut self) {
        self.instance_reset_params();
        self.instance_clear();
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        self.instance_constants(sample_rate as i32);
        self.reset();
    }

    fn generate(&mut self) -> Self::Output {
		let mut fSlow0: f32 = f32::max(((self.fHslider0) as f32), 23.4489498);
		let mut fSlow1: f32 = f32::max(20.0, f32::abs(fSlow0));
		let mut fSlow2: f32 = self.fConst1 / fSlow1;
		let mut fSlow3: f32 = self.fConst2 * fSlow1;
		let mut fSlow4: f32 = f32::max(0.0, f32::min(2047.0, self.fConst0 * ((self.fHslider1) as f32) / fSlow0));
		let mut fSlow5: f32 = f32::floor(fSlow4);
		let mut fSlow6: f32 = fSlow5 + 1.0 - fSlow4;
		let mut iSlow7: i32 = ((fSlow4) as i32);
		let mut fSlow8: f32 = fSlow4 - fSlow5;
		let mut iSlow9: i32 = iSlow7 + 1;

		{
			self.iVec0[0] = 1;
			self.fRec0[0] = fSlow3 + self.fRec0[1] - f32::floor(fSlow3 + self.fRec0[1]);
			let mut fTemp0: f32 = mydsp_faustpower2_f(2.0 * self.fRec0[0] + -1.0);
			self.fVec1[0] = fTemp0;
			let mut fTemp1: f32 = fSlow2 * ((self.iVec0[1]) as f32) * (fTemp0 - self.fVec1[1]);
			self.fVec2[(self.IOTA0 & 4095) as usize] = fTemp1;
			let output = ((fTemp1 - (fSlow6 * self.fVec2[((self.IOTA0 - iSlow7) & 4095) as usize] + fSlow8 * self.fVec2[((self.IOTA0 - iSlow9) & 4095) as usize])) as f32);
			self.iVec0[1] = self.iVec0[0];
			self.fRec0[1] = self.fRec0[0];
			self.fVec1[1] = self.fVec1[0];
			self.IOTA0 = self.IOTA0 + 1;

            return S::from_f32(output);
		}
    }
}

impl<S: Sample> Pitched for Pulse<S> {
    fn get_pitch(&self) -> f32 {
        self.fHslider0
    }

    fn set_pitch(&mut self, hz: f32) {
        self.fHslider0 = hz;
    }
}

fn mydsp_faustpower2_f(value: f32) -> f32 {
	return value * value;
}