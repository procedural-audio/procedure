use crate::*;

use pa_dsp::*;

pub struct DigitalFilter {
    selected: usize,
    cutoff: f32,
    q: f32,
}

pub struct DigitalFilterVoice {
    lp: SvfLpFilter<Stereo<f32>>,
    bp: SvfBpFilter<Stereo<f32>>,
    hp: SvfHpFilter<Stereo<f32>>
}

impl Module for DigitalFilter {
    type Voice = DigitalFilterVoice;

    const INFO: Info = Info {
        title: "Digital Filter",
        id: "default.effects.filters.digital_filter",
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
        path: &["Audio", "Spectral", "Digital Filter"],
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
            lp: SvfLpFilter::new(),
            bp: SvfBpFilter::new(),
            hp: SvfHpFilter::new()
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
        voice.lp.init(sample_rate as i32);
        voice.bp.init(sample_rate as i32);
        voice.hp.init(sample_rate as i32);
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
                voice.lp.set_freq(cutoff * 10000.0);
                voice.lp.set_q(0.5 + q * 4.0);
                voice.lp.compute(input.len() as i32, &[input], &mut [output]);
            }
            1 => {
                voice.bp.set_freq(cutoff * 10000.0);
                voice.bp.set_q(0.5 + q * 4.0);
                voice.bp.compute(input.len() as i32, &[input], &mut [output]);
            }
            2 => {
                voice.hp.set_freq(cutoff * 10000.0);
                voice.hp.set_q(0.5 + q * 4.0);
                voice.hp.compute(input.len() as i32, &[input], &mut [output]);
            }
            _ => ()
        }
    }
}

/*
import("stdfaust.lib");
freq = hslider("freq",0.5,0,1,0.001);
q = hslider("res",1,0.5,10,0.01);
process = fi.svf.lp(freq, q);
*/

pub struct SvfLpFilter<F: Sample> {
	fSampleRate: i32,
	fConst0: f32,
	fHslider0: f32,
	fHslider1: f32,
	fRec0: [F;2],
	fRec1: [F;2],
}

impl<F: Sample> SvfLpFilter<F> {
	fn new() -> Self {
		Self {
			fSampleRate: 0,
			fConst0: 0.0,
			fHslider0: 0.0,
			fHslider1: 0.0,
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
		self.fHslider0 = 0.5;
		self.fHslider1 = 1.0;
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

    fn set_q(&mut self, q: f32) {
        self.fHslider1 = q;
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

		let mut fSlow0: f32 = f32::tan(self.fConst0 * ((self.fHslider0) as f32));
		let mut fSlow1: f32 = fSlow0 * (1.0 / ((self.fHslider1) as f32) + fSlow0) + 1.0;
		let mut fSlow2: f32 = 2.0 / fSlow1;
		let mut fSlow3: f32 = fSlow0 / fSlow1;

		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			let mut fTemp0: F = ((*input0) as F);
			let mut fTemp1: F = self.fRec0[1] + F::from(fSlow0) * (fTemp0 - self.fRec1[1]);
			self.fRec0[0] = F::from(fSlow2) * fTemp1 - self.fRec0[1];
			let mut fTemp2: F = self.fRec1[1] + F::from(fSlow3) * fTemp1;
			self.fRec1[0] = F::from(2.0) * fTemp2 - self.fRec1[1];
			let mut fRec2: F = fTemp2;
			*output0 = ((fRec2) as F);
			self.fRec0[1] = self.fRec0[0];
			self.fRec1[1] = self.fRec1[0];
		}
	}
}

pub struct SvfHpFilter<F: Sample> {
	fSampleRate: i32,
	fConst0: f32,
	fHslider0: f32,
	fHslider1: f32,
	fRec0: [F;2],
	fRec1: [F;2],
}

impl<F: Sample> SvfHpFilter<F> {
	fn new() -> Self {
		Self {
			fSampleRate: 0,
			fConst0: 0.0,
			fHslider0: 0.0,
			fHslider1: 0.0,
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
		self.fHslider0 = 0.5;
		self.fHslider1 = 1.0;
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

    fn set_q(&mut self, q: f32) {
        self.fHslider1 = q;
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

		let mut fSlow0: f32 = f32::tan(self.fConst0 * ((self.fHslider0) as f32));
		let mut fSlow1: f32 = 1.0 / ((self.fHslider1) as f32);
		let mut fSlow2: f32 = fSlow0 * (fSlow1 + fSlow0) + 1.0;
		let mut fSlow3: f32 = 2.0 / fSlow2;
		let mut fSlow4: f32 = fSlow0 / fSlow2;
		let mut fSlow5: f32 = 1.0 / fSlow2;

		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			let mut fTemp0: F = ((*input0) as F);
			let mut fTemp1: F = self.fRec0[1] + F::from(fSlow0) * (fTemp0 - self.fRec1[1]);
			self.fRec0[0] = F::from(fSlow3) * fTemp1 - self.fRec0[1];
			let mut fTemp2: F = self.fRec1[1] + F::from(fSlow4) * fTemp1;
			self.fRec1[0] = F::from(2.0) * fTemp2 - self.fRec1[1];
			let mut fRec2: F = F::from(fSlow5) * fTemp1;
			let mut fRec3: F = fTemp2;
			*output0 = ((fTemp0 - (fRec3 + F::from(fSlow1) * fRec2)) as F);
			self.fRec0[1] = self.fRec0[0];
			self.fRec1[1] = self.fRec1[0];
		}
	}
}

pub struct SvfBpFilter<F: Sample> {
	fSampleRate: i32,
	fConst0: f32,
	fHslider0: f32,
	fHslider1: f32,
	fRec0: [F;2],
	fRec1: [F;2],
}

impl<F: Sample> SvfBpFilter<F> {
	fn new() -> Self {
		Self {
			fSampleRate: 0,
			fConst0: 0.0,
			fHslider0: 0.0,
			fHslider1: 0.0,
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
		self.fHslider0 = 0.5;
		self.fHslider1 = 1.0;
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

    fn set_q(&mut self, q: f32) {
        self.fHslider1 = q;
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

		let mut fSlow0: f32 = f32::tan(self.fConst0 * ((self.fHslider0) as f32));
		let mut fSlow1: f32 = fSlow0 * (1.0 / ((self.fHslider1) as f32) + fSlow0) + 1.0;
		let mut fSlow2: f32 = 2.0 / fSlow1;
		let mut fSlow3: f32 = fSlow0 / fSlow1;
		let mut fSlow4: f32 = 1.0 / fSlow1;

		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			let mut fTemp0: F = ((*input0) as F);
			let mut fTemp1: F = self.fRec0[1] + F::from(fSlow0) * (fTemp0 - self.fRec1[1]);
			self.fRec0[0] = F::from(fSlow2) * fTemp1 - self.fRec0[1];
			let mut fTemp2: F = self.fRec1[1] + F::from(fSlow3) * fTemp1;
			self.fRec1[0] = F::from(2.0) * fTemp2 - self.fRec1[1];
			let mut fRec2: F = F::from(fSlow4) * fTemp1;
			*output0 = ((fRec2) as F);
			self.fRec0[1] = self.fRec0[0];
			self.fRec1[1] = self.fRec1[0];
		}
	}
}
