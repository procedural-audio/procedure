

use crate::*;


// use pa_dsp::buffers::*;

pub struct SineModule {
    wave_index: u32,
    freq: f32,
    glide: f32,
    other: f32,
}

pub struct SineModuleVoice {
    sine: Sine,
    active: bool,
    id: Id,
}

impl Module for SineModule {
    type Voice = SineModuleVoice;

    const INFO: Info = Info {
        title: "Sine",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[Pin::Notes("Notes", 15)],
        outputs: &[Pin::Audio("Audio Output", 15)],
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
            sine: Sine::new(),
            active: false,
            id: Id::new(),
        }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 25),
            size: (40, 40),
            child: Svg {
                path: "waveforms/sine.svg",
                color: Color::GREEN,
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, _block_size: usize) {
        voice.active = false;
        voice.id = Id::new();
        voice.sine.init(sample_rate as i32);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        /*for note in &inputs.events[0] {
            match note {
                Event::NoteOn { note, offset: _ } => {
                    voice.active = true;
                    voice.id = note.id;

                    voice.sine.set_freq(note.pitch);
                }
                Event::NoteOff { id } => {
                    if voice.id == *id {
                        voice.active = false;
                    }
                }
                Event::Pitch { id, freq } => {
                    if voice.id == *id {
                        voice.sine.set_freq(*freq);
                    }
                }
                _ => (),
            }
        }

        if voice.active {
            let buffer = &mut outputs.audio[0];

            voice
                .sine
                .compute(buffer.len() as i32, &[], &mut [buffer.left.as_slice_mut()]);

            buffer.right.copy_from(&buffer.left);
        }*/
    }
}

/*faust!(Saw2,
    freq = hslider("freq[style:numerical]", 500, 20, 20000, 0.001) : si.smoo;
    process = os.sinetooth(freq);
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

    fn compute(&mut self, count: i32, _inputs: &[&[f32]], outputs: &mut [&mut [f32]]) {
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
            *output0 =
                (unsafe { ftbl0SineSIG0[((65536.0 * self.fRec1[0]) as i32) as usize] }) as f32;
            self.fRec2[1] = self.fRec2[0];
            self.fRec1[1] = self.fRec1[0];
        }
    }
}
