

use crate::*;


// use pa_dsp::buffers::*;
pub struct TriangleModule {
    wave_index: u32,
    freq: f32,
    glide: f32,
    other: f32,
}

pub struct TriangleModuleVoice {
    triangle: Triangle,
    active: bool,
    id: Id,
}

impl Module for TriangleModule {
    type Voice = TriangleModuleVoice;

    const INFO: Info = Info {
        title: "Triangle",
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
            triangle: Triangle::new(),
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
                path: "waveforms/saw.svg",
                color: Color::GREEN,
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, _block_size: usize) {
        voice.active = false;
        voice.id = Id::new();
        voice.triangle.init(sample_rate as i32);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        /*for note in &inputs.events[0] {
            match note {
                Event::NoteOn { note, offset: _ } => {
                    voice.active = true;
                    voice.id = note.id;

                    voice.triangle.set_freq(note.pitch);
                }
                Event::NoteOff { id } => {
                    if voice.id == *id {
                        voice.active = false;
                    }
                }
                Event::Pitch { id, freq } => {
                    if voice.id == *id {
                        voice.triangle.set_freq(*freq);
                    }
                }
                _ => (),
            }
        }

        if voice.active {
            let buffer = &mut outputs.audio[0];

            voice
                .triangle
                .compute(buffer.len() as i32, &[], &mut [buffer.left.as_slice_mut()]);

            buffer.right.copy_from(&buffer.left);
        }*/
    }
}

/*faust!(Triangle2,
    freq = hslider("freq[style:numerical]", 500, 20, 20000, 0.001) : si.smoo;
    process = os.triangletooth(freq);
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

fn Triangle_faustpower2_f(value: f32) -> f32 {
    return value * value;
}
pub struct Triangle {
    fSampleRate: i32,
    fConst1: f32,
    fConst2: f32,
    fHslider0: f32,
    fConst3: f32,
    iVec0: [i32; 2],
    fRec0: [f32; 2],
    fConst4: f32,
    fConst5: f32,
    fRec2: [f32; 2],
    fVec1: [f32; 2],
    IOTA0: i32,
    fVec2: [f32; 4096],
    fConst6: f32,
    fRec1: [f32; 2],
}

impl Triangle {
    fn new() -> Triangle {
        Triangle {
            fSampleRate: 0,
            fConst1: 0.0,
            fConst2: 0.0,
            fHslider0: 0.0,
            fConst3: 0.0,
            iVec0: [0; 2],
            fRec0: [0.0; 2],
            fConst4: 0.0,
            fConst5: 0.0,
            fRec2: [0.0; 2],
            fVec1: [0.0; 2],
            IOTA0: 0,
            fVec2: [0.0; 4096],
            fConst6: 0.0,
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

    fn class_init(_sample_rate: i32) {}

    fn instance_reset_params(&mut self) {
        self.fHslider0 = 500.0;
    }

    fn instance_clear(&mut self) {
        for l0 in 0..2 {
            self.iVec0[(l0) as usize] = 0;
        }
        for l1 in 0..2 {
            self.fRec0[(l1) as usize] = 0.0;
        }
        for l2 in 0..2 {
            self.fRec2[(l2) as usize] = 0.0;
        }
        for l3 in 0..2 {
            self.fVec1[(l3) as usize] = 0.0;
        }
        self.IOTA0 = 0;
        for l4 in 0..4096 {
            self.fVec2[(l4) as usize] = 0.0;
        }
        for l5 in 0..2 {
            self.fRec1[(l5) as usize] = 0.0;
        }
    }

    fn instance_constants(&mut self, sample_rate: i32) {
        self.fSampleRate = sample_rate;
        let fConst0: f32 = f32::min(192000.0, f32::max(1.0, (self.fSampleRate) as f32));
        self.fConst1 = 4.0 / fConst0;
        self.fConst2 = 44.0999985 / fConst0;
        self.fConst3 = 1.0 - self.fConst2;
        self.fConst4 = 0.25 * fConst0;
        self.fConst5 = 1.0 / fConst0;
        self.fConst6 = 0.5 * fConst0;
    }

    fn instance_init(&mut self, sample_rate: i32) {
        self.instance_constants(sample_rate);
        self.instance_reset_params();
        self.instance_clear();
    }

    fn init(&mut self, sample_rate: i32) {
        Triangle::class_init(sample_rate);
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
            self.iVec0[0] = 1;
            self.fRec0[0] = fSlow0 + self.fConst3 * self.fRec0[1];
            let fTemp0: f32 = f32::max(self.fRec0[0], 23.4489498);
            let fTemp1: f32 = f32::max(20.0, f32::abs(fTemp0));
            let fTemp2: f32 = self.fRec2[1] + self.fConst5 * fTemp1;
            self.fRec2[0] = fTemp2 - f32::floor(fTemp2);
            let fTemp3: f32 = Triangle_faustpower2_f(2.0 * self.fRec2[0] + -1.0);
            self.fVec1[0] = fTemp3;
            let fTemp4: f32 = (((self.iVec0[1]) as f32) * (fTemp3 - self.fVec1[1])) / fTemp1;
            self.fVec2[(self.IOTA0 & 4095) as usize] = fTemp4;
            let fTemp5: f32 = f32::max(0.0, f32::min(2047.0, self.fConst6 / fTemp0));
            let iTemp6: i32 = (fTemp5) as i32;
            let fTemp7: f32 = f32::floor(fTemp5);
            self.fRec1[0] = 0.999000013 * self.fRec1[1]
                + self.fConst4
                    * (fTemp4
                        - self.fVec2[((self.IOTA0 - iTemp6) & 4095) as usize]
                            * (fTemp7 + 1.0 - fTemp5)
                        - (fTemp5 - fTemp7)
                            * self.fVec2[((self.IOTA0 - (iTemp6 + 1)) & 4095) as usize]);
            *output0 = (self.fConst1 * self.fRec0[0] * self.fRec1[0]) as f32;
            self.iVec0[1] = self.iVec0[0];
            self.fRec0[1] = self.fRec0[0];
            self.fRec2[1] = self.fRec2[0];
            self.fVec1[1] = self.fVec1[0];
            self.IOTA0 = self.IOTA0 + 1;
            self.fRec1[1] = self.fRec1[0];
        }
    }
}
