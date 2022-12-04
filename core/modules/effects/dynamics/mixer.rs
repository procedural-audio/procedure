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

pub struct MixerVoice {
    buffer: Stereo,
}

impl Module for Mixer {
    type Voice = MixerVoice;

    const INFO: Info = Info {
        title: Title("", Color::BLUE),
        size: Size::Static(120, 505),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Input", 25 + 60 * 0),
            Pin::Control("Linear Gain", 50 + 60 * 0),
            Pin::Audio("Audio Input", 25 + 60 * 1),
            Pin::Control("Linear Gain", 50 + 60 * 1),
            Pin::Audio("Audio Input", 25 + 60 * 2),
            Pin::Control("Linear Gain", 50 + 60 * 2),
            Pin::Audio("Audio Input", 25 + 60 * 3),
            Pin::Control("Linear Gain", 50 + 60 * 3),
            Pin::Audio("Audio Input", 25 + 60 * 4),
            Pin::Control("Linear Gain", 50 + 60 * 4),
            Pin::Audio("Audio Input", 25 + 60 * 5),
            Pin::Control("Linear Gain", 50 + 60 * 5),
            Pin::Audio("Audio Input", 25 + 60 * 6),
            Pin::Control("Linear Gain", 50 + 60 * 6),
            Pin::Audio("Audio Input", 25 + 60 * 7),
            Pin::Control("Linear Gain", 50 + 60 * 7),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 25)
        ],
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

    fn new_voice(_index: u32) -> Self::Voice {
        Self::Voice {
            buffer: Stereo::init(0.0, 256),
        }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        let top = 15;
        let space = 60;

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

    fn prepare(&self, voice: &mut Self::Voice, _sample_rate: u32, block_size: usize) {
        voice.buffer = Stereo::init(0.0, block_size);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        voice.buffer.copy_from(&inputs.audio[0]);
        voice.buffer.gain(self.value_1);
        outputs.audio[0].copy_from(&voice.buffer);

        voice.buffer.copy_from(&inputs.audio[1]);
        voice.buffer.gain(self.value_2);
        outputs.audio[0].add_from(&voice.buffer);

        voice.buffer.copy_from(&inputs.audio[2]);
        voice.buffer.gain(self.value_3);
        outputs.audio[0].add_from(&voice.buffer);

        voice.buffer.copy_from(&inputs.audio[4]);
        voice.buffer.gain(self.value_4);
        outputs.audio[0].add_from(&voice.buffer);
    }
}
