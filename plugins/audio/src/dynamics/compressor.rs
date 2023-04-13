use crate::*;

pub struct Compressor {
    compress_amount: f32,
    output_rms: f32,
    threshold: f32,
    ratio: f32,
    attack: f32,
    release: f32,
    release2: f32,
    release3: f32,
}

impl Module for Compressor {
    type Voice = ();

    const INFO: Info = Info {
        title: "Compressor",
        id: "default.effects.dynamics.compressor",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(410, 220),
        voicing: Voicing::Monophonic,
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
            compress_amount: 0.5,
            output_rms: 0.3,
            threshold: 0.0,
            ratio: 1.0,
            attack: 0.0,
            release: 0.0,
            release2: 0.0,
            release3: 0.0,
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Padding {
            padding: (10, 10, 10, 10),
            child: Stack {
                children: (
                    Transform {
                        position: (30, 30),
                        size: (50, 70),
                        child: Knob {
                            text: "Threshold",
                            color: Color::BLUE,
                            value: &mut self.threshold,
                            feedback: Box::new(|_v| String::new()),
                        },
                    },
                    Transform {
                        position: (30, 110),
                        size: (50, 70),
                        child: Knob {
                            text: "Attack",
                            color: Color::BLUE,
                            value: &mut self.attack,
                            feedback: Box::new(|_v| String::new()),
                        },
                    },
                    Transform {
                        position: (30 + 60, 30),
                        size: (50, 70),
                        child: Knob {
                            text: "Ratio",
                            color: Color::BLUE,
                            value: &mut self.ratio,
                            feedback: Box::new(|_v| String::new()),
                        },
                    },
                    Transform {
                        position: (30 + 60, 110),
                        size: (50, 70),
                        child: Knob {
                            text: "Release",
                            color: Color::BLUE,
                            value: &mut self.release,
                            feedback: Box::new(|_v| String::new()),
                        },
                    },
                    Positioned {
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
                    },
                    Transform {
                        position: (30 + 60, 110),
                        size: (50, 70),
                        child: Knob {
                            text: "Release",
                            color: Color::BLUE,
                            value: &mut self.release2,
                            feedback: Box::new(|_v| String::new()),
                        },
                    },
                    Transform {
                        position: (30 + 60, 110),
                        size: (50, 70),
                        child: Knob {
                            text: "Release",
                            color: Color::BLUE,
                            value: &mut self.release3,
                            feedback: Box::new(|_v| String::new()),
                        },
                    },
                ),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {
        self.compress_amount += 0.01;
        self.output_rms += 0.03;

        if self.compress_amount > 1.0 {
            self.compress_amount = 0.0;
        }

        if self.output_rms > 1.0 {
            self.output_rms = 0.0;
        }
    }
}

/*
faust!(CompressorDSP,
    freq = hslider("freq",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0,10,0.01);

    process = _,_ : Compressor_stereo(thresh,att,hold,rel);
);
*/
