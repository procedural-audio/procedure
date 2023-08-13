use crate::*;

use pa_dsp::*;

pub struct ShelfFilter {
    selected: usize,
    cutoff: f32,
    q: f32,
}

pub struct ShelfFilterVoice {
    ls: SvfLsFilter<Stereo<f32>>,
    bell: SvfBellFilter<Stereo<f32>>,
    hs: SvfHsFilter<Stereo<f32>>
}

impl Module for ShelfFilter {
    type Voice = ShelfFilterVoice;

    const INFO: Info = Info {
        title: "Shelf Filter",
        id: "default.effects.filters.shelf_filter",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(190, 160),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 20),
            Pin::Control("Control Input", 50),
            Pin::Control("Control Input", 80),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 20)
        ],
        path: &["Audio", "Spectral", "Shelf Filter"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            selected: 0,
            cutoff: 1.0,
            q: 0.0,
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            ls: SvfLsFilter::new(),
        	bell: SvfBellFilter::new(),
            hs: SvfHsFilter::new()
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Stack {
            children: (
                Transform {
                    position: (35, 35),
                    size: (60, 70),
                    child: Knob {
                        text: "Cutoff", // Cutoff
                        color: Color::BLUE,
                        value: &mut self.cutoff,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (35 + 70, 35),
                    size: (60, 70),
                    child: Knob {
                        text: "Q", // Q
                        color: Color::BLUE,
                        value: &mut self.q,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (35, 110),
                    size: (120, 40),
                    child: ButtonGrid {
                        index: &mut self.selected,
                        color: Color::BLUE,
                        rows: 1,
                        icons: &[
                            "waveforms/saw.svg",
                            "waveforms/triangle.svg",
                            "waveforms/saw.svg",
                        ]
                    }
                },
            ),
        });
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.ls.init(sample_rate as i32);
        voice.bell.init(sample_rate as i32);
        voice.hs.init(sample_rate as i32);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let input = inputs.audio[0].as_slice();
        let output = outputs.audio[0].as_slice_mut();
        let mut cutoff = f32::clamp(self.cutoff, 0.0, 1.0);
        let mut q = f32::clamp(self.q, 0.0, 1.0);

        if inputs.control.connected(0) {
            cutoff = f32::clamp(inputs.control[0], 0.0, 1.0);
        }

        if inputs.control.connected(1) {
            q = f32::clamp(inputs.control[1], 0.0, 1.0);
        }

        match self.selected {
            0 => {
                voice.ls.set_freq(cutoff * 10000.0);
                // voice.ls.set_q(0.5 + q * 4.0);
				voice.ls.set_gain(q * 10.0 - 10.0);
                voice.ls.compute(input.len() as i32, &[input], &mut [output]);
            }
            1 => {
                voice.bell.set_freq(cutoff * 10000.0);
                // voice.bell.set_q(0.5 + q * 4.0);
                voice.bell.set_q(1.0);
				voice.bell.set_gain(q * 10.0 - 10.0);
                voice.bell.compute(input.len() as i32, &[input], &mut [output]);
            }
            2 => {
                voice.hs.set_freq(cutoff * 1.0);
                // voice.hs.set_q(0.5 + q * 4.0);
                voice.hs.set_q(1.0);
				voice.hs.set_gain(q * 10.0 - 10.0);
                voice.hs.compute(input.len() as i32, &[input], &mut [output]);
            }
            _ => ()
        }
    }
}

/*
import("stdfaust.lib");
freq = hslider("freq",0.5,0,1,0.001);
q = hslider("q",1,0.5,10,0.01);
gain = hslider("gain",1,0.5,10,0.01);
process = fi.svf.lp(freq, q, gain);
*/

fn mydsp_faustpower2_f<F: Frame>(value: F) -> F {
	return value * value;
}
pub struct SvfLsFilter<F: Frame> {
	fHslider0: f32,
	fHslider1: f32,
	fSampleRate: i32,
	fConst0: f32,
	fHslider2: f32,
	fRec0: [F;2],
	fRec1: [F;2],
}

impl<F: Frame> SvfLsFilter<F> {
	fn new() -> Self {
		Self {
			fHslider0: 0.0,
			fHslider1: 0.0,
			fSampleRate: 0,
			fConst0: 0.0,
			fHslider2: 0.0,
			fRec0: [F::from(0.0);2],
			fRec1: [F::from(0.0);2],
		}
	}

	fn get_sample_rate(&self) -> i32 {
		return self.fSampleRate;
	}

	fn get_num_inputs(&self) -> i32 {
		return 1;
	}

	fn get_num_outputs(&self) -> i32 {
		return 1;
	}

	fn instance_reset_params(&mut self) {
		self.fHslider0 = 1.0;
		self.fHslider1 = 1.0;
		self.fHslider2 = 0.5;
	}

	fn instance_clear(&mut self) {
		for l0 in 0..2 {
			self.fRec0[(l0) as usize] = F::from(0.0);
		}
		for l1 in 0..2 {
			self.fRec1[(l1) as usize] = F::from(0.0);
		}
	}

	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		self.fConst0 = 3.14159274 / f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32)));
	}

	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}

	fn init(&mut self, sample_rate: i32) {
		self.instance_init(sample_rate);
	}

	fn set_freq(&mut self, freq: f32) {
		self.fHslider0 = freq;
	}

	fn set_gain(&mut self, gain: f32) {
		self.fHslider1 = gain;
	}

	fn set_q(&mut self, q: f32) {
		self.fHslider2 = q;
	}

	fn compute(&mut self, count: i32, inputs: &[&[F]], outputs: &mut[&mut[F]]) {
		let (inputs0) = if let [inputs0, ..] = inputs {
			let inputs0 = inputs0[..count as usize].iter();
			(inputs0)
		} else {
			panic!("wrong number of inputs");
		};
		let (outputs0) = if let [outputs0, ..] = outputs {
			let outputs0 = outputs0[..count as usize].iter_mut();
			(outputs0)
		} else {
			panic!("wrong number of outputs");
		};
		let mut fSlow0: f32 = f32::powf(10.0, 0.0250000004 * ((self.fHslider0) as f32));
		let mut fSlow1: f32 = ((self.fHslider1) as f32);
		let mut fSlow2: f32 = (fSlow0 + -1.0) / fSlow1;
		let mut fSlow3: f32 = f32::tan(self.fConst0 * ((self.fHslider2) as f32));
		let mut fSlow4: f32 = f32::sqrt(fSlow0);
		let mut fSlow5: f32 = fSlow3 / fSlow4;
		let mut fSlow6: f32 = (fSlow3 * (1.0 / fSlow1 + fSlow5)) / fSlow4 + 1.0;
		let mut fSlow7: f32 = 2.0 / fSlow6;
		let mut fSlow8: f32 = fSlow3 / (fSlow4 * fSlow6);
		let mut fSlow9: f32 = 1.0 / fSlow6;
		let mut fSlow10: f32 = mydsp_faustpower2_f(fSlow0) + -1.0;
		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			let mut fTemp0: F = ((*input0) as F);
			let mut fTemp1: F = self.fRec0[1] + F::from(fSlow5) * (fTemp0 - self.fRec1[1]);
			self.fRec0[0] = F::from(fSlow7) * fTemp1 - self.fRec0[1];
			let mut fTemp2: F = self.fRec1[1] + F::from(fSlow8) * fTemp1;
			self.fRec1[0] = F::from(2.0) * fTemp2 - self.fRec1[1];
			let mut fRec2: F = F::from(fSlow9) * fTemp1;
			let mut fRec3: F = fTemp2;
			*output0 = ((fTemp0 + F::from(fSlow2) * fRec2 + F::from(fSlow10) * fRec3) as F);
			self.fRec0[1] = self.fRec0[0];
			self.fRec1[1] = self.fRec1[0];
		}
	}
}

pub struct SvfBellFilter<F: Frame> {
	fHslider0: f32,
	fHslider1: f32,
	fSampleRate: i32,
	fConst0: f32,
	fHslider2: f32,
	fRec0: [F;2],
	fRec1: [F;2],
}

impl<F: Frame> SvfBellFilter<F> {
	fn new() -> Self {
		Self {
			fHslider0: 0.0,
			fHslider1: 0.0,
			fSampleRate: 0,
			fConst0: 0.0,
			fHslider2: 0.0,
			fRec0: [F::from(0.0);2],
			fRec1: [F::from(0.0);2],
		}
	}

	fn get_sample_rate(&self) -> i32 {
		return self.fSampleRate;
	}

	fn get_num_inputs(&self) -> i32 {
		return 1;
	}

	fn get_num_outputs(&self) -> i32 {
		return 1;
	}

	fn instance_reset_params(&mut self) {
		self.fHslider0 = 1.0;
		self.fHslider1 = 1.0;
		self.fHslider2 = 0.5;
	}

	fn instance_clear(&mut self) {
		for l0 in 0..2 {
			self.fRec0[(l0) as usize] = F::from(0.0);
		}
		for l1 in 0..2 {
			self.fRec1[(l1) as usize] = F::from(0.0);
		}
	}

	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		self.fConst0 = 3.14159274 / f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32)));
	}

	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}

	fn init(&mut self, sample_rate: i32) {
		self.instance_init(sample_rate);
	}

	fn set_freq(&mut self, freq: f32) {
		self.fHslider0 = freq;
	}

	fn set_gain(&mut self, gain: f32) {
		self.fHslider1 = gain;
	}

	fn set_q(&mut self, q: f32) {
		self.fHslider2 = q;
	}

	fn compute(&mut self, count: i32, inputs: &[&[F]], outputs: &mut[&mut[F]]) {
		let (inputs0) = if let [inputs0, ..] = inputs {
			let inputs0 = inputs0[..count as usize].iter();
			(inputs0)
		} else {
			panic!("wrong number of inputs");
		};
		let (outputs0) = if let [outputs0, ..] = outputs {
			let outputs0 = outputs0[..count as usize].iter_mut();
			(outputs0)
		} else {
			panic!("wrong number of outputs");
		};
		let mut fSlow0: f32 = f32::powf(10.0, 0.0250000004 * ((self.fHslider0) as f32));
		let mut fSlow1: f32 = ((self.fHslider1) as f32) * fSlow0;
		let mut fSlow2: f32 = (mydsp_faustpower2_f(fSlow0) + -1.0) / fSlow1;
		let mut fSlow3: f32 = f32::tan(self.fConst0 * ((self.fHslider2) as f32));
		let mut fSlow4: f32 = fSlow3 * (1.0 / fSlow1 + fSlow3) + 1.0;
		let mut fSlow5: f32 = 2.0 / fSlow4;
		let mut fSlow6: f32 = fSlow3 / fSlow4;
		let mut fSlow7: f32 = 1.0 / fSlow4;
		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			let mut fTemp0: F = ((*input0) as F);
			let mut fTemp1: F = self.fRec0[1] + F::from(fSlow3) * (fTemp0 - self.fRec1[1]);
			self.fRec0[0] = F::from(fSlow5) * fTemp1 - self.fRec0[1];
			let mut fTemp2: F = self.fRec1[1] + F::from(fSlow6) * fTemp1;
			self.fRec1[0] = F::from(2.0) * fTemp2 - self.fRec1[1];
			let mut fRec2: F = F::from(fSlow7) * fTemp1;
			*output0 = ((fTemp0 + F::from(fSlow2) * fRec2) as F);
			self.fRec0[1] = self.fRec0[0];
			self.fRec1[1] = self.fRec1[0];
		}
	}
}

pub struct SvfHsFilter<F: Frame> {
	fHslider0: f32,
	fHslider1: f32,
	fSampleRate: i32,
	fConst0: f32,
	fHslider2: f32,
	fRec0: [F;2],
	fRec1: [F;2],
}

impl<F: Frame> SvfHsFilter<F> {
	fn new() -> Self {
		Self {
			fHslider0: 0.0,
			fHslider1: 0.0,
			fSampleRate: 0,
			fConst0: 0.0,
			fHslider2: 0.0,
			fRec0: [F::from(0.0);2],
			fRec1: [F::from(0.0);2],
		}
	}

	fn get_sample_rate(&self) -> i32 {
		return self.fSampleRate;
	}

	fn get_num_inputs(&self) -> i32 {
		return 1;
	}

	fn get_num_outputs(&self) -> i32 {
		return 1;
	}

	fn instance_reset_params(&mut self) {
		self.fHslider0 = 1.0;
		self.fHslider1 = 1.0;
		self.fHslider2 = 0.5;
	}

	fn instance_clear(&mut self) {
		for l0 in 0..2 {
			self.fRec0[(l0) as usize] = F::from(0.0);
		}
		for l1 in 0..2 {
			self.fRec1[(l1) as usize] = F::from(0.0);
		}
	}

	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		self.fConst0 = 3.14159274 / f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32)));
	}

	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}

	fn init(&mut self, sample_rate: i32) {
		self.instance_init(sample_rate);
	}

	fn set_freq(&mut self, freq: f32) {
		self.fHslider0 = freq;
	}

	fn set_gain(&mut self, gain: f32) {
		self.fHslider1 = gain;
	}

	fn set_q(&mut self, q: f32) {
		self.fHslider2 = q;
	}

	fn compute(&mut self, count: i32, inputs: &[&[F]], outputs: &mut[&mut[F]]) {
		let (inputs0) = if let [inputs0, ..] = inputs {
			let inputs0 = inputs0[..count as usize].iter();
			(inputs0)
		} else {
			panic!("wrong number of inputs");
		};
		let (outputs0) = if let [outputs0, ..] = outputs {
			let outputs0 = outputs0[..count as usize].iter_mut();
			(outputs0)
		} else {
			panic!("wrong number of outputs");
		};
		let mut fSlow0: f32 = f32::powf(10.0, 0.0250000004 * ((self.fHslider0) as f32));
		let mut fSlow1: f32 = ((self.fHslider1) as f32);
		let mut fSlow2: f32 = (1.0 - fSlow0) / fSlow1;
		let mut fSlow3: f32 = f32::tan(self.fConst0 * ((self.fHslider2) as f32)) * f32::sqrt(fSlow0);
		let mut fSlow4: f32 = fSlow3 * (1.0 / fSlow1 + fSlow3) + 1.0;
		let mut fSlow5: f32 = 2.0 / fSlow4;
		let mut fSlow6: f32 = fSlow3 / fSlow4;
		let mut fSlow7: f32 = 1.0 / fSlow4;
		let mut fSlow8: f32 = 1.0 - mydsp_faustpower2_f(fSlow0);
		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			let mut fTemp0: F = ((*input0) as F);
			let mut fTemp1: F = self.fRec0[1] + F::from(fSlow3) * (fTemp0 - self.fRec1[1]);
			self.fRec0[0] = F::from(fSlow5) * fTemp1 - self.fRec0[1];
			let mut fTemp2: F = self.fRec1[1] + F::from(fSlow6) * fTemp1;
			self.fRec1[0] = F::from(2.0) * fTemp2 - self.fRec1[1];
			let mut fRec2: F = F::from(fSlow7) * fTemp1;
			let mut fRec3: F = fTemp2;
			*output0 = ((F::from(fSlow0) * (F::from(fSlow0) * fTemp0 + F::from(fSlow2) * fRec2) + F::from(fSlow8) * fRec3) as F);
			self.fRec0[1] = self.fRec0[0];
			self.fRec1[1] = self.fRec1[0];
		}
	}
}