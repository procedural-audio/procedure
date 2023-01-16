use crate::*;

pub struct SquareModule;

pub struct SquareModuleVoice {
    square: Square,
    active: bool,
}

impl Module for SquareModule {
    type Voice = SquareModuleVoice;

    const INFO: Info = Info {
        title: "Squ",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[Pin::Notes("Notes", 15)],
        outputs: &[Pin::Audio("Audio Output", 15)],
        path: "Category 1/Category 2/Module Name"
    };

    fn new() -> Self { Self }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            square: Square::new(),
            active: false,
        }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 25),
            size: (40, 40),
            child: Svg {
                path: "waveforms/square.svg",
                color: Color::BLUE,
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, _block_size: usize) {
        voice.active = false;
        voice.square.init(sample_rate as i32);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure: _ } => {
                    voice.active = true;
                    voice.square.init(voice.square.fSampleRate);
                    voice.square.set_freq(pitch);
                }
                Event::NoteOff => {
                    voice.active = false;
                }
                Event::Pitch(pitch) => {
                    voice.square.set_freq(pitch);
                }
                _ => (),
            }
        }

        if voice.active {
            voice.square.compute(
                outputs.audio[0].len() as i32, 
                &[],
                &mut [outputs.audio[0].as_slice_mut()]);

            for sample in outputs.audio[0].as_slice_mut() {
                sample.gain(0.1);
            }
        }
    }
}

fn mydsp_faustpower2_f(value: f32) -> f32 {
    return value * value;
}

pub struct Square {
    fSampleRate: i32,
    fConst1: f32,
    iVec0: [i32; 2],
    fConst2: f32,
    fConst3: f32,
    fHslider0: f32,
    fConst4: f32,
    fRec1: [f32; 2],
    fRec0: [f32; 2],
    fVec1: [f32; 2],
    IOTA0: i32,
    fVec2: Box<[f32; 4096]>,
    fConst5: f32,
}

impl Square {
    fn new() -> Self {
        Self {
            fSampleRate: 0,
            fConst1: 0.0,
            iVec0: [0; 2],
            fConst2: 0.0,
            fConst3: 0.0,
            fHslider0: 0.0,
            fConst4: 0.0,
            fRec1: [0.0; 2],
            fRec0: [0.0; 2],
            fVec1: [0.0; 2],
            IOTA0: 0,
            fVec2: Box::new([0.0; 4096]),
            fConst5: 0.0,
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

    fn class_init(_sample_rate: i32) {}

    fn instance_reset_params(&mut self) {
        self.fHslider0 = 0.100000001;
    }

    fn instance_clear(&mut self) {
        for l0 in 0..2 {
            self.iVec0[(l0) as usize] = 0;
        }
        for l1 in 0..2 {
            self.fRec1[(l1) as usize] = 0.0;
        }
        for l2 in 0..2 {
            self.fRec0[(l2) as usize] = 0.0;
        }
        for l3 in 0..2 {
            self.fVec1[(l3) as usize] = 0.0;
        }
        self.IOTA0 = 0;
        for l4 in 0..4096 {
            self.fVec2[(l4) as usize] = 0.0;
        }
    }

    fn instance_constants(&mut self, sample_rate: i32) {
        self.fSampleRate = sample_rate;
        let fConst0: f32 = f32::min(192000.0, f32::max(1.0, self.fSampleRate as f32));
        self.fConst1 = 0.25 * fConst0;
        self.fConst2 = 1.0 / fConst0;
        self.fConst3 = 44.0999985 / fConst0;
        self.fConst4 = 1.0 - self.fConst3;
        self.fConst5 = 0.5 * fConst0;
    }

    fn instance_init(&mut self, sample_rate: i32) {
        self.instance_constants(sample_rate);
        self.instance_reset_params();
        self.instance_clear();
    }

    fn init(&mut self, sample_rate: i32) {
        Self::class_init(sample_rate);
        self.instance_init(sample_rate);
    }

    fn set_freq(&mut self, value: f32) {
        self.fHslider0 = value;
    }

    fn compute(&mut self, count: i32, _inputs: &[&[Stereo2]], outputs: &mut [&mut [Stereo2]]) {
        let outputs0 = if let [outputs0, ..] = outputs {
            let outputs0 = outputs0[..count as usize].iter_mut();
            outputs0
        } else {
            panic!("wrong number of outputs");
        };
        let fSlow0: f32 = self.fConst3 * ((self.fHslider0) as f32);
        let zipped_iterators = outputs0;
        for output0 in zipped_iterators {
            self.iVec0[0] = 1;
            self.fRec1[0] = fSlow0 + self.fConst4 * self.fRec1[1];
            let fTemp0: f32 = f32::max(self.fRec1[0], 23.4489498);
            let fTemp1: f32 = f32::max(20.0, f32::abs(fTemp0));
            let fTemp2: f32 = self.fRec0[1] + self.fConst2 * fTemp1;
            self.fRec0[0] = fTemp2 - f32::floor(fTemp2);
            let fTemp3: f32 = mydsp_faustpower2_f(2.0 * self.fRec0[0] + -1.0);
            self.fVec1[0] = fTemp3;
            let fTemp4: f32 = (((self.iVec0[1]) as f32) * (fTemp3 - self.fVec1[1])) / fTemp1;
            self.fVec2[(self.IOTA0 & 4095) as usize] = fTemp4;
            let fTemp5: f32 = f32::max(0.0, f32::min(2047.0, self.fConst5 / fTemp0));
            let iTemp6: i32 = fTemp5 as i32;
            let fTemp7: f32 = f32::floor(fTemp5);
            output0.left = self.fConst1
                * (fTemp4
                    - self.fVec2[((self.IOTA0 - iTemp6) & 4095) as usize] * (fTemp7 + 1.0 - fTemp5)
                    - (fTemp5 - fTemp7) * self.fVec2[((self.IOTA0 - (iTemp6 + 1)) & 4095) as usize])
                    as f32;
            output0.right = output0.left;
            self.iVec0[1] = self.iVec0[0];
            self.fRec1[1] = self.fRec1[0];
            self.fRec0[1] = self.fRec0[0];
            self.fVec1[1] = self.fVec1[0];
            self.IOTA0 = self.IOTA0 + 1;
        }
    }
}
