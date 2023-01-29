use crate::*;


pub struct Gate {
    input_rms: f32,
    output_rms: f32,
    threshold: f32,
    ret: f32,
}

impl Module for Gate {
    type Voice = ();

    const INFO: Info = Info {
        title: "Gate",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(350, 220),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Input", 25),
            Pin::Control("Linear Gate", 55),
            Pin::Control("Linear Gate", 85),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 25)
        ],
        path: "Audio Effects/Dynamics/Gate",
        presets: Presets::NONE
    };

    
    fn new() -> Self {
        Self {
            input_rms: 0.5,
            output_rms: 0.3,
            threshold: 0.0,
            ret: 0.0,
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
                            text: "Return",
                            color: Color::BLUE,
                            value: &mut self.ret,
                            feedback: Box::new(|_v| String::new()),
                        },
                    },
                    Positioned {
                        position: (100, 30),
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
                                        value: &self.input_rms,
                                        width: 3.0,
                                        color: Color(0xff787878),
                                    },
                                    DynamicLine {
                                        value: &self.output_rms,
                                        width: 3.0,
                                        color: Color(0xffb4b4b4),
                                    },
                                    Painter {
                                        paint: | canvas | {
                                            let mut paint = Paint::new();
                                            paint.set_color(Color::BLUE);

                                            canvas.draw_rect((0.0, 50.0), (150.0, 3.0), paint);
                                        },
                                    },
                                ),
                            },
                        },
                    },
                ),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {
        self.input_rms += 0.01;
        self.output_rms += 0.03;

        if self.input_rms > 1.0 {
            self.input_rms = 0.0;
        }

        if self.output_rms > 1.0 {
            self.output_rms = 0.0;
        }
    }
}

/*
faust!(GateDSP,
    freq = hslider("freq",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0,10,0.01);

    process = _,_ : gate_stereo(thresh,att,hold,rel);
);
*/
