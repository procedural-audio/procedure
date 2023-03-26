use crate::*;


pub struct SineModule;

pub struct SineModuleVoice {
    sine: Sine,
    active: bool,
}

impl Module for SineModule {
    type Voice = SineModuleVoice;

    const INFO: Info = Info {
        title: "Sin",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[Pin::Notes("Notes", 15)],
        outputs: &[Pin::Audio("Audio Output", 15)],
        path: &["Audio Sources", "Synthesis", "Sine"],
        presets: Presets::NONE
    };

    
    fn new() -> Self { Self }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            sine: Sine::new(),
            active: false,
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 25),
            size: (40, 40),
            child: Icon {
                path: "waveforms/sine.svg",
                color: Color::BLUE,
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, _block_size: usize) {
        voice.active = false;
        voice.sine.init(sample_rate as i32);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure: _ } => {
                    voice.active = true;
                    voice.sine.init(voice.sine.fSampleRate);
                    voice.sine.set_freq(pitch);
                }
                Event::NoteOff => {
                    voice.active = false;
                }
                Event::Pitch(pitch) => {
                    voice.sine.set_freq(pitch);
                }
                _ => (),
            }
        }

        if voice.active {
            voice.sine.compute(
                outputs.audio[0].len() as i32, 
                &[],
                &mut [outputs.audio[0].as_slice_mut()]);

            for sample in outputs.audio[0].as_slice_mut() {
                sample.gain(0.1);
            }
        }
    }
}

pub struct SineSIG0 {
    iVec0: [i32; 2],
    iRec0: [i32; 2],
}

impl SineSIG0 {
    fn get_num_inputsSineSIG0(&self) -> i32 {
        return 0;
    }
    fn get_num_outputsSineSIG0(&self) -> i32 {
        return 1;
    }

    fn instance_initSineSIG0(&mut self, _sample_rate: i32) {
        for l0 in 0..2 {
            self.iVec0[(l0) as usize] = 0;
        }
        for l1 in 0..2 {
            self.iRec0[(l1) as usize] = 0;
        }
    }

    fn fillSineSIG0(&mut self, count: i32, table: &mut [f32]) {
        for i1 in 0..count {
            self.iVec0[0] = 1;
            self.iRec0[0] = (self.iVec0[1] + self.iRec0[1]) % 65536;
            table[(i1) as usize] = f32::sin(9.58738019e-05 * ((self.iRec0[0]) as f32));
            self.iVec0[1] = self.iVec0[0];
            self.iRec0[1] = self.iRec0[0];
        }
    }
}

pub fn newSineSIG0() -> SineSIG0 {
    SineSIG0 {
        iVec0: [0; 2],
        iRec0: [0; 2],
    }
}

static mut ftbl0SineSIG0: [f32; 65536] = [0.0; 65536];

pub struct Sine {
    fSampleRate: i32,
    fConst1: f32,
    fConst2: f32,
    fHslider0: f32,
    fConst3: f32,
    fRec2: [f32; 2],
    fRec1: [f32; 2],
}

impl Sine {
    fn new() -> Sine {
        Sine {
            fSampleRate: 0,
            fConst1: 0.0,
            fConst2: 0.0,
            fHslider0: 0.0,
            fConst3: 0.0,
            fRec2: [0.0; 2],
            fRec1: [0.0; 2],
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
        let mut sig0: SineSIG0 = newSineSIG0();
        sig0.instance_initSineSIG0(sample_rate);
        sig0.fillSineSIG0(65536, unsafe { &mut ftbl0SineSIG0 });
    }

    fn instance_reset_params(&mut self) {
        self.fHslider0 = 0.100000001;
    }

    fn instance_clear(&mut self) {
        for l2 in 0..2 {
            self.fRec2[(l2) as usize] = 0.0;
        }
        for l3 in 0..2 {
            self.fRec1[(l3) as usize] = 0.0;
        }
    }

    fn instance_constants(&mut self, sample_rate: i32) {
        self.fSampleRate = sample_rate;
        let fConst0: f32 = f32::min(192000.0, f32::max(1.0, (self.fSampleRate) as f32));
        self.fConst1 = 1.0 / fConst0;
        self.fConst2 = 44.0999985 / fConst0;
        self.fConst3 = 1.0 - self.fConst2;
    }

    fn instance_init(&mut self, sample_rate: i32) {
        self.instance_constants(sample_rate);
        self.instance_reset_params();
        self.instance_clear();
    }

    fn init(&mut self, sample_rate: i32) {
        Sine::class_init(sample_rate);
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
        let fSlow0: f32 = self.fConst2 * ((self.fHslider0) as f32);
        let zipped_iterators = outputs0;
        for output0 in zipped_iterators {
            self.fRec2[0] = fSlow0 + self.fConst3 * self.fRec2[1];
            let fTemp0: f32 = self.fRec1[1] + self.fConst1 * self.fRec2[0];
            self.fRec1[0] = fTemp0 - f32::floor(fTemp0);
            output0.left =
                (unsafe { ftbl0SineSIG0[((65536.0 * self.fRec1[0]) as i32) as usize] }) as f32;
            output0.right = output0.left;
            self.fRec2[1] = self.fRec2[0];
            self.fRec1[1] = self.fRec1[0];
        }
    }
}
