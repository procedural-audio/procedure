use std::sync::{Arc, RwLock};

use crate::*;

pub struct Sampler {
    sample: Arc<RwLock<SampleFile<Stereo2>>>,
}

pub struct SamplerVoice {
    index: u32,
    player: PitchedSamplePlayer2<Stereo2>,
    lpf_left: TempLPF,
    lpf_right: TempLPF
}

impl Module for Sampler {
    type Voice = SamplerVoice;

    const INFO: Info = Info {
        title: "Sampler",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(390-35*2, 200),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 10)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 10)
        ],
        path: "Category 1/Category 2/Module Name"
    };

    fn new() -> Self {
        let path = if cfg!(target_os = "macos") {
            "/Users/chasekanipe/guitar_samples/Samples/FlamencoDreams_55_C2_G_2.wav"
        } else if cfg!(target_os = "linux") {
            "/home/chase/guitar_samples/Samples/FlamencoDreams_55_C2_G_2.wav"
        } else {
            todo!()
        };

        return Self {
            sample: Arc::new(RwLock::new(SampleFile::load(path)))
        };
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        let player = PitchedSamplePlayer2::new();

        Self::Voice {
            index,
            player,
            lpf_left: TempLPF::new(),
            lpf_right: TempLPF::new()
        }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Stack {
            children: (Padding {
                padding: (5, 35, 5, 5),
                child: SampleFilePicker {
                    sample: self.sample.clone()
                }
            })
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure: _ } => {
                    if let Ok(sample) = self.sample.try_read() {
                        voice.player.set_sample(sample.clone());
                    } else {
                        println!("Couldn't update sample");
                    }

                    voice.player.set_pitch(pitch);
                    voice.player.play();
                },
                Event::NoteOff => voice.player.stop(),
                Event::Pitch(pitch) => voice.player.set_pitch(pitch / 440.0),
                _ => ()
            }
        }

        voice.player.generate_block(&mut outputs.audio[0]);
    }
}

fn TempLPF_faustpower2_f(value: f32) -> f32 {
	return value * value;
}
pub struct TempLPF {
	fSampleRate: i32,
	fConst2: f32,
	fConst3: f32,
	fConst4: f32,
	fConst5: f32,
	fRec1: [f32;3],
	fConst6: f32,
	fRec0: [f32;3],
}

impl TempLPF {
	fn new() -> TempLPF {
		TempLPF {
			fSampleRate: 0,
			fConst2: 0.0,
			fConst3: 0.0,
			fConst4: 0.0,
			fConst5: 0.0,
			fRec1: [0.0;3],
			fConst6: 0.0,
			fRec0: [0.0;3],
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
	}
	fn instance_clear(&mut self) {
		for l0 in 0..3 {
			self.fRec1[(l0) as usize] = 0.0;
		}
		for l1 in 0..3 {
			self.fRec0[(l1) as usize] = 0.0;
		}
	}
	fn instance_constants(&mut self, sample_rate: i32) {
		self.fSampleRate = sample_rate;
		let mut fConst0: f32 = f32::tan(47123.8906 / f32::min(192000.0, f32::max(1.0, ((self.fSampleRate) as f32))));
		let mut fConst1: f32 = 1.0 / fConst0;
		self.fConst2 = 1.0 / ((fConst1 + 0.765366852) / fConst0 + 1.0);
		self.fConst3 = 1.0 / ((fConst1 + 1.84775901) / fConst0 + 1.0);
		self.fConst4 = (fConst1 + -1.84775901) / fConst0 + 1.0;
		self.fConst5 = 2.0 * (1.0 - 1.0 / TempLPF_faustpower2_f(fConst0));
		self.fConst6 = (fConst1 + -0.765366852) / fConst0 + 1.0;
	}
	fn instance_init(&mut self, sample_rate: i32) {
		self.instance_constants(sample_rate);
		self.instance_reset_params();
		self.instance_clear();
	}
	fn init(&mut self, sample_rate: i32) {
		TempLPF::class_init(sample_rate);
		self.instance_init(sample_rate);
	}

	/*fn get_param(&self, param: ParamIndex) -> Option<Self::T> {
		match param.0 {
			_ => None,
		}
	}

	fn set_param(&mut self, param: ParamIndex, value: Self::T) {
		match param.0 {
			_ => {}
		}
	}*/

	fn compute(&mut self, count: i32, inputs: &[&[f32]], outputs: &mut[&mut[f32]]) {
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
		let zipped_iterators = inputs0.zip(outputs0);
		for (input0, output0) in zipped_iterators {
			self.fRec1[0] = ((*input0) as f32) - self.fConst3 * (self.fConst4 * self.fRec1[2] + self.fConst5 * self.fRec1[1]);
			self.fRec0[0] = self.fConst3 * (self.fRec1[2] + self.fRec1[0] + 2.0 * self.fRec1[1]) - self.fConst2 * (self.fConst6 * self.fRec0[2] + self.fConst5 * self.fRec0[1]);
			*output0 = ((self.fConst2 * (self.fRec0[2] + self.fRec0[0] + 2.0 * self.fRec0[1])) as f32);
			self.fRec1[2] = self.fRec1[1];
			self.fRec1[1] = self.fRec1[0];
			self.fRec0[2] = self.fRec0[1];
			self.fRec0[1] = self.fRec0[0];
		}
	}

}