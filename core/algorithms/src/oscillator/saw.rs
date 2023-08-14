use std::marker::PhantomData;

use pa_dsp::Frame;

pub struct Saw<F: Frame> {
	fSampleRate: i32,
	fConst0: f32,
	fConst1: f32,
	fConst2: f32,
	fHslider0: f32,
	fConst3: f32,
	fRec2: [f32;2],
	fRec0: [f32;2],
    data: PhantomData<F>
}

impl<F: Frame> Saw<F> {
	pub fn new() -> Self {
		Self {
			fSampleRate: 0,
			fConst0: 0.0,
			fConst1: 0.0,
			fConst2: 0.0,
			fHslider0: 0.0,
			fConst3: 0.0,
			fRec2: [0.0;2],
			fRec0: [0.0;2],
            data: PhantomData
		}
	}

	pub fn get_sample_rate(&self) -> i32 {
		return self.fSampleRate;
	}

	pub fn get_num_inputs(&self) -> i32 {
		return 0;
	}

	pub fn get_num_outputs(&self) -> i32 {
		return 1;
	}

	pub fn instance_reset_params(&mut self) {
		self.fHslider0 = 500.0;
	}

	pub fn instance_clear(&mut self) {
		for l0 in 0..2 {
			self.fRec2[(l0) as usize] = 0.0;
		}
		for l1 in 0..2 {
			self.fRec0[(l1) as usize] = 0.0;
		}
	}

	pub fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		self.fConst0 = f32::min(192000.0, f32::max(1.0, (self.fSampleRate) as f32));
		self.fConst1 = 1.0 / self.fConst0;
		self.fConst2 = 44.0999985 / self.fConst0;
		self.fConst3 = 1.0 - self.fConst2;
	}

	pub fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}

	pub fn init(&mut self, sample_rate: i32) {
		self.instance_init(sample_rate);
	}

	pub fn set_freq(&mut self, hz: f32) {
        self.fHslider0 = hz;
	}

	pub fn compute(&mut self, count: i32, _inputs: &[&[F]], outputs: &mut [&mut [F]]) {
		let (outputs0) = if let [outputs0, ..] = outputs {
			let outputs0 = outputs0[..count as usize].iter_mut();
			(outputs0)
		} else {
			panic!("wrong number of outputs");
		};
		let mut fSlow0: f32 = self.fConst2 * ((self.fHslider0) as f32);
		let zipped_iterators = outputs0;
		for output0 in zipped_iterators {
			self.fRec2[0] = fSlow0 + self.fConst3 * self.fRec2[1];
			let fTemp0: f32 = f32::max(1.1920929e-07, f32::abs(self.fRec2[0]));
			let fTemp1: f32 = self.fRec0[1] + self.fConst1 * fTemp0;
			let fTemp2: f32 = fTemp1 + -1.0;
			let iTemp3: i32 = ((fTemp2 < 0.0) as i32);
			self.fRec0[0] = if (iTemp3 as i32 != 0) { fTemp1 } else { fTemp2 };
			let fThen1: f32 = fTemp1 + (1.0 - self.fConst0 / fTemp0) * fTemp2;
			let fRec1: f32 = if iTemp3 as i32 != 0 { fTemp1 } else { fThen1 };
			*output0 = F::from(2.0) * F::from(fRec1) + F::from(-1.0);
			self.fRec2[1] = self.fRec2[0];
			self.fRec0[1] = self.fRec0[0];
		}
	}
}
