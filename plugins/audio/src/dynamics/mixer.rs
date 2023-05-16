use crate::*;

pub struct Mixer {
    value_1: f32,
    value_2: f32,
    value_3: f32,
    value_4: f32,
    value_5: f32,
    value_6: f32,
    value_7: f32,
    value_8: f32,
}

impl Module for Mixer {
    type Voice = ();

    const INFO: Info = Info {
        title: "",
        id: "default.effects.dynamics.mixer",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Dynamic(| inputs, _outputs | {
            let mut max = 1;
            for i in 0..inputs.len() / 2 {
                if inputs[i] {
                    max = (i as u32 + 2) / 2;
                }
            }

            (120, 70 + 60 * max)
        }),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 15 + 60 * 0),
            Pin::Control("Linear Gain", 40 + 60 * 0),
            Pin::Audio("Audio Input", 15 + 60 * 1),
            Pin::Control("Linear Gain", 40 + 60 * 1),
            Pin::Audio("Audio Input", 15 + 60 * 2),
            Pin::Control("Linear Gain", 40 + 60 * 2),
            Pin::Audio("Audio Input", 15 + 60 * 3),
            Pin::Control("Linear Gain", 40 + 60 * 3),
            Pin::Audio("Audio Input", 15 + 60 * 4),
            Pin::Control("Linear Gain", 40 + 60 * 4),
            Pin::Audio("Audio Input", 15 + 60 * 5),
            Pin::Control("Linear Gain", 40 + 60 * 5),
            Pin::Audio("Audio Input", 15 + 60 * 6),
            Pin::Control("Linear Gain", 40 + 60 * 6),
            Pin::Audio("Audio Input", 15 + 60 * 7),
            Pin::Control("Linear Gain", 40 + 60 * 7),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 15)
        ],
        path: &["Audio", "Dynamics", "Mixer"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            value_1: 0.5,
            value_2: 0.5,
            value_3: 0.5,
            value_4: 0.5,
            value_5: 0.5,
            value_6: 0.5,
            value_7: 0.5,
            value_8: 0.5,
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        let top = 10;
        let space = 60;

        // TODO: Simplify to use column widget instead of stack
        Box::new(Stack {
            children: (
                Transform {
                    position: (35, top + space * 0),
                    size: (50, 70),
                    child: Knob {
                        text: "",
                        color: Color::BLUE,
                        value: &mut self.value_1,
                        feedback: Box::new(|_v| String::new()),
                    },
                },
                Transform {
                    position: (35, top + space * 1),
                    size: (50, 70),
                    child: Knob {
                        text: "",
                        color: Color::BLUE,
                        value: &mut self.value_2,
                        feedback: Box::new(|_v| String::new()),
                    },
                },
                Transform {
                    position: (35, top + space * 2),
                    size: (50, 70),
                    child: Knob {
                        text: "",
                        color: Color::BLUE,
                        value: &mut self.value_3,
                        feedback: Box::new(|_v| String::new()),
                    },
                },
                Transform {
                    position: (35, top + space * 3),
                    size: (50, 70),
                    child: Knob {
                        text: "",
                        color: Color::BLUE,
                        value: &mut self.value_4,
                        feedback: Box::new(|_v| String::new()),
                    },
                },
                Transform {
                    position: (35, top + space * 4),
                    size: (50, 70),
                    child: Knob {
                        text: "",
                        color: Color::BLUE,
                        value: &mut self.value_5,
                        feedback: Box::new(|_v| String::new()),
                    },
                },
                Transform {
                    position: (35, top + space * 5),
                    size: (50, 70),
                    child: Knob {
                        text: "",
                        color: Color::BLUE,
                        value: &mut self.value_6,
                        feedback: Box::new(|_v| String::new()),
                    },
                },
                Transform {
                    position: (35, top + space * 6),
                    size: (50, 70),
                    child: Knob {
                        text: "",
                        color: Color::BLUE,
                        value: &mut self.value_7,
                        feedback: Box::new(|_v| String::new()),
                    },
                },
                Transform {
                    position: (35, top + space * 7),
                    size: (50, 70),
                    child: Knob {
                        text: "",
                        color: Color::BLUE,
                        value: &mut self.value_8,
                        feedback: Box::new(|_v| String::new()),
                    },
                },
            ),
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let values = &[
            self.value_1,
            self.value_2,
            self.value_3,
            self.value_4,
            self.value_5,
            self.value_6,
            self.value_7,
            self.value_8,
        ];

        for i in 0..inputs.audio.len() {
            if inputs.audio.connected(i) {
                let m = values[i];
                for (o, i) in outputs.audio[0].as_slice_mut().iter_mut().zip(&inputs.audio[i]) {
                    o.left = o.left + i.left * m;
                    o.right = o.right + i.right * m;
                }
            }
        }
    }
}
