use crate::*;

pub struct SawModule {
    wave_index: u32,
    freq: f32,
    glide: f32,
    other: f32,
}

pub struct SawModuleVoice {
    saw: Saw,
    active: bool,
    id: Id,
}

impl Module for SawModule {
    type Voice = SawModuleVoice;

    const INFO: Info = Info {
        title: "Saw",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes", 15)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 15)
        ],
        path: "Category 1/Category 2/Module Name"
    };

    fn new() -> Self {
        Self {
            wave_index: 0,
            freq: 100.0,
            glide: 0.0,
            other: 0.0,
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        Self::Voice {
            saw: Saw::new(),
            active: false,
            id: Id::new(),
        }
    }

    fn load(&mut self, json: &JSON) {
        self.freq = json.get("freq");
        self.wave_index = json.get("wave_index");
    }

    fn save(&self, json: &mut JSON) {
        json.insert("freq", self.freq);
        json.insert("wave_index", self.wave_index);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 25),
            size: (40, 40),
            child: Svg {
                path: "waveforms/saw.svg",
                color: Color::BLUE,
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, _block_size: usize) {
        voice.active = false;
        voice.id = Id::new();
        voice.saw.init(sample_rate as i32);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure } => {
                    voice.active = true;
                    voice.id = msg.id;
                    voice.saw.set_freq(pitch);
                }
                Event::NoteOff => {
                    if voice.id == msg.id {
                        voice.active = false;
                    }
                }
                Event::Pitch(freq) => {
                    if voice.id == msg.id {
                        voice.saw.set_freq(freq);
                    }
                }
                _ => (),
            }
        }

        if voice.active {
            let buffer = &mut outputs.audio[0];

            voice.saw.compute(
                buffer.len() as i32,
                &[],
                &mut [buffer.as_slice_mut()]
            );

            buffer.gain(0.1);
        }
    }
}

/* 
import("stdfaust.lib");
freq = hslider("freq[style:numerical]", 500, 20, 20000, 0.001) : si.smoo;
process = os.sawtooth(freq);
*/

/*faust!(Saw2,
    freq = hslider("freq[style:numerical]", 500, 20, 20000, 0.001) : si.smoo;
    process = os.sawtooth(freq);
);

faust!(Square2,
    freq = hslider("freq[style:numerical]", 500, 200, 12000, 0.001) : si.smoo;
    process = os.square(freq * driftosc);
);

faust!(Sine2,
    freq = hslider("freq[style:numerical]", 500, 200, 12000, 0.001) : si.smoo;
    process = os.osc(freq);
);

faust!(Triangle2,
    freq = hslider("freq[style:numerical]", 500, 200, 12000, 0.001) : si.smoo;
    process = os.triangle(freq);
);
*/

pub struct Saw {
	fSampleRate: i32,
	fConst0: f32,
	fConst1: f32,
	fConst2: f32,
	fHslider0: f32,
	fConst3: f32,
	fRec2: [f32;2],
	fRec0: [f32;2],
}

impl Saw {
	fn new() -> Saw {
		Saw {
			fSampleRate: 0,
			fConst0: 0.0,
			fConst1: 0.0,
			fConst2: 0.0,
			fHslider0: 0.0,
			fConst3: 0.0,
			fRec2: [0.0;2],
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

	fn class_init(sample_rate: i32) {
	}

	fn instance_reset_params(&mut self) {
		self.fHslider0 = 500.0;
	}

	fn instance_clear(&mut self) {
		for l0 in 0..2 {
			self.fRec2[(l0) as usize] = 0.0;
		}
		for l1 in 0..2 {
			self.fRec0[(l1) as usize] = 0.0;
		}
	}

	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		self.fConst0 = f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32)));
		self.fConst1 = 1.0 / self.fConst0;
		self.fConst2 = 44.0999985 / self.fConst0;
		self.fConst3 = 1.0 - self.fConst2;
	}

	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}

	fn init(&mut self, sample_rate: i32) {
		Saw::class_init(sample_rate);
		self.instance_init(sample_rate);
	}

	fn set_freq(&mut self, hz: f32) {
        self.fHslider0 = hz;
	}

	fn compute(&mut self, count: i32, inputs: &[&[Stereo2]], outputs: &mut [&mut [Stereo2]]) {
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
			let mut fTemp0: f32 = f32::max(1.1920929e-07, f32::abs(self.fRec2[0]));
			let mut fTemp1: f32 = self.fRec0[1] + self.fConst1 * fTemp0;
			let mut fTemp2: f32 = fTemp1 + -1.0;
			let mut iTemp3: i32 = ((fTemp2 < 0.0) as i32);
			self.fRec0[0] = if (iTemp3 as i32 != 0) { fTemp1 } else { fTemp2 };
			let mut fThen1: f32 = fTemp1 + (1.0 - self.fConst0 / fTemp0) * fTemp2;
			let mut fRec1: f32 = if (iTemp3 as i32 != 0) { fTemp1 } else { fThen1 };
			*output0 = ((Stereo2{left: 2.0, right: 2.0} * Stereo2{left: fRec1, right: fRec1} + Stereo2{left: -1.0, right: -1.0}));
			self.fRec2[1] = self.fRec2[0];
			self.fRec0[1] = self.fRec0[0];
		}
	}
}