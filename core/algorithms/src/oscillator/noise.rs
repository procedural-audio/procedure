use pa_dsp::*;

pub fn colored_noise<S: Sample>(s: f32) -> AudioNode<ColoredNoise<S>> {
    todo!()
}

pub struct ColoredNoise<S: Sample> {
	fSampleRate: i32,
	fConst1: f32,
	fConst2: f32,
	fHslider0: f32,
	fConst3: f32,
	fConst5: f32,
	fConst6: f32,
	fConst7: f32,
	fConst8: f32,
	fConst9: f32,
	fConst10: f32,
	iRec3: [i32;2],
	fVec0: [S;2],
	fRec2: [S;2],
	fRec1: [S;2],
	fVec1: [S;2],
	fRec0: [S;2],
}

impl<S: Sample> ColoredNoise<S> {
	pub fn new() -> Self {
		Self {
			fSampleRate: 0,
			fConst1: 0.0,
			fConst2: 0.0,
			fHslider0: 0.0,
			fConst3: 0.0,
			fConst5: 0.0,
			fConst6: 0.0,
			fConst7: 0.0,
			fConst8: 0.0,
			fConst9: 0.0,
			fConst10: 0.0,
			iRec3: [0;2],
			fVec0: [S::EQUILIBRIUM;2],
			fRec2: [S::EQUILIBRIUM;2],
			fRec1: [S::EQUILIBRIUM;2],
			fVec1: [S::EQUILIBRIUM;2],
			fRec0: [S::EQUILIBRIUM;2],
		}
	}

	fn instance_reset_params(&mut self) {
		self.fHslider0 = -0.5;
	}

	fn instance_clear(&mut self) {
		for l0 in 0..2 {
			self.iRec3[(l0) as usize] = 0;
		}
		for l1 in 0..2 {
			self.fVec0[(l1) as usize] = S::EQUILIBRIUM;
		}
		for l2 in 0..2 {
			self.fRec2[(l2) as usize] = S::EQUILIBRIUM;
		}
		for l3 in 0..2 {
			self.fRec1[(l3) as usize] = S::EQUILIBRIUM;
		}
		for l4 in 0..2 {
			self.fVec1[(l4) as usize] = S::EQUILIBRIUM;
		}
		for l5 in 0..2 {
			self.fRec0[(l5) as usize] = S::EQUILIBRIUM;
		}
	}

	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		let mut fConst0: f32 = f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32)));
		self.fConst1 = f32::tan(62831.8516 / fConst0);
		self.fConst2 = 62.831852 / fConst0;
		self.fConst3 = f32::tan(self.fConst2);
		let mut fConst4: f32 = 125.663704 * self.fConst1 / self.fConst3;
		self.fConst5 = 1.0 / f32::tan(0.5 / fConst0);
		self.fConst6 = 1.0 / (fConst4 + self.fConst5);
		self.fConst7 = fConst4 - self.fConst5;
		self.fConst8 = 125.663704 / self.fConst3;
		self.fConst9 = 1.0 / (self.fConst5 + 125.663704);
		self.fConst10 = 125.663704 - self.fConst5;
	}

    pub fn set_color(&mut self, color: f32) {
        self.fHslider0 = f32::clamp(color, -1.0, 1.0);
    }

	/*fn compute(&mut self, count: i32, inputs: &[&[S]], outputs: &mut[&mut[S]]) {
		let (outputs0) = if let [outputs0, ..] = outputs {
			let outputs0 = outputs0[..count as usize].iter_mut();
			(outputs0)
		} else {
			panic!("wrong number of outputs");
		};
		let mut fSlow0: f32 = ((self.fHslider0) as f32);
		let mut fSlow1: f32 = f32::tan(self.fConst2 * f32::powf(1000.0, 1.0 - fSlow0));
		let mut fSlow2: f32 = self.fConst1 / fSlow1;
		let mut fSlow3: f32 = self.fConst8 * fSlow1;
		let mut fSlow4: f32 = f32::tan(self.fConst2 * f32::powf(1000.0, -1.0 * fSlow0));
		let mut fSlow5: f32 = self.fConst3 * (self.fConst5 + fSlow3) / fSlow4;
		let mut fSlow6: f32 = self.fConst8 * fSlow4;
		let mut fSlow7: f32 = self.fConst5 + fSlow6;
		let mut fSlow8: f32 = fSlow6 - self.fConst5;
		let mut fSlow9: f32 = fSlow3 - self.fConst5;
		let mut fSlow10: f32 = self.fConst3 / fSlow4;
		let mut fSlow11: f32 = 2.0 * fSlow0;
		let mut iSlow12: i32 = ((((fSlow11 > 0.0) as i32) - ((fSlow11 < 0.0) as i32) > 0) as i32);
		let mut fSlow13: f32 = if (iSlow12 as i32 != 0) { 1.0 } else { 0.801599979 } * f32::exp(0.0 - fSlow11 * if (iSlow12 as i32 != 0) { -4.28000021 } else { -2.6329999 }) + if (iSlow12 as i32 != 0) { 0.0 } else { 0.198400006 } * f32::exp(0.0 - fSlow11 * if (iSlow12 as i32 != 0) { 0.0 } else { -0.719600022 });
		let zipped_iterators = outputs0;
		for output0 in zipped_iterators {
			self.iRec3[0] = 1103515245 * self.iRec3[1] + 12345;
			let mut fTemp0: f32 = ((self.iRec3[0]) as f32);
			self.fVec0[0] = S::from_f32(fTemp0);
			self.fRec2[0] = S::from_f32(0.995000005) * self.fRec2[1] + S::from_f32(4.65661287e-10) * (S::from_f32(fTemp0) - self.fVec0[1]);
			self.fRec1[0] = S::EQUILIBRIUM - S::from_f32(self.fConst9) * (S::from_f32(self.fConst10) * self.fRec1[1] - (S::from_f32(fSlow7) * self.fRec2[0] + S::from_f32(fSlow8) * self.fRec2[1]));
			self.fVec1[0] = S::from_f32(fSlow10) * self.fRec1[0];
			self.fRec0[0] = S::EQUILIBRIUM - S::from_f32(self.fConst6) * (S::from_f32(self.fConst7) * self.fRec0[1] - (S::from_f32(fSlow5) * self.fRec1[0] + S::from_f32(fSlow9) * self.fVec1[1]));
			*output0 = (S::min(S::from_f32(1.0), S::max(S::from_f32(-1.0), S::from_f32(fSlow2) * self.fRec0[0] / S::from_f32(fSlow13))));
			self.iRec3[1] = self.iRec3[0];
			self.fVec0[1] = self.fVec0[0];
			self.fRec2[1] = self.fRec2[0];
			self.fRec1[1] = self.fRec1[0];
			self.fVec1[1] = self.fVec1[0];
			self.fRec0[1] = self.fRec0[0];
		}
	}*/
}

impl<S: Sample> Generator for ColoredNoise<S> {
    type Output = S;

    fn reset(&mut self) {
		self.instance_clear();
		self.instance_reset_params();
    }

    fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
		self.instance_constants(sample_rate as i32);
		self.reset();
    }

    fn generate(&mut self) -> Self::Output {
		let mut fSlow0: f32 = ((self.fHslider0) as f32);
		let mut fSlow1: f32 = f32::tan(self.fConst2 * f32::powf(1000.0, 1.0 - fSlow0));
		let mut fSlow2: f32 = self.fConst1 / fSlow1;
		let mut fSlow3: f32 = self.fConst8 * fSlow1;
		let mut fSlow4: f32 = f32::tan(self.fConst2 * f32::powf(1000.0, -1.0 * fSlow0));
		let mut fSlow5: f32 = self.fConst3 * (self.fConst5 + fSlow3) / fSlow4;
		let mut fSlow6: f32 = self.fConst8 * fSlow4;
		let mut fSlow7: f32 = self.fConst5 + fSlow6;
		let mut fSlow8: f32 = fSlow6 - self.fConst5;
		let mut fSlow9: f32 = fSlow3 - self.fConst5;
		let mut fSlow10: f32 = self.fConst3 / fSlow4;
		let mut fSlow11: f32 = 2.0 * fSlow0;
		let mut iSlow12: i32 = ((((fSlow11 > 0.0) as i32) - ((fSlow11 < 0.0) as i32) > 0) as i32);
		let mut fSlow13: f32 = if (iSlow12 as i32 != 0) { 1.0 } else { 0.801599979 } * f32::exp(0.0 - fSlow11 * if (iSlow12 as i32 != 0) { -4.28000021 } else { -2.6329999 }) + if (iSlow12 as i32 != 0) { 0.0 } else { 0.198400006 } * f32::exp(0.0 - fSlow11 * if (iSlow12 as i32 != 0) { 0.0 } else { -0.719600022 });

		{
			self.iRec3[0] = 1103515245 * self.iRec3[1] + 12345;
			let mut fTemp0: f32 = ((self.iRec3[0]) as f32);
			self.fVec0[0] = S::from_f32(fTemp0);
			self.fRec2[0] = S::from_f32(0.995000005) * self.fRec2[1] + S::from_f32(4.65661287e-10) * (S::from_f32(fTemp0) - self.fVec0[1]);
			self.fRec1[0] = S::EQUILIBRIUM - S::from_f32(self.fConst9) * (S::from_f32(self.fConst10) * self.fRec1[1] - (S::from_f32(fSlow7) * self.fRec2[0] + S::from_f32(fSlow8) * self.fRec2[1]));
			self.fVec1[0] = S::from_f32(fSlow10) * self.fRec1[0];
			self.fRec0[0] = S::EQUILIBRIUM - S::from_f32(self.fConst6) * (S::from_f32(self.fConst7) * self.fRec0[1] - (S::from_f32(fSlow5) * self.fRec1[0] + S::from_f32(fSlow9) * self.fVec1[1]));
			let output = (S::min(S::from_f32(1.0), S::max(S::from_f32(-1.0), S::from_f32(fSlow2) * self.fRec0[0] / S::from_f32(fSlow13))));
			self.iRec3[1] = self.iRec3[0];
			self.fVec0[1] = self.fVec0[0];
			self.fRec2[1] = self.fRec2[0];
			self.fRec1[1] = self.fRec1[0];
			self.fVec1[1] = self.fVec1[0];
			self.fRec0[1] = self.fRec0[0];

			return output;
		}
    }
}