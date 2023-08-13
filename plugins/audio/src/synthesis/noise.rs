use crate::*;

pub struct Noise {
    value: f32,
}

impl Module for Noise {
    type Voice = ColoredNoiseDsp<Stereo<f32>>;

    const INFO: Info = Info {
        title: "Noise",
        id: "default.synthesis.noise",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Control("Noise Type", 25)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 25)
        ],
        path: &["Audio", "Synthesis", "Noise"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ColoredNoiseDsp::new()
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Type",
                color: Color::BLUE,
                value: &mut self.value,
                feedback: Box::new(|v| {
                    if v < 1.0 / 3.0 {
                        format!("Brown")
                    } else if v < 2.0 / 3.0 {
                        format!("Pink")
                    } else {
                        format!("White")
                    }
                }),
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, _block_size: usize) {
        voice.init(sample_rate as i32);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let mut color = self.value;
        if inputs.control.connected(0) {
            color = f32::clamp(inputs.control[0], 0.0, 1.0);
        }
        
        voice.set_color(color - 1.0);
        voice.compute(
            outputs.audio[0].len() as i32,
            &[&[]],
            &mut [outputs.audio[0].as_slice_mut()]
        );
    }
}

/*faust!(NoiseProcessor,
    freq = hslider("freq[style:numerical]", -0.5, -1.0, 1.0, 0.001) : si.smoo;
    process = no.colored_noise(2, freq);
);*/

pub struct ColoredNoiseDsp<F: Frame> {
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
	fVec0: [F;2],
	fRec2: [F;2],
	fRec1: [F;2],
	fVec1: [F;2],
	fRec0: [F;2],
}

impl<F: Frame> ColoredNoiseDsp<F> {
	fn new() -> Self {
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
			fVec0: [F::from(0.0);2],
			fRec2: [F::from(0.0);2],
			fRec1: [F::from(0.0);2],
			fVec1: [F::from(0.0);2],
			fRec0: [F::from(0.0);2],
		}
	}

	fn get_sample_rate(&self) -> i32 {
		return self.fSampleRate;
	}

	fn get_num_inputs(&self) -> i32 {
		return 0;
	}

	fn get_num_outputs(&self) -> i32 {
		return 1;
	}

	fn instance_reset_params(&mut self) {
		self.fHslider0 = -0.5;
	}

	fn instance_clear(&mut self) {
		for l0 in 0..2 {
			self.iRec3[(l0) as usize] = 0;
		}
		for l1 in 0..2 {
			self.fVec0[(l1) as usize] = F::from(0.0);
		}
		for l2 in 0..2 {
			self.fRec2[(l2) as usize] = F::from(0.0);
		}
		for l3 in 0..2 {
			self.fRec1[(l3) as usize] = F::from(0.0);
		}
		for l4 in 0..2 {
			self.fVec1[(l4) as usize] = F::from(0.0);
		}
		for l5 in 0..2 {
			self.fRec0[(l5) as usize] = F::from(0.0);
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

	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}

	fn init(&mut self, sample_rate: i32) {
		self.instance_init(sample_rate);
	}

    fn set_color(&mut self, color: f32) {
        self.fHslider0 = f32::clamp(color, -1.0, 1.0);
    }

	fn compute(&mut self, count: i32, inputs: &[&[F]], outputs: &mut[&mut[F]]) {
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
			self.fVec0[0] = F::from(fTemp0);
			self.fRec2[0] = F::from(0.995000005) * self.fRec2[1] + F::from(4.65661287e-10) * (F::from(fTemp0) - self.fVec0[1]);
			self.fRec1[0] = F::from(0.0) - F::from(self.fConst9) * (F::from(self.fConst10) * self.fRec1[1] - (F::from(fSlow7) * self.fRec2[0] + F::from(fSlow8) * self.fRec2[1]));
			self.fVec1[0] = F::from(fSlow10) * self.fRec1[0];
			self.fRec0[0] = F::from(0.0) - F::from(self.fConst6) * (F::from(self.fConst7) * self.fRec0[1] - (F::from(fSlow5) * self.fRec1[0] + F::from(fSlow9) * self.fVec1[1]));
			*output0 = ((F::min(F::from(1.0), F::max(F::from(-1.0), F::from(fSlow2) * self.fRec0[0] / F::from(fSlow13)))) as F);
			self.iRec3[1] = self.iRec3[0];
			self.fVec0[1] = self.fVec0[0];
			self.fRec2[1] = self.fRec2[0];
			self.fRec1[1] = self.fRec1[0];
			self.fVec1[1] = self.fVec1[0];
			self.fRec0[1] = self.fRec0[0];
		}
	}
}

/*pub struct ColoredNoiseDsp2<F: Frame>{
	fSampleRate: i32,
	fConst1: F,
	fConst2: F,
	fConst3: F,
	fConst5: F,
	fConst6: F,
	fConst7: F,
	fConst8: F,
	fConst9: F,
	iRec3: [F;2],
	fVec0: [F;2],
	fRec2: [F;2],
	fConst10: F,
	fConst11: F,
	fHslider0: f32,
	fConst12: F,
	fRec4: [F;2],
	fRec1: [F;2],
	fVec1: [F;2],
	fRec0: [F;2],
}

impl<F: Frame> ColoredNoiseDsp2<F> {
	fn new() -> Self {
		Self {
			fSampleRate: 0,
			fConst1: 0.0,
			fConst2: 0.0,
			fConst3: 0.0,
			fConst5: 0.0,
			fConst6: 0.0,
			fConst7: 0.0,
			fConst8: 0.0,
			fConst9: 0.0,
			iRec3: [0;2],
			fVec0: [0.0;2],
			fRec2: [0.0;2],
			fConst10: 0.0,
			fConst11: 0.0,
			fHslider0: 0.0,
			fConst12: 0.0,
			fRec4: [0.0;2],
			fRec1: [0.0;2],
			fVec1: [0.0;2],
			fRec0: [0.0;2],
		}
	}

	fn get_sample_rate(&self) -> i32 {
		return self.fSampleRate;
	}

	fn get_num_inputs(&self) -> i32 {
		return 0;
	}

	fn get_num_outputs(&self) -> i32 {
		return 1;
	}

	fn instance_reset_params(&mut self) {
		self.fHslider0 = -0.5;
	}

	fn instance_clear(&mut self) {
		for l0 in 0..2 {
			self.iRec3[(l0) as usize] = 0;
		}
		for l1 in 0..2 {
			self.fVec0[(l1) as usize] = 0.0;
		}
		for l2 in 0..2 {
			self.fRec2[(l2) as usize] = 0.0;
		}
		for l3 in 0..2 {
			self.fRec4[(l3) as usize] = 0.0;
		}
		for l4 in 0..2 {
			self.fRec1[(l4) as usize] = 0.0;
		}
		for l5 in 0..2 {
			self.fVec1[(l5) as usize] = 0.0;
		}
		for l6 in 0..2 {
			self.fRec0[(l6) as usize] = 0.0;
		}
	}

	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		let mut fConst0: f32 = f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32)));
		self.fConst1 = F::tan(F::from(62831.8516) / F::from(fConst0));
		self.fConst2 = F::from(62.831852 / fConst0);
		self.fConst3 = F::tan(self.fConst2);
		let mut fConst4: F = F::from(125.663704) * self.fConst1 / self.fConst3;
		self.fConst5 = F::from(1.0) / F::tan(F::from(0.5) / F::from(fConst0));
		self.fConst6 = F::from(1.0) / (fConst4 + self.fConst5);
		self.fConst7 = fConst4 - self.fConst5;
		self.fConst8 = F::from(1.0) / (self.fConst5 + F::from(125.663704));
		self.fConst9 = F::from(125.663704) - self.fConst5;
		self.fConst10 = F::from(125.663704) / self.fConst3;
		self.fConst11 = F::from(44.0999985) / F::from(fConst0);
		self.fConst12 = F::from(1.0) - self.fConst11;
	}

	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}

	fn init(&mut self, sample_rate: i32) {
		self.instance_init(sample_rate);
	}

    fn set_color(&mut self, color: f32) {
        self.fHslider0 = f32::clamp(color, -1.0, 1.0);
    }

	fn compute(&mut self, count: i32, outputs: &mut[&mut[F]]) {
		let (outputs0) = if let [outputs0, ..] = outputs {
			let outputs0 = outputs0[..count as usize].iter_mut();
			(outputs0)
		} else {
			panic!("wrong number of outputs");
		};
		let mut fSlow0: F = self.fConst11 * (F::from(self.fHslider0) as F);
		let zipped_iterators = outputs0;
		for output0 in zipped_iterators {
			self.iRec3[0] = F::from(1103515245.0) * self.iRec3[1] + F::from(12345.0);
			let mut fTemp0: F = ((self.iRec3[0]) as F);
			self.fVec0[0] = fTemp0;
			self.fRec2[0] = F::from(0.995000005) * self.fRec2[1] + F::from(4.65661287e-10) * (fTemp0 - self.fVec0[1]);
			self.fRec4[0] = fSlow0 + self.fConst12 * self.fRec4[1];
			let mut fTemp1: F = F::tan(self.fConst2 * F::powf(F::from(1000.0), F::from(-1.0) * self.fRec4[0]));
			let mut fTemp2: F = self.fConst10 * fTemp1;
			self.fRec1[0] = F::from(0.0) - self.fConst8 * (self.fConst9 * self.fRec1[1] - (self.fRec2[0] * (self.fConst5 + fTemp2) + self.fRec2[1] * (fTemp2 - self.fConst5)));
			let mut fTemp3: F = F::tan(self.fConst2 * F::powf(F::from(1000.0), F::from(1.0) - self.fRec4[0]));
			let mut fTemp4: F = self.fConst10 * fTemp3;
			self.fVec1[0] = self.fRec1[0] / fTemp1;
			self.fRec0[0] = F::from(0.0) - self.fConst6 * (self.fConst7 * self.fRec0[1] - self.fConst3 * ((self.fRec1[0] * (self.fConst5 + fTemp4)) / fTemp1 + self.fVec1[1] * (fTemp4 - self.fConst5)));
			let mut fTemp5: F = F::from(2.0) * self.fRec4[0];
			let mut iTemp6: F = ((((fTemp5 > 0.0)) as i32) - ((fTemp5 < 0.0) as i32) > 0) as i32);
			*output0 = ((F::min(F::from(1.0), F::max(F::from(-1.0), self.fConst1 * self.fRec0[0] / (fTemp3 * (if (iTemp6 as i32 != 0) { 1.0 } else { 0.801599979 } * F::exp(0.0 - 2.0 * self.fRec4[0] * if (iTemp6 as i32 != 0) { -4.28000021 } else { -2.6329999 }) + if (iTemp6 as i32 != 0) { 0.0 } else { 0.198400006 } * F::exp(0.0 - 2.0 * self.fRec4[0] * if (iTemp6 as i32 != 0) { 0.0 } else { -0.719600022 })))))) as F);
			self.iRec3[1] = self.iRec3[0];
			self.fVec0[1] = self.fVec0[0];
			self.fRec2[1] = self.fRec2[0];
			self.fRec4[1] = self.fRec4[0];
			self.fRec1[1] = self.fRec1[0];
			self.fVec1[1] = self.fVec1[0];
			self.fRec0[1] = self.fRec0[0];
		}
	}
}*/