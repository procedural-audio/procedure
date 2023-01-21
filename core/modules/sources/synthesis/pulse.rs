

use crate::*;


// use pa_dsp::buffers::*;

pub struct PulseModule {
    wave_index: u32,
    freq: f32,
    glide: f32,
    other: f32,
}

pub struct PulseModuleVoice {
    saw: Pulse,
    active: bool,
    id: Id,
}

impl Module for PulseModule {
    type Voice = PulseModuleVoice;

    const INFO: Info = Info {
        title: "Pulse",
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

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            saw: Pulse::new(),
            active: false,
            id: Id::new(),
        }
    }

    fn load(&mut self, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 25),
            size: (40, 40),
            child: Svg {
                path: "waveforms/saw.svg",
                color: Color::GREEN,
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, _block_size: usize) {
        voice.active = false;
        voice.id = Id::new();
        voice.saw.init(sample_rate as i32);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        /*for note in &inputs.events[0] {
            match note {
                Event::NoteOn { note, offset: _ } => {
                    voice.active = true;
                    voice.id = note.id;

                    voice.saw.set_freq(note.pitch);
                }
                Event::NoteOff { id } => {
                    if voice.id == *id {
                        voice.active = false;
                    }
                }
                Event::Pitch { id, freq } => {
                    if voice.id == *id {
                        voice.saw.set_freq(*freq);
                    }
                }
                _ => (),
            }
        }

        if voice.active {
            let buffer = &mut outputs.audio[0];

            voice
                .saw
                .compute(buffer.len() as i32, &[], &mut [buffer.left.as_slice_mut()]);

            buffer.right.copy_from(&buffer.left);
        }*/
    }
}

/*faust!(Pulse2,
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

pub struct Pulse {
    fSampleRate: i32,
    fConst0: f32,
    fConst1: f32,
    fConst2: f32,
    fHslider0: f32,
    fConst3: f32,
    fRec2: [f32; 2],
    fRec0: [f32; 2],
}

impl Pulse {
    fn new() -> Self {
        Self {
            fSampleRate: 0,
            fConst0: 0.0,
            fConst1: 0.0,
            fConst2: 0.0,
            fHslider0: 0.0,
            fConst3: 0.0,
            fRec2: [0.0; 2],
            fRec0: [0.0; 2],
        }
    }

    fn get_num_inputs(&self) -> i32 {
        return 0;
    }

    fn get_num_outputs(&self) -> i32 {
        return 1;
    }

    fn class_init(_sample_rate: i32) {}

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
        self.fConst0 = f32::min(192000.0, f32::max(1.0, self.fSampleRate as f32));
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
        Self::class_init(sample_rate);
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
            let fTemp0: f32 = f32::max(1.1920929e-07, f32::abs(self.fRec2[0]));
            let fTemp1: f32 = self.fRec0[1] + self.fConst1 * fTemp0;
            let fTemp2: f32 = fTemp1 + -1.0;
            let iTemp3: i32 = (fTemp2 < 0.0) as i32;
            self.fRec0[0] = if iTemp3 as i32 != 0 { fTemp1 } else { fTemp2 };
            let fThen1: f32 = fTemp1 + (1.0 - self.fConst0 / fTemp0) * fTemp2;
            let fRec1: f32 = if iTemp3 as i32 != 0 { fTemp1 } else { fThen1 };
            *output0 = (2.0 * fRec1 + -1.0) as f32;
            self.fRec2[1] = self.fRec2[0];
            self.fRec0[1] = self.fRec0[0];
        }
    }
}
