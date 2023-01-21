use crate::*;

pub struct LfoModule {
    wave: usize,
    value: f32,
}

pub struct LfoVoice {
    saw: Lfo,
    square: Lfo,
    sine: Lfo,
    triangle: Lfo,
    last_reset: f32,
}

impl Module for LfoModule {
    type Voice = LfoVoice;

    const INFO: Info = Info {
        title: "LFO",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(250, 140),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Control("LFO Rate (hz)", 15),
            Pin::Control("Reset (trigger)", 45),
        ],
        outputs: &[
            Pin::Control("LFO Output", 15)
        ],
        path: "Category 1/Category 2/Module Name"
    };
    
    fn new() -> Self {
        Self {
            wave: 0,
            value: 0.5,
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        use std::f32::consts::PI;

        Self::Voice {
            saw: Lfo::from(|x| {
                let x = x % (2.0 * PI);

                x / PI - 1.0
            }),
            square: Lfo::from(|x| {
                let x = x % (2.0 * PI);

                if x < PI {
                    -1.0
                } else {
                    1.0
                }
            }),
            sine: Lfo::from(f32::sin),
            triangle: Lfo::from(|x| {
                let x = x % (2.0 * PI);

                if x < PI {
                    x / PI * 2.0 - 1.0
                } else {
                    -(x / PI * 2.0 - 1.0)
                }
            }),
            last_reset: 0.0,
        }
    }

    fn load(&mut self, state: &State) {
        self.wave = state.load::<&str, u32>("wave") as usize;
        self.value = state.load("value");
    }

    fn save(&self, state: &mut State) {
        state.save("wave", self.wave as u32);
        state.save("value", self.value);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Stack {
            children: (
                Transform {
                    position: (40, 30),
                    size: (100, 100),
                    child: ButtonGrid {
                        index: &mut self.wave,
                        color: Color::RED,
                        rows: 2,
                        icons: &[
                            "waveforms/saw.svg",
                            "waveforms/square.svg",
                            "waveforms/sine.svg",
                            "waveforms/triangle.svg",
                        ]
                    }
                },
                Transform {
                    position: (155, 40),
                    size: (60, 70),
                    child: Knob {
                        text: "Rate",
                        color: Color::RED,
                        value: &mut self.value,
                        feedback: Box::new(|v| format!("{:.2} hz", v * 20.0)),
                    },
                },
            ),
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.saw.prepare(sample_rate / block_size as u32, 1);
        voice.square.prepare(sample_rate / block_size as u32, 1);
        voice.sine.prepare(sample_rate / block_size as u32, 1);
        voice.triangle.prepare(sample_rate / block_size as u32, 1);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let hz = self.value * 80.0;
        let reset = inputs.control[0];

        if voice.last_reset < 0.5 {
            if reset >= 0.5 {
                voice.saw.reset();
                voice.square.reset();
                voice.sine.reset();
                voice.triangle.reset();
            }
        }

        voice.last_reset = reset;

        if self.wave == 0 {
            voice.saw.set_pitch(hz);
            outputs.control[0] = voice.saw.gen();
        } else if self.wave == 1 {
            voice.square.set_pitch(hz);
            outputs.control[0] = voice.square.gen();
        } else if self.wave == 2 {
            voice.sine.set_pitch(hz);
            outputs.control[0] = voice.sine.gen();
        } else if self.wave == 3 {
            voice.triangle.set_pitch(hz);
            outputs.control[0] = voice.triangle.gen();
        }
    }
}
