use crate::*;

use pa_dsp::*;

// TODO: Implement resonance. Add high pass, band pass filters.
pub struct AnalogFilter {
    selected: usize,
    cutoff: f32,
    resonance: f32,
}

pub struct AnalogFilterVoice {
    korg: Korg35LPF<Stereo<f32>>,
    diode: DiodeLPF<Stereo<f32>>,
    oberheim: OberheimLPF<Stereo<f32>>,
    ladder: MoogLadderLPF<Stereo<f32>>,
    half_ladder: HalfLadderLPF<Stereo<f32>>,
    sallen_key: SallenKeyLPF<Stereo<f32>>,
}

impl Module for AnalogFilter {
    type Voice = AnalogFilterVoice;

    const INFO: Info = Info {
        title: "Analog Filter",
        id: "default.effects.filters.analog_filter",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(200, 160),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 20),
            Pin::Control("Control Input", 50),
            Pin::Control("Control Input", 80),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 20)
        ],
        path: &["Audio", "Spectral", "Analog Filter"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            selected: 0,
            cutoff: 1.0,
            resonance: 0.0,
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            korg: Korg35LPF::new(),
            diode: DiodeLPF::new(),
            oberheim: OberheimLPF::new(),
            ladder: MoogLadderLPF::new(),
            half_ladder: HalfLadderLPF::new(),
            sallen_key: SallenKeyLPF::new(),
        }
    }

    fn load(&mut self, _version: &str, state: &State) {
		self.selected = state.load("selected");
        self.cutoff = state.load("cutoff");
        self.resonance = state.load("resonance");
    }

    fn save(&self, state: &mut State) {
		state.save("selected", self.selected);
        state.save("cutoff", self.cutoff);
        state.save("resonance", self.resonance);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Stack {
            children: (
                Transform {
                    position: (40, 110),
                    size: (120, 40),
                    child: Dropdown {
                        index: &mut self.selected,
                        color: Color::BLUE,
                        elements: &[
                            "Korg 35",
                            "Diode",
                            "Oberheim",
                            "Ladder",
                            "Half Ladder",
                            "Sallen Key",
                        ],
                    },
                },
                Transform {
                    position: (40, 35),
                    size: (60, 70),
                    child: Knob {
                        text: "Cutoff", // Cutoff
                        color: Color::BLUE,
                        value: &mut self.cutoff,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70, 35),
                    size: (60, 70),
                    child: Knob {
                        text: "Res", // Resonance
                        color: Color::BLUE,
                        value: &mut self.resonance,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
            ),
        });
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, _block_size: usize) {
        voice.korg.init(sample_rate as i32);
        voice.diode.init(sample_rate as i32);
		voice.oberheim.init(sample_rate as i32);
		voice.ladder.init(sample_rate as i32);
		voice.half_ladder.init(sample_rate as i32);
        voice.sallen_key.init(sample_rate as i32);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let input = inputs.audio[0].as_slice();
        let output = outputs.audio[0].as_slice_mut();

        let mut cutoff = self.cutoff;
		if inputs.control.connected(0) {
        	cutoff = f32::clamp(inputs.control[0], 0.0, 1.0);
		}

        /*let mut res = self.resonance;
		if inputs.control.connected(1) {
        	res = f32::clamp(inputs.control[1], 0.0, 1.0);
		}*/

        match self.selected {
            0 => {
                voice.korg.set_cutoff(cutoff);
				// voice.korg.set_res(res);
                voice.korg.compute(input.len() as i32, &[input], &mut [output]);
            }
            1 => {
                voice.diode.set_cutoff(cutoff);
				// voice.diode.set_res(res);
                voice.diode.compute(input.len() as i32, &[input], &mut [output]);
            }
            2 => {
				voice.oberheim.set_cutoff(cutoff);
				// voice.oberheim.set_res(res);
				voice.oberheim.compute(input.len() as i32, &[input], &mut [output]);
            }
            3 => {
				voice.ladder.set_cutoff(cutoff);
				// voice.ladder.set_res(res);
				voice.ladder.compute(input.len() as i32, &[input], &mut [output]);
            }
            4 => {
				voice.half_ladder.set_cutoff(cutoff);
				// voice.half_ladder.set_res(res);
				voice.half_ladder.compute(input.len() as i32, &[input], &mut [output]);
            }
            5 => {
				voice.sallen_key.set_cutoff(cutoff);
				// voice.sallen_key.set_res(res);
				voice.sallen_key.compute(input.len() as i32, &[input], &mut [output]);
            }
            _ => ()
        }
    }
}

/*
import("stdfaust.lib");
freq = hslider("freq",0.5,0,1,0.001);
res = hslider("res",1,0,10,0.01);
process = ve.korg35LPF(freq, res);
*/

pub struct Korg35LPF<F: Sample> {
	fSampleRate: i32,
	fConst0: f32,
	fHslider0: f32,
	fHslider1: f32,
	fRec0: [F;2],
	fRec1: [F;2],
	fRec2: [F;2],
}

impl<F: Sample> Korg35LPF<F> {
	fn new() -> Self {
		Self {
			fSampleRate: 0,
			fConst0: 0.0,
			fHslider0: 0.0,
			fHslider1: 0.0,
			fRec0: [F::EQUILIBRIUM;2],
			fRec1: [F::EQUILIBRIUM;2],
			fRec2: [F::EQUILIBRIUM;2],
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
			self.fRec0[(l0) as usize] = F::EQUILIBRIUM;
		}
		for l1 in 0..2 {
			self.fRec1[(l1) as usize] = F::EQUILIBRIUM;
		}
		for l2 in 0..2 {
			self.fRec2[(l2) as usize] = F::EQUILIBRIUM;
		}
	}

	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		self.fConst0 = 6.28318548 / f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32)));
	}

	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}

	fn init(&mut self, sample_rate: i32) {
		self.instance_init(sample_rate);
	}

	fn get_cutoff(&self) -> f32 {
		return self.fHslider0;
	}

	fn set_cutoff(&mut self, freq: f32) {
		self.fHslider0 = freq;
	}

	fn get_res(&self) -> f32 {
		return self.fHslider1;
	}

	fn set_res(&mut self, res: f32) {
		self.fHslider1 = res;
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
		let mut fSlow0: f32 = f32::tan(self.fConst0 * f32::powf(10.0, 3.0 * ((self.fHslider0) as f32) + 1.0));
		let mut fSlow1: f32 = fSlow0 + 1.0;
		let mut fSlow2: f32 = fSlow0 / fSlow1;
		let mut fSlow3: f32 = 2.0 * fSlow2;
		let mut fSlow4: f32 = ((self.fHslider1) as f32) + -0.707000017;
		let mut fSlow5: f32 = 1.0 - fSlow2;
		let mut fSlow6: f32 = 1.0 / (1.0 - 0.215215757 * (fSlow0 * fSlow4 * fSlow5) / fSlow1);
		let mut fSlow7: f32 = 1.0 / fSlow1;
		let mut fSlow8: f32 = 0.215215757 * fSlow4 * fSlow5;
		let mut fSlow9: f32 = 0.0 - fSlow7;
		let mut fSlow10: f32 = 0.215215757 * fSlow4;
		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			let mut fTemp0: F = ((*input0)) - self.fRec2[1];
			let mut fTemp1: F = F::from_f32(fSlow6) * (self.fRec2[1] + F::from_f32(fSlow7) * (F::from_f32(fSlow0) * fTemp0 + F::from_f32(fSlow8) * self.fRec0[1]) + F::from_f32(fSlow9) * self.fRec1[1]) - self.fRec0[1];
			self.fRec0[0] = self.fRec0[1] + F::from_f32(fSlow3) * fTemp1;
			let mut fTemp2: F = self.fRec0[1] + F::from_f32(fSlow2) * fTemp1;
			self.fRec1[0] = self.fRec1[1] + F::from_f32(fSlow3) * (F::from_f32(fSlow10) * fTemp2 - self.fRec1[1]);
			self.fRec2[0] = self.fRec2[1] + F::from_f32(fSlow3) * fTemp0;
			let mut fRec3: F = fTemp2;
			*output0 = ((fRec3) as F);
			self.fRec0[1] = self.fRec0[0];
			self.fRec1[1] = self.fRec1[0];
			self.fRec2[1] = self.fRec2[0];
		}
	}
}

/*
import("stdfaust.lib");
freq = hslider("freq",0.5,0,1,0.001);
res = hslider("res",1,0.5,10,0.01);
process = ve.diodeLadder(freq, res);
*/

fn mydsp_faustpower2_f<F: Sample>(value: F) -> F {
	return value * value;
}
fn mydsp_faustpower10_f<F: Sample>(value: F) -> F {
	return value * value * value * value * value * value * value * value * value * value;
}
fn mydsp_faustpower3_f<F: Sample>(value: F) -> F {
	return value * value * value;
}
fn mydsp_faustpower4_f<F: Sample>(value: F) -> F {
	return value * value * value * value;
}

pub struct DiodeLPF<F: Sample> {
	fSampleRate: i32,
	fConst0: f32,
	fHslider0: f32,
	fHslider1: f32,
	fRec0: [F;2],
	fRec1: [F;2],
	fRec2: [F;2],
	fRec3: [F;2],
}

impl<F: Sample> DiodeLPF<F> {
	fn new() -> Self {
		Self {
			fSampleRate: 0,
			fConst0: 0.0,
			fHslider0: 0.0,
			fHslider1: 0.0,
			fRec0: [F::EQUILIBRIUM;2],
			fRec1: [F::EQUILIBRIUM;2],
			fRec2: [F::EQUILIBRIUM;2],
			fRec3: [F::EQUILIBRIUM;2],
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
			self.fRec0[(l0) as usize] = F::EQUILIBRIUM;
		}
		for l1 in 0..2 {
			self.fRec1[(l1) as usize] = F::EQUILIBRIUM;
		}
		for l2 in 0..2 {
			self.fRec2[(l2) as usize] = F::EQUILIBRIUM;
		}
		for l3 in 0..2 {
			self.fRec3[(l3) as usize] = F::EQUILIBRIUM;
		}
	}

	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		self.fConst0 = 6.28318548 / f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32)));
	}

	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}

	fn init(&mut self, sample_rate: i32) {
		self.instance_init(sample_rate);
	}

	fn get_cutoff(&self) -> f32 {
		return self.fHslider0;
	}

	fn set_cutoff(&mut self, freq: f32) {
		self.fHslider0 = freq;
	}

	fn get_res(&self) -> f32 {
		return self.fHslider1;
	}

	fn set_res(&mut self, res: f32) {
		self.fHslider1 = res;
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
		let mut fSlow0: f32 = ((self.fHslider0) as f32);
		let mut fSlow1: f32 = f32::tan(self.fConst0 * f32::powf(10.0, 3.0 * fSlow0 + 1.0));
		let mut fSlow2: f32 = fSlow1 + 1.0;
		let mut fSlow3: f32 = fSlow1 / fSlow2;
		let mut fSlow4: f32 = 2.0 * fSlow3;
		let mut fSlow5: f32 = mydsp_faustpower2_f(fSlow1);
		let mut fSlow6: f32 = fSlow1 * (1.0 - 0.25 * fSlow3) + 1.0;
		let mut fSlow7: f32 = fSlow2 * fSlow6;
		let mut fSlow8: f32 = 0.25 * fSlow5 / fSlow7 + 1.0;
		let mut fSlow9: f32 = fSlow1 / fSlow6;
		let mut fSlow10: f32 = fSlow1 * (1.0 - 0.25 * fSlow9) + 1.0;
		let mut fSlow11: f32 = fSlow6 * fSlow10;
		let mut fSlow12: f32 = 0.25 * fSlow5 / fSlow11 + 1.0;
		let mut fSlow13: f32 = fSlow1 / fSlow10;
		let mut fSlow14: f32 = 0.5 * fSlow13;
		let mut fSlow15: f32 = fSlow1 * (1.0 - fSlow14) + 1.0;
		let mut fSlow16: f32 = 17.0 - 9.69999981 * mydsp_faustpower10_f(fSlow0);
		let mut fSlow17: f32 = ((self.fHslider1) as f32) + -0.707000017;
		let mut fSlow18: f32 = (0.5 * fSlow5 / (fSlow10 * fSlow15) + 1.0) / (0.00514551532 * (mydsp_faustpower4_f(fSlow1) * fSlow16 * fSlow17) / (fSlow7 * fSlow10 * fSlow15) + 1.0);
		let mut fSlow19: f32 = (fSlow16 * fSlow17) / fSlow2;
		let mut fSlow20: f32 = 0.0205820613 * fSlow9;
		let mut fSlow21: f32 = 0.5 * fSlow3;
		let mut fSlow22: f32 = 0.0205820613 * fSlow13;
		let mut fSlow23: f32 = 0.5 * fSlow9;
		let mut fSlow24: f32 = 0.00514551532 * mydsp_faustpower3_f(fSlow1) / (fSlow11 * fSlow15);
		let mut fSlow25: f32 = 1.0 / fSlow10;
		let mut fSlow26: f32 = 0.5 * fSlow1 / fSlow15;
		let mut fSlow27: f32 = 1.0 / fSlow6;
		let mut fSlow28: f32 = 1.0 / fSlow2;
		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			let mut fTemp0: F = F::max(F::from_f32(-1.0), F::min(F::from_f32(1.0), ((*input0) as F)));
			let mut fTemp1: F = F::from_f32(fSlow21) * self.fRec0[1] + self.fRec1[1];
			let mut fTemp2: F = F::from_f32(fSlow23) * fTemp1;
			let mut fTemp3: F = fTemp2 + self.fRec2[1];
			let mut fTemp4: F = F::from_f32(fSlow13) * fTemp3 + self.fRec3[1];
			let mut fTemp5: F = (F::from_f32(fSlow18) * (F::from_f32(1.5) * fTemp0 * (F::from_f32(1.0) - F::from_f32(0.333333343) * mydsp_faustpower2_f(fTemp0)) + F::from_f32(fSlow19) * (F::EQUILIBRIUM - (F::from_f32(0.0411641225) * self.fRec0[1] + F::from_f32(fSlow20) * fTemp1) - F::from_f32(fSlow22) * fTemp3 - F::from_f32(fSlow24) * fTemp4)) + F::from_f32(fSlow25) * (fTemp3 + F::from_f32(fSlow26) * fTemp4)) - self.fRec3[1];
			let mut fTemp6: F = F::from_f32(0.5) * (F::from_f32(fSlow12) * (self.fRec3[1] + F::from_f32(fSlow3) * fTemp5) + F::from_f32(fSlow27) * (fTemp1 + F::from_f32(fSlow14) * fTemp3)) - self.fRec2[1];
			let mut fTemp7: F = F::from_f32(0.5) * (F::from_f32(fSlow8) * (self.fRec2[1] + F::from_f32(fSlow3) * fTemp6) + F::from_f32(fSlow28) * (self.fRec0[1] + fTemp2)) - self.fRec1[1];
			let mut fTemp8: F = F::from_f32(0.5) * (self.fRec1[1] + F::from_f32(fSlow3) * fTemp7) - self.fRec0[1];
			self.fRec0[0] = self.fRec0[1] + F::from_f32(fSlow4) * fTemp8;
			self.fRec1[0] = self.fRec1[1] + F::from_f32(fSlow4) * fTemp7;
			self.fRec2[0] = self.fRec2[1] + F::from_f32(fSlow4) * fTemp6;
			self.fRec3[0] = self.fRec3[1] + F::from_f32(fSlow4) * fTemp5;
			let mut fRec4: F = self.fRec0[1] + F::from_f32(fSlow3) * fTemp8;
			*output0 = ((fRec4) as F);
			self.fRec0[1] = self.fRec0[0];
			self.fRec1[1] = self.fRec1[0];
			self.fRec2[1] = self.fRec2[0];
			self.fRec3[1] = self.fRec3[0];
		}
	}
}

/*
import("stdfaust.lib");
freq = hslider("freq",0.5,0,1,0.001);
res = hslider("res",1,0.5,10,0.01);
process = ve.oberheimLPF(freq, res);
*/

pub struct OberheimLPF<F: Sample> {
	fSampleRate: i32,
	fConst0: f32,
	fHslider0: f32,
	fHslider1: f32,
	fRec0: [F;2],
	fRec1: [F;2],
}

impl<F: Sample> OberheimLPF<F> {
	fn new() -> Self {
		Self {
			fSampleRate: 0,
			fConst0: 0.0,
			fHslider0: 0.0,
			fHslider1: 0.0,
			fRec0: [F::EQUILIBRIUM;2],
			fRec1: [F::EQUILIBRIUM;2],
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

	fn class_init(sample_rate: i32) {
	}
	fn instance_reset_params(&mut self) {
		self.fHslider0 = 0.5;
		self.fHslider1 = 1.0;
	}

	fn instance_clear(&mut self) {
		for l0 in 0..2 {
			self.fRec0[(l0) as usize] = F::EQUILIBRIUM;
		}
		for l1 in 0..2 {
			self.fRec1[(l1) as usize] = F::EQUILIBRIUM;
		}
	}
	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		self.fConst0 = 6.28318548 / f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32)));
	}
	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}

	fn init(&mut self, sample_rate: i32) {
		self.instance_init(sample_rate);
	}

	fn get_cutoff(&self) -> f32 {
		return self.fHslider0;
	}

	fn set_cutoff(&mut self, freq: f32) {
		self.fHslider0 = freq;
	}

	fn get_res(&self) -> f32 {
		return self.fHslider1;
	}

	fn set_res(&mut self, res: f32) {
		self.fHslider1 = res;
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
		let mut fSlow0: f32 = f32::tan(self.fConst0 * f32::powf(10.0, 3.0 * ((self.fHslider0) as f32) + 1.0));
		let mut fSlow1: f32 = 2.0 * fSlow0;
		let mut fSlow2: f32 = 1.0 / ((self.fHslider1) as f32) + fSlow0;
		let mut fSlow3: f32 = fSlow0 * fSlow2 + 1.0;
		let mut fSlow4: f32 = fSlow0 / fSlow3;
		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			let mut fTemp0: F = ((*input0)) - (self.fRec0[1] + F::from_f32(fSlow2) * self.fRec1[1]);
			let mut fTemp1: F = F::from_f32(fSlow4) * fTemp0;
			let mut fTemp2: F = F::max(F::from_f32(-1.0), F::min(F::from_f32(1.0), self.fRec1[1] + fTemp1));
			let mut fTemp3: F = fTemp2 * (F::from_f32(1.0) - F::from_f32(0.333333343) * mydsp_faustpower2_f(fTemp2));
			self.fRec0[0] = self.fRec0[1] + F::from_f32(fSlow1) * fTemp3;
			self.fRec1[0] = fTemp1 + fTemp3;
			let mut fTemp4: F = F::from_f32(fSlow0) * fTemp3;
			let mut fRec2: F = self.fRec0[1] + fTemp4;
			*output0 = fRec2;
			self.fRec0[1] = self.fRec0[0];
			self.fRec1[1] = self.fRec1[0];
		}
	}
}

/*
import("stdfaust.lib");
freq = hslider("freq",0.5,0,1,0.001);
res = hslider("res",1,0.5,10,0.01);
process = ve.moogLadder(freq, res);
*/

pub struct MoogLadderLPF<F: Sample> {
	fHslider0: f32,
	fHslider1: f32,
	fRec0: [F;2],
	fRec1: [F;2],
	fRec2: [F;2],
	fRec3: [F;2],
	fSampleRate: i32,
}

impl<F: Sample> MoogLadderLPF<F> {
	fn new() -> Self {
		Self {
			fHslider0: 0.0,
			fHslider1: 0.0,
			fRec0: [F::EQUILIBRIUM;2],
			fRec1: [F::EQUILIBRIUM;2],
			fRec2: [F::EQUILIBRIUM;2],
			fRec3: [F::EQUILIBRIUM;2],
			fSampleRate: 0,
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
			self.fRec0[(l0) as usize] = F::EQUILIBRIUM;
		}
		for l1 in 0..2 {
			self.fRec1[(l1) as usize] = F::EQUILIBRIUM;
		}
		for l2 in 0..2 {
			self.fRec2[(l2) as usize] = F::EQUILIBRIUM;
		}
		for l3 in 0..2 {
			self.fRec3[(l3) as usize] = F::EQUILIBRIUM;
		}
	}

	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
	}

	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}

	fn init(&mut self, sample_rate: i32) {
		self.instance_init(sample_rate);
	}

	fn get_cutoff(&self) -> f32 {
		return self.fHslider0;
	}

	fn set_cutoff(&mut self, freq: f32) {
		self.fHslider0 = freq;
	}

	fn get_res(&self) -> f32 {
		return self.fHslider1;
	}

	fn set_res(&mut self, res: f32) {
		self.fHslider1 = res;
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
		let mut fSlow0: f32 = f32::tan(1.57079637 * ((self.fHslider0) as f32));
		let mut fSlow1: f32 = fSlow0 + 1.0;
		let mut fSlow2: f32 = fSlow0 / fSlow1;
		let mut fSlow3: f32 = 2.0 * fSlow2;
		let mut fSlow4: f32 = ((self.fHslider1) as f32) + -0.707000017;
		let mut fSlow5: f32 = 1.0 / (0.16465649 * (mydsp_faustpower4_f(fSlow0) * fSlow4) / mydsp_faustpower4_f(fSlow1) + 1.0);
		let mut fSlow6: f32 = 0.16465649 * fSlow4 * (1.0 - fSlow2);
		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			let mut fTemp0: F = F::from_f32(fSlow5) * (((*input0)) - F::from_f32(fSlow6) * (self.fRec3[1] + F::from_f32(fSlow2) * (self.fRec2[1] + F::from_f32(fSlow2) * (self.fRec1[1] + F::from_f32(fSlow2) * self.fRec0[1])))) - self.fRec0[1];
			self.fRec0[0] = self.fRec0[1] + F::from_f32(fSlow3) * fTemp0;
			let mut fTemp1: F = (self.fRec0[1] + F::from_f32(fSlow2) * fTemp0) - self.fRec1[1];
			self.fRec1[0] = self.fRec1[1] + F::from_f32(fSlow3) * fTemp1;
			let mut fTemp2: F = (self.fRec1[1] + F::from_f32(fSlow2) * fTemp1) - self.fRec2[1];
			self.fRec2[0] = self.fRec2[1] + F::from_f32(fSlow3) * fTemp2;
			let mut fTemp3: F = (self.fRec2[1] + F::from_f32(fSlow2) * fTemp2) - self.fRec3[1];
			self.fRec3[0] = self.fRec3[1] + F::from_f32(fSlow3) * fTemp3;
			let mut fRec4: F = self.fRec3[1] + F::from_f32(fSlow2) * fTemp3;
			*output0 = fRec4;
			self.fRec0[1] = self.fRec0[0];
			self.fRec1[1] = self.fRec1[0];
			self.fRec2[1] = self.fRec2[0];
			self.fRec3[1] = self.fRec3[0];
		}
	}
}

/*
import("stdfaust.lib");
freq = hslider("freq",0.5,0,1,0.001);
res = hslider("res",1,0.5,10,0.01);
process = ve.moogHalfLadder(freq, res);
*/

pub struct HalfLadderLPF<F: Sample> {
	fSampleRate: i32,
	fConst0: f32,
	fHslider0: f32,
	fHslider1: f32,
	fRec0: [F;2],
	fRec1: [F;2],
	fRec2: [F;2],
}

impl<F: Sample> HalfLadderLPF<F> {
	fn new() -> Self {
		Self {
			fSampleRate: 0,
			fConst0: 0.0,
			fHslider0: 0.0,
			fHslider1: 0.0,
			fRec0: [F::EQUILIBRIUM;2],
			fRec1: [F::EQUILIBRIUM;2],
			fRec2: [F::EQUILIBRIUM;2],
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
			self.fRec0[(l0) as usize] = F::EQUILIBRIUM;
		}
		for l1 in 0..2 {
			self.fRec1[(l1) as usize] = F::EQUILIBRIUM;
		}
		for l2 in 0..2 {
			self.fRec2[(l2) as usize] = F::EQUILIBRIUM;
		}
	}

	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		self.fConst0 = 6.28318548 / f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32)));
	}

	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}
	fn init(&mut self, sample_rate: i32) {
		self.instance_init(sample_rate);
	}

	fn get_cutoff(&self) -> f32 {
		return self.fHslider0;
	}

	fn set_cutoff(&mut self, freq: f32) {
		self.fHslider0 = freq;
	}

	fn get_res(&self) -> f32 {
		return self.fHslider1;
	}

	fn set_res(&mut self, res: f32) {
		self.fHslider1 = res;
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
		let mut fSlow0: f32 = f32::tan(self.fConst0 * f32::powf(10.0, 3.0 * ((self.fHslider0) as f32) + 1.0));
		let mut fSlow1: f32 = fSlow0 + 1.0;
		let mut fSlow2: f32 = fSlow0 / fSlow1;
		let mut fSlow3: f32 = 2.0 * fSlow2;
		let mut fSlow4: f32 = ((self.fHslider1) as f32) + -0.707000017;
		let mut fSlow5: f32 = fSlow3 + -1.0;
		let mut fSlow6: f32 = 1.0 / (0.082328245 * (mydsp_faustpower2_f(fSlow0) * fSlow4 * fSlow5) / mydsp_faustpower2_f(fSlow1) + 1.0);
		let mut fSlow7: f32 = fSlow4 / fSlow1;
		let mut fSlow8: f32 = 0.082328245 * fSlow5;
		let mut fSlow9: f32 = 0.082328245 * (fSlow0 * fSlow5) / fSlow1;
		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			let mut fTemp0: F = F::from_f32(fSlow6) * (((*input0)) + F::from_f32(fSlow7) * (F::EQUILIBRIUM - (F::from_f32(0.16465649) * self.fRec0[1] + F::from_f32(fSlow8) * self.fRec1[1]) - F::from_f32(fSlow9) * self.fRec2[1])) - self.fRec2[1];
			let mut fTemp1: F = (self.fRec2[1] + F::from_f32(fSlow2) * fTemp0) - self.fRec1[1];
			let mut fTemp2: F = self.fRec1[1] + F::from_f32(fSlow2) * fTemp1;
			let mut fTemp3: F = fTemp2 - self.fRec0[1];
			self.fRec0[0] = self.fRec0[1] + F::from_f32(fSlow3) * fTemp3;
			self.fRec1[0] = self.fRec1[1] + F::from_f32(fSlow3) * fTemp1;
			self.fRec2[0] = self.fRec2[1] + F::from_f32(fSlow3) * fTemp0;
			let mut fRec3: F = F::from_f32(2.0) * (self.fRec0[1] + F::from_f32(fSlow2) * fTemp3) - fTemp2;
			*output0 = ((fRec3) as F);
			self.fRec0[1] = self.fRec0[0];
			self.fRec1[1] = self.fRec1[0];
			self.fRec2[1] = self.fRec2[0];
		}
	}
}

/*
import("stdfaust.lib")
freq = hslider("freq",0.5,0,1,0.001);
res = hslider("res",1,0.5,10,0.01);
process = ve.sallenKey2ndOrderLPF(freq, res);
*/

pub struct SallenKeyLPF<F: Sample> {
	fSampleRate: i32,
	fConst0: f32,
	fHslider0: f32,
	fHslider1: f32,
	fRec0: [F;2],
	fRec1: [F;2],
}

impl<F: Sample> SallenKeyLPF<F> {
	fn new() -> Self {
		Self {
			fSampleRate: 0,
			fConst0: 0.0,
			fHslider0: 0.0,
			fHslider1: 0.0,
			fRec0: [F::EQUILIBRIUM;2],
			fRec1: [F::EQUILIBRIUM;2],
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
			self.fRec0[(l0) as usize] = F::EQUILIBRIUM;
		}
		for l1 in 0..2 {
			self.fRec1[(l1) as usize] = F::EQUILIBRIUM;
		}
	}
	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		self.fConst0 = 6.28318548 / f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32)));
	}
	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}
	fn init(&mut self, sample_rate: i32) {
		self.instance_init(sample_rate);
	}

	fn get_cutoff(&self) -> f32 {
		return self.fHslider0;
	}

	fn set_cutoff(&mut self, freq: f32) {
		self.fHslider0 = freq;
	}

	fn get_res(&self) -> f32 {
		return self.fHslider1;
	}

	fn set_res(&mut self, res: f32) {
		self.fHslider1 = res;
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
		let mut fSlow0: f32 = f32::tan(self.fConst0 * f32::powf(10.0, 3.0 * ((self.fHslider0) as f32) + 1.0));
		let mut fSlow1: f32 = 2.0 * fSlow0;
		let mut fSlow2: f32 = 1.0 / ((self.fHslider1) as f32) + fSlow0;
		let mut fSlow3: f32 = fSlow0 * fSlow2 + 1.0;
		let mut fSlow4: f32 = fSlow0 / fSlow3;
		let mut fSlow5: f32 = 2.0 * fSlow4;
		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			let mut fTemp0: F = ((*input0) as F) - (self.fRec0[1] + F::from_f32(fSlow2) * self.fRec1[1]);
			let mut fTemp1: F = self.fRec1[1] + F::from_f32(fSlow4) * fTemp0;
			self.fRec0[0] = self.fRec0[1] + F::from_f32(fSlow1) * fTemp1;
			let mut fTemp2: F = self.fRec1[1] + F::from_f32(fSlow5) * fTemp0;
			self.fRec1[0] = fTemp2;
			let mut fRec2: F = self.fRec0[1] + F::from_f32(fSlow0) * fTemp2;
			*output0 = ((fRec2) as F);
			self.fRec0[1] = self.fRec0[0];
			self.fRec1[1] = self.fRec1[0];
		}
	}
}