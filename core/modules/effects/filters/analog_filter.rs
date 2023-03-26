use crate::*;

use pa_dsp::*;

pub struct AnalogFilter {
    selected: usize,
    cutoff: f32,
    resonance: f32,
}

pub struct AnalogFilterVoice {
    korg: [Korg35LPF; 2],
    /*diode: DiodeLPF,
    oberheim: OberheimLPF,
    ladder: LadderLPF,
    half_ladder: HalfLadderLPF,
    moog: MoogLPF,
    sallen_key: SallenKeyLPF,*/
}

impl Module for AnalogFilter {
    type Voice = AnalogFilterVoice;

    const INFO: Info = Info {
        title: "Analog Filter",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(200, 170),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 20),
            Pin::Control("Control Input", 50),
            Pin::Control("Control Input", 80),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 20)
        ],
        path: &["Audio Effects", "Filters", "Analog Filter"],
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
            korg: [Korg35LPF::new(), Korg35LPF::new()],
            /*diode: DiodeLPF::new(),
            oberheim: OberheimLPF::new(),
            ladder: LadderLPF::new(),
            half_ladder: HalfLadderLPF::new(),
            moog: MoogLPF::new(),
            sallen_key: SallenKeyLPF::new(),*/
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Stack {
            children: (
                Transform {
                    position: (50, 40 + 70),
                    size: (100, 40),
                    child: Dropdown {
                        index: &mut self.selected,
                        color: Color::BLUE,
                        elements: &[
                            "Korg 35",
                            "Diode",
                            "Oberheim",
                            "Ladder",
                            "Half Ladder",
                            "Moog",
                            "Sallen Key",
                        ],
                    },
                },
                Transform {
                    position: (40, 40),
                    size: (60, 70),
                    child: Knob {
                        text: "Cutoff", // Cutoff
                        color: Color::BLUE,
                        value: &mut self.cutoff,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70, 40),
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

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.korg[0].init(sample_rate as i32);
        voice.korg[1].init(sample_rate as i32);
        /*voice.diode.prepare(sample_rate, block_size);
        voice.oberheim.prepare(sample_rate, block_size);
        voice.ladder.prepare(sample_rate, block_size);
        voice.half_ladder.prepare(sample_rate, block_size);
        voice.moog.prepare(sample_rate, block_size);
        voice.sallen_key.prepare(sample_rate, block_size);*/
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let input = inputs.audio[0].as_slice();
        let output = outputs.audio[0].as_slice_mut();

        let cutoff = f32::clamp(inputs.control[0], 0.0, 1.0);

        match self.selected {
            _ => {
                voice.korg[0].set_param(0, cutoff);
                voice.korg[0].set_param(1, self.resonance);
                voice.korg[0].compute(input.len() as i32, &[input], &mut [output], true);

                voice.korg[1].set_param(0, cutoff);
                voice.korg[1].set_param(1, self.resonance);
                voice.korg[1].compute(input.len() as i32, &[input], &mut [output], false);
            }
            /*1 => {
                voice.diode.set_param(0, self.cutoff);
                voice.diode.set_param(1, self.resonance);
                voice.diode.process(&input, &mut output);
            }
            2 => {
                voice.oberheim.set_param(0, self.cutoff);
                voice.oberheim.set_param(1, self.resonance);
                voice.oberheim.process(&input, &mut output);
            }
            3 => {
                voice.ladder.set_param(0, self.cutoff);
                voice.ladder.set_param(1, self.resonance);
                voice.ladder.process(&input, &mut output);
            }
            4 => {
                voice.half_ladder.set_param(0, self.cutoff);
                voice.half_ladder.set_param(1, self.resonance);
                voice.half_ladder.process(&input, &mut output);
            }
            5 => {
                voice.moog.set_param(0, self.cutoff);
                voice.moog.set_param(1, self.resonance);
                voice.moog.process(&input, &mut output);
            }
            6 => {
                voice.sallen_key.set_param(0, self.cutoff);
                voice.sallen_key.set_param(1, self.resonance);
                voice.sallen_key.process(&input, &mut output);
            }
            _ => ()*/
        }
    }
}

/*faust!(Korg35LPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0,10,0.01);
    process = _,_ : ve.korg35LPF(freq, res), ve.korg35LPF(freq, res);
);

faust!(DiodeLPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0.5,10,0.01);
    process = _,_ : ve.diodeLadder(freq, res), ve.diodeLadder(freq, res);
);

faust!(OberheimLPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0.5,10,0.01);
    process = _,_ : ve.oberheimLPF(freq, res), ve.oberheimLPF(freq, res);
);

faust!(LadderLPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0.5,10,0.01);
    process = _,_ : ve.moogLadder(freq * 0.8, res), ve.moogLadder(freq * 0.8, res);
);

faust!(HalfLadderLPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0.5,10,0.01);
    process = _,_ : ve.moogHalfLadder(freq, res), ve.moogHalfLadder(freq, res);
);

faust!(MoogLPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0.5,10,0.01);
    process = _,_ : ve.moog_vcf(res, freq), ve.moog_vcf(res, freq);
);

faust!(SallenKeyLPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0.5,10,0.01);
    process = _,_ : ve.sallenKeyOnePoleLPF(freq), ve.sallenKeyOnePoleLPF(freq);
);*/

pub struct Korg35LPF {
	fSampleRate: i32,
	fConst1: f32,
	fConst2: f32,
	fHslider0: f32,
	fConst3: f32,
	fRec4: [f32;2],
	fHslider1: f32,
	fRec1: [f32;2],
	fRec2: [f32;2],
	fRec3: [f32;2],
}

impl Korg35LPF {
	fn new() -> Korg35LPF {
		Korg35LPF {
			fSampleRate: 0,
			fConst1: 0.0,
			fConst2: 0.0,
			fHslider0: 0.0,
			fConst3: 0.0,
			fRec4: [0.0;2],
			fHslider1: 0.0,
			fRec1: [0.0;2],
			fRec2: [0.0;2],
			fRec3: [0.0;2],
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
			self.fRec4[(l0) as usize] = 0.0;
		}
		for l1 in 0..2 {
			self.fRec1[(l1) as usize] = 0.0;
		}
		for l2 in 0..2 {
			self.fRec2[(l2) as usize] = 0.0;
		}
		for l3 in 0..2 {
			self.fRec3[(l3) as usize] = 0.0;
		}
	}
	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		let mut fConst0: f32 = f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32)));
		self.fConst1 = 6.28318548 / fConst0;
		self.fConst2 = 44.0999985 / fConst0;
		self.fConst3 = 1.0 - self.fConst2;
	}
	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}
	fn init(&mut self, sample_rate: i32) {
		Korg35LPF::class_init(sample_rate);
		self.instance_init(sample_rate);
	}

	fn get_param(&self, param: usize) -> Option<f32> {
		match param {
			0 => Some(self.fHslider0),
			1 => Some(self.fHslider1),
			_ => None,
		}
	}

	fn set_param(&mut self, param: usize, value: f32) {
		match param {
			0 => { self.fHslider0 = value }
			1 => { self.fHslider1 = value }
			_ => {}
		}
	}

	fn compute(&mut self, count: i32, inputs: &[&[Stereo2]], outputs: &mut[&mut[Stereo2]], left: bool) {
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
		let mut fSlow0: f32 = self.fConst2 * ((self.fHslider0) as f32);
		let mut fSlow1: f32 = 0.215215757 * (((self.fHslider1) as f32) + -0.707000017);
		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			self.fRec4[0] = fSlow0 + self.fConst3 * self.fRec4[1];
			let mut fTemp0: f32 = f32::tan(self.fConst1 * f32::powf(10.0, 3.0 * self.fRec4[0] + 1.0));
			let mut fTemp1: f32 = if left {
                (((input0.left) as f32) - self.fRec3[1]) * fTemp0
            } else {
                (((input0.right) as f32) - self.fRec3[1]) * fTemp0
            };

			let mut fTemp2: f32 = fTemp0 + 1.0;
			let mut fTemp3: f32 = 1.0 - fTemp0 / fTemp2;
			let mut fTemp4: f32 = (fTemp0 * ((self.fRec3[1] + (fTemp1 + fSlow1 * self.fRec1[1] * fTemp3) / fTemp2 + self.fRec2[1] * (0.0 - 1.0 / fTemp2)) / (1.0 - fSlow1 * (fTemp0 * fTemp3) / fTemp2) - self.fRec1[1])) / fTemp2;
			let mut fTemp5: f32 = self.fRec1[1] + fTemp4;
			let mut fRec0: f32 = fTemp5;
			self.fRec1[0] = self.fRec1[1] + 2.0 * fTemp4;
			self.fRec2[0] = self.fRec2[1] + 2.0 * (fTemp0 * (fSlow1 * fTemp5 - self.fRec2[1])) / fTemp2;
			self.fRec3[0] = self.fRec3[1] + 2.0 * fTemp1 / fTemp2;
            if left {
			    output0.left = ((fRec0) as f32);
            } else {
                output0.right = ((fRec0) as f32);
            };
			self.fRec4[1] = self.fRec4[0];
			self.fRec1[1] = self.fRec1[0];
			self.fRec2[1] = self.fRec2[0];
			self.fRec3[1] = self.fRec3[0];
		}
	}

}