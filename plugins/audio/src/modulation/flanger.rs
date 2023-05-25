use crate::*;

pub struct Flanger {
    delay: f32,
    offset: f32,
    speed: f32,
    depth: f32,
}

impl Module for Flanger {
    type Voice = (); // FlangerDsp;

    const INFO: Info = Info {
        title: "Flanger",
        id: "default.effects.modulation.flanger",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(310 - 40 - 70, 200),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Input", 20),
            Pin::Control("Control 1", 50)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 20)
        ],
        path: &["Audio", "Modulation", "Flanger"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Flanger {
            delay: 0.5,
            offset: 0.5,
            speed: 0.5,
            depth: 0.5,
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        () // FlangerDsp::new()
    }

    fn load(&mut self, _version: &str, _state: &State) {
        // Should use generics like serde
    }

    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        let _size = 50;

        return Box::new(Stack {
            children: (
                Transform {
                    position: (40 + 70 * 0, 40 + 80 * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Delay",
                        color: Color::BLUE,
                        value: &mut self.delay,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70 * 1, 40 + 80 * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Offset",
                        color: Color::BLUE,
                        value: &mut self.offset,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70 * 0, 40 + 80 * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "Speed",
                        color: Color::BLUE,
                        value: &mut self.speed,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70 * 1, 40 + 80 * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "Depth",
                        color: Color::BLUE,
                        value: &mut self.depth,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
            ),
        });
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        // voice.prepare(sample_rate, block_size);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        /*voice.process(
            &inputs.audio[0].as_array(),
            &mut outputs.audio[0].as_array_mut(),
        );*/
    }
}

/*faust!(FlangerDsp,
    import("math.lib");

    dmax = 2048;

    lfol = component("oscillator.lib").oscrs;
    lfor = component("oscillator.lib").oscrc;

    dflange = 0.001 * SR * hslider("[1] Flange Delay [unit:ms] [style:knob]", 10, 0, 20, 0.001);
    odflange = 0.001 * SR * hslider("[2] Delay Offset [unit:ms] [style:knob]", 1, 0, 20, 0.001);
    freq  = hslider("[1] Speed [unit:Hz] [style:knob]", 0.5, 0, 10, 0.01);
    depth = hslider("[2] Depth [style:knob]", 1, 0, 1, 0.001);
    fb = hslider("[3] Feedback [style:knob]", 0, -0.999, 0.999, 0.001);
    level = hslider("Flanger Output Level [unit:dB]", 0, -60, 10, 0.1) : db2linear;

    curdel1 = odflange+dflange*(1 + lfol(freq))/2;
    curdel2 = odflange+dflange*(1 + lfor(freq))/2;

    process = _,_ : pf.flanger_stereo(dmax,curdel1,curdel2,depth,fb,0) : _,_;
);*/

/*
import("stdfaust.lib");

dmax = 2048;
SR = 1;

lfol = component("oscillator.lib").oscrs;
lfor = component("oscillator.lib").oscrc;

dflange = 0.001 * SR * hslider("[1] Flange Delay [unit:ms] [style:knob]", 10, 0, 20, 0.001);
odflange = 0.001 * SR * hslider("[2] Delay Offset [unit:ms] [style:knob]", 1, 0, 20, 0.001);
freq  = hslider("[1] Speed [unit:Hz] [style:knob]", 0.5, 0, 10, 0.01);
depth = hslider("[2] Depth [style:knob]", 1, 0, 1, 0.001);
fb = hslider("[3] Feedback [style:knob]", 0, -0.999, 0.999, 0.001);
level = hslider("Flanger Output Level [unit:dB]", 0, -60, 10, 0.1) : db2linear;

curdel1 = odflange+dflange*(1 + lfol(freq))/2;
curdel2 = odflange+dflange*(1 + lfor(freq))/2;

process = _ : pf.flanger_mono(dmax,curdel1,curdel2,depth,fb,0);
 */

 pub struct FlangerDSP {
	fHslider0: f32,
	iVec0: [i32;2],
	IOTA0: i32,
	fVec1: Vec<f32>,
	fHslider1: f32,
	fHslider2: f32,
	fSampleRate: i32,
	fConst0: f32,
	fHslider3: f32,
	fRec1: [f32;2],
	fRec2: [f32;2],
	fRec0: [f32;2],
	fHslider4: f32,
}

impl FlangerDSP {
	fn new() -> Self {
		Self {
			fHslider0: 0.0,
			iVec0: [0;2],
			IOTA0: 0,
			fVec1: vec![0.0;4096],
			fHslider1: 0.0,
			fHslider2: 0.0,
			fSampleRate: 0,
			fConst0: 0.0,
			fHslider3: 0.0,
			fRec1: [0.0;2],
			fRec2: [0.0;2],
			fRec0: [0.0;2],
			fHslider4: 0.0,
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
		self.fHslider0 = 1.0;
		self.fHslider1 = 1.0;
		self.fHslider2 = 10.0;
		self.fHslider3 = 0.5;
		self.fHslider4 = 0.0;
	}

	fn instance_clear(&mut self) {
		for l0 in 0..2 {
			self.iVec0[(l0) as usize] = 0;
		}
		self.IOTA0 = 0;
		for l1 in 0..4096 {
			self.fVec1[(l1) as usize] = 0.0;
		}
		for l2 in 0..2 {
			self.fRec1[(l2) as usize] = 0.0;
		}
		for l3 in 0..2 {
			self.fRec2[(l3) as usize] = 0.0;
		}
		for l4 in 0..2 {
			self.fRec0[(l4) as usize] = 0.0;
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

	pub fn init(&mut self, sample_rate: i32, block_size: usize) {
		self.instance_init(sample_rate);
        self.fVec1 = vec![0.0; block_size];
	}

    pub fn set_delay(&mut self, delay: f32) {
        self.fHslider2 = f32::clamp(delay, 0.0, 1.0) * 20.0;
    }

    pub fn set_delay_offset(&mut self, delay: f32) {
        self.fHslider1 = f32::clamp(delay, 0.0, 1.0) * 20.0;
    }

    pub fn set_speed(&mut self, speed: f32) {
        self.fHslider3 = f32::clamp(speed, 0.0, 1.0) * 10.0;
    }

    pub fn set_feedback(&mut self, feedback: f32) {
        self.fHslider4 = f32::clamp(feedback, 0.0, 0.999);
    }

    pub fn set_depth(&mut self, depth: f32) {
        self.fHslider0 = f32::clamp(depth, 0.0, 1.0);
    }

	pub fn compute(&mut self, count: i32, inputs: &[&[f32]], outputs: &mut[&mut[f32]]) {
		let (outputs0) = if let [outputs0, ..] = outputs {
			let outputs0 = outputs0[..count as usize].iter_mut();
			(outputs0)
		} else {
			panic!("wrong number of outputs");
		};
		let mut fSlow0: f32 = ((self.fHslider0) as f32);
		let mut fSlow1: f32 = 0.00100000005 * ((self.fHslider1) as f32);
		let mut fSlow2: f32 = 0.000500000024 * ((self.fHslider2) as f32);
		let mut fSlow3: f32 = self.fConst0 * ((self.fHslider3) as f32);
		let mut fSlow4: f32 = f32::sin(fSlow3);
		let mut fSlow5: f32 = f32::cos(fSlow3);
		let mut iSlow6: i32 = ((((self.fHslider4) as f32)) as i32);
		let zipped_iterators = outputs0;
		for output0 in zipped_iterators {
			self.iVec0[0] = 1;
			let mut fTemp0: f32 = fSlow0 * self.fRec0[1];
			self.fVec1[(self.IOTA0 & 4095) as usize] = fTemp0;
			self.fRec1[0] = fSlow4 * self.fRec2[1] + fSlow5 * self.fRec1[1];
			self.fRec2[0] = (((1 - self.iVec0[1]) as f32) + fSlow5 * self.fRec2[1]) - fSlow4 * self.fRec1[1];
			let mut fTemp1: f32 = fSlow2 * (self.fRec1[0] + 1.0);
			let mut fTemp2: f32 = fSlow1 + fTemp1;
			let mut iTemp3: i32 = ((fTemp2.mono()) as i32);
			let mut fTemp4: f32 = f32::floor(fTemp2);
			self.fRec0[0] = self.fVec1[((self.IOTA0 - std::cmp::min(2049, std::cmp::max(0, iTemp3))) & 4095) as usize] * ((fTemp4 + 1.0 - fTemp1) - fSlow1) + (fSlow1 + fTemp1 - fTemp4) * self.fVec1[((self.IOTA0 - std::cmp::min(2049, std::cmp::max(0, iTemp3 + 1))) & 4095) as usize];
			let mut fTemp5: f32 = fSlow1 + fSlow2 * (self.fRec2[0] + 1.0);
			let mut fElse0: f32 = -1.0 * fTemp5;
			*output0 = ((0.5 * self.fRec0[0] * if (iSlow6 as i32 != 0) { fElse0 } else { fTemp5 }) as f32);
			self.iVec0[1] = self.iVec0[0];
			self.IOTA0 = self.IOTA0 + 1;
			self.fRec1[1] = self.fRec1[0];
			self.fRec2[1] = self.fRec2[0];
			self.fRec0[1] = self.fRec0[0];
		}
	}
}