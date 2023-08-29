use crate::*;

pub struct Crossover {
    value: f32,
}

impl Module for Crossover {
    type Voice = CrossoverDSP<Stereo<f32>>;

    const INFO: Info = Info {
        title: "Crossover",
        id: "default.effects.spectral.crossover",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 25),
            Pin::Control("Crossover (0-1)", 55),
        ],
        outputs: &[
            Pin::Audio("Audio High", 25),
            Pin::Audio("Audio Low", 55)
        ],
        path: &["Audio", "Spectral", "Crossover"],
        presets: Presets::NONE
    };

    
    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        CrossoverDSP::new()
    }

    fn load(&mut self, _version: &str, _state: &State) {

    }

    fn save(&self, _state: &mut State) {

    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Crossover",
                color: Color::BLUE,
                value: &mut self.value,
                feedback: Box::new(| v| {
                    format!("{:.2} hz", v * 10000.0)
                }),
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, _block_size: usize) {
        voice.init(sample_rate as i32);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let mut freq = self.value * 10000.0;

        if inputs.control.connected(0) {
            freq = f32::clamp(inputs.control[0], 0.0, 1.0) * 10000.0;
        }

        voice.set_crossover_freq(freq);

        let out1 = outputs.audio[0].as_mut_ptr();
        let out2 = outputs.audio[1].as_mut_ptr();

        unsafe {
            voice.compute(
        		inputs.audio[0].as_slice(),
                &mut [
                    std::slice::from_raw_parts_mut(&mut *out2, outputs.audio[1].len()),
                    std::slice::from_raw_parts_mut(&mut *out1, outputs.audio[0].len()),
                ]
            );
        }
    }
}

/*
import("stdfaust.lib");
freq = hslider("freq", 0.5, 0, 1, 0.0001);
process = _ : fi.crossover2LR4(freq) : si.bus(2);
*/

pub struct CrossoverDSP<F: Sample> {
	fSampleRate: i32,
	fConst0: f32,
	fHslider0: f32,
	fRec3: [F;2],
	fRec4: [F;2],
	fRec0: [F;2],
	fRec1: [F;2],
	fRec7: [F;2],
	fRec8: [F;2],
}

impl<F: Sample> CrossoverDSP<F> {
	fn new() -> Self {
		Self {
			fSampleRate: 0,
			fConst0: 0.0,
			fHslider0: 0.0,
			fRec3: [F::from(0.0);2],
			fRec4: [F::from(0.0);2],
			fRec0: [F::from(0.0);2],
			fRec1: [F::from(0.0);2],
			fRec7: [F::from(0.0);2],
			fRec8: [F::from(0.0);2],
		}
    }

	fn instance_reset_params(&mut self) {
		self.fHslider0 = 0.5;
	}

	fn instance_clear(&mut self) {
		for l0 in 0..2 {
			self.fRec3[(l0) as usize] = F::from(0.0);
		}
		for l1 in 0..2 {
			self.fRec4[(l1) as usize] = F::from(0.0);
		}
		for l2 in 0..2 {
			self.fRec0[(l2) as usize] = F::from(0.0);
		}
		for l3 in 0..2 {
			self.fRec1[(l3) as usize] = F::from(0.0);
		}
		for l4 in 0..2 {
			self.fRec7[(l4) as usize] = F::from(0.0);
		}
		for l5 in 0..2 {
			self.fRec8[(l5) as usize] = F::from(0.0);
		}
	}

	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		self.fConst0 = 3.14159274 / f32::min(192000.0, f32::max(1.0, self.fSampleRate as f32));
	}

	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}

	pub fn init(&mut self, sample_rate: i32) {
		self.instance_init(sample_rate);
	}

	pub fn set_crossover_freq(&mut self, freq: f32) {
        self.fHslider0 = freq;
	}

	pub fn compute(&mut self, inputs: &[F], outputs: &mut[&mut[F]; 2]) {
		let count = inputs.len() as i32;
		let inputs0 = inputs.iter();
		let (outputs0, outputs1) = if let [outputs0, outputs1, ..] = outputs {
			let outputs0 = outputs0[..count as usize].iter_mut();
			let outputs1 = outputs1[..count as usize].iter_mut();
			(outputs0, outputs1)
		} else {
			panic!("wrong number of outputs");
		};
		let mut fSlow0: F = F::from(f32::tan(self.fConst0 * ((self.fHslider0) as f32)));
		let mut fSlow1: F = fSlow0 * (fSlow0 + F::from(1.41421354)) + F::from(1.0);
		let mut fSlow2: F = F::from(2.0) / fSlow1;
		let mut fSlow3: F = fSlow0 / fSlow1;
		let mut fSlow4: F = F::from(1.0) / fSlow1;
		let zipped_iterators = inputs0.zip(outputs0).zip(outputs1);
		for ((input0, output0), output1) in zipped_iterators {
			let mut fTemp0: F = *input0;
			let mut fTemp1: F = self.fRec3[1] + fSlow0 * (fTemp0 - self.fRec4[1]);
			self.fRec3[0] = fSlow2 * fTemp1 - self.fRec3[1];
			let mut fTemp2: F = self.fRec4[1] + fSlow3 * fTemp1;
			self.fRec4[0] = F::from(2.0) * fTemp2 - self.fRec4[1];
			let mut fRec5: F = fSlow4 * fTemp1;
			let mut fRec6: F = fTemp2;
			let mut fTemp3: F = self.fRec0[1] + fSlow0 * (fRec6 - self.fRec1[1]);
			self.fRec0[0] = fSlow2 * fTemp3 - self.fRec0[1];
			let mut fTemp4: F = self.fRec1[1] + fSlow3 * fTemp3;
			self.fRec1[0] = F::from(2.0) * fTemp4 - self.fRec1[1];
			let mut fRec2: F = fTemp4;
			*output0 = (fRec2) as F;
			let mut fTemp5: F = fRec6 + F::from(1.41421354) * fRec5;
			let mut fTemp6: F = self.fRec7[1] + fSlow0 * (fTemp0 - (fTemp5 + self.fRec8[1]));
			self.fRec7[0] = fSlow2 * fTemp6 - self.fRec7[1];
			let mut fTemp7: F = self.fRec8[1] + fSlow3 * fTemp6;
			self.fRec8[0] = F::from(2.0) * fTemp7 - self.fRec8[1];
			let mut fRec9: F = fSlow4 * fTemp6;
			let mut fRec10: F = fTemp7;
			*output1 = ((fTemp0 - (F::from(1.41421354) * (fRec5 + fRec9) + fRec6 + fRec10)) as F);
			self.fRec3[1] = self.fRec3[0];
			self.fRec4[1] = self.fRec4[0];
			self.fRec0[1] = self.fRec0[0];
			self.fRec1[1] = self.fRec1[0];
			self.fRec7[1] = self.fRec7[0];
			self.fRec8[1] = self.fRec8[0];
		}
	}
}