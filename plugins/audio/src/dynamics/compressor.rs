use crate::*;

pub struct Compressor {
    input_rms: f32,
    output_rms: f32,
    threshold: f32,
    ratio: f32,
    attack: f32,
    release: f32,
}

impl Module for Compressor {
    type Voice = VoiceIndex;

    const INFO: Info = Info {
        title: "Compressor",
        id: "default.effects.dynamics.compressor",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(340, 200),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 25),
            Pin::Control("Threshold", 55),
            Pin::Control("Ratio", 85),
            Pin::Control("Attack", 85 + 30),
            Pin::Control("Release", 85 + 60),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 25)
        ],
        path: &["Audio", "Dynamics", "Compressor"],
        presets: Presets::NONE
    };

    
    fn new() -> Self {
        Self {
            input_rms: 0.5,
            output_rms: 0.3,
            threshold: 0.0,
            ratio: 1.0,
            attack: 0.0,
            release: 0.0,
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        VoiceIndex::from(index)
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Padding {
            padding: (10, 10, 10, 10),
            child: Stack {
                children: (
                    Transform {
                        position: (30, 25),
                        size: (50, 70),
                        child: Knob {
                            text: "Threshold",
                            color: Color::BLUE,
                            value: &mut self.threshold,
                            feedback: Box::new(|_v| String::new()),
                        },
                    },
                    Transform {
                        position: (30, 100),
                        size: (50, 70),
                        child: Knob {
                            text: "Attack",
                            color: Color::BLUE,
                            value: &mut self.attack,
                            feedback: Box::new(|_v| String::new()),
                        },
                    },
                    Transform {
                        position: (30 + 60, 25),
                        size: (50, 70),
                        child: Knob {
                            text: "Ratio",
                            color: Color::BLUE,
                            value: &mut self.ratio,
                            feedback: Box::new(|_v| String::new()),
                        },
                    },
                    Transform {
                        position: (30 + 60, 100),
                        size: (50, 70),
                        child: Knob {
                            text: "Release",
                            color: Color::BLUE,
                            value: &mut self.release,
                            feedback: Box::new(|_v| String::new()),
                        },
                    },
                    /*Positioned {
                        position: (100 + 60, 30),
                        child: Container {
                            size: (200, 150),
                            color: Color(0xff141414),
                            border: Border {
                                radius: 5,
                                thickness: 2,
                                color: Color::BLUE, // Color(0xff505050)
                            },
                            child: Stack {
                                children: (
                                    DynamicLine {
                                        value: &self.compress_amount,
                                        width: 3.0,
                                        color: Color::RED,
                                    },
                                    DynamicLine {
                                        value: &self.output_rms,
                                        width: 3.0,
                                        color: Color(0xffb4b4b4),
                                    },
                                ),
                            },
                        },
                    },*/
                    Transform {
                        position: (100 + 60, 25),
                        size: (140, 140),
                        child: Stack {
                            children: (
                                DynamicLine {
                                    value: &self.input_rms,
                                    width: 3.0,
                                    color: Color(0xffb4b4b4),
                                },
                                DynamicLine {
                                    value: &self.output_rms,
                                    width: 3.0,
                                    color: Color::RED,
                                },
                            ),
                        },
                    },
                ),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, _outputs: &mut IO) {
        if voice.index == 0 {
            self.input_rms = 0.0;
        }

        self.input_rms = f32::max(inputs.audio[0].rms().mono(), self.input_rms);

        println!("input rms: {}", self.input_rms);

        self.output_rms += 0.03;
        if self.output_rms > 1.0 {
            self.output_rms = 0.0;
        }
    }
}
