use metasampler_macros::*;
use pa_dsp::*;
use crate::*;

static mut points: [(f32, f32); 40] = [(0.0, 0.0); 40];

pub struct Waveshaper {
    selected: u32,
    pregain: f32,
    gain: f32,
    gain2: f32,
}

pub struct WaveshaperVoice {
    tube1_l: Tube1,
    tube2_l: Tube2,
    tube3_l: Tube3,
    tube4_l: Tube4,
    tube5_l: Tube5,
    tube6_l: Tube6,
}

impl Module for Waveshaper {
    type Voice = WaveshaperVoice;

    const INFO: Info = Info {
        name: "Waveshaper",
        color: Color::BLUE,
        size: Size::Static(240, 160),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Input", 20),
            Pin::Control("Knob 1", 50),
            Pin::Control("Knob 2", 80),
        ],
        outputs: &[Pin::Audio("Audio Output", 20)],
    };

    
    fn new() -> Self {
        Self {
            selected: 0,
            pregain: 0.0,
            gain: 1.0,
            gain2: 0.0,
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        Self::Voice {
            tube1_l: Tube1::new(),
            tube2_l: Tube2::new(),
            tube3_l: Tube3::new(),
            tube4_l: Tube4::new(),
            tube5_l: Tube5::new(),
            tube6_l: Tube6::new(),
        }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        println!("BUilding stuff");
        return Box::new(Stack {
            children: (
                Transform {
                    position: (40, 40 + 70),
                    size: (100, 40),
                    child: Dropdown {
                        index: &mut self.selected,
                        color: Color::BLUE,
                        elements: &["Sine", "Tan", "Abs"],
                    },
                },
                Transform {
                    position: (40, 40),
                    size: (100, 60),
                    child: Painter {
                        painter: Box::new(|_canvas| {
                            let mut paint = Paint::new();

                            paint.set_color(Color::BLUE);
                            paint.set_width(2.0);

                            /*unsafe {
                                for i in 0..40 {
                                    let x = ((i as f32) - 20.0) / 20.0;
                                    let mut y = 0.0;

                                    if self.selected == 0 {
                                        y = f32::sin(x * self.gain2);
                                    } else if self.selected == 1 {
                                        y = f32::tan(x * self.gain2);
                                    } else if self.selected == 1 {
                                        y = f32::abs(x * self.gain2);
                                    }

                                    points[i] = (x * 50.0 + 50.0, y * 30.0 + 30.0);
                                }

                                canvas.draw_points(&points, paint);
                            }*/
                        }),
                    },
                },
                Transform {
                    position: (40 + 70 + 40, 40),
                    size: (60, 70),
                    child: Knob {
                        text: "Gain",
                        color: Color::BLUE,
                        value: &mut self.gain,
                        feedback: Box::new(|_value| String::new()), /*on_changed: Box::new(| mut value | {
                                                                           self.gain = (value + 1.0) * 20.0;
                                                                       })*/
                    },
                },
            ),
        });
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {
        self.gain2 = self.gain;

        // let input_l = inputs.audio[0].left.as_channel().as_array();
        // let input_r = inputs.audio[0].right.as_channel().as_array();

        /*
        match self.selected {
            0 => {
            },
            _ => panic!("Dropdown value out of range"),
        }
        */
    }
}

/*const fn wavetable2(f: fn(f32) -> f32, count: usize) -> &'static [f32] {
    &[
        f(0.0)
    ]
}*/

faust!(Tube1,
    import("filters.lib");

    tubes = component("tubes.lib").T1_12AX7 : *(preamp):
        lowpass(1,6531.0) : component("tubes.lib").T2_12AX7 : *(preamp):
        lowpass(1,6531.0) : component("tubes.lib").T3_12AX7 : *(gain) with {
        preamp = vslider("Pregain",-6,-20,20,0.1) : ba.db2linear : si.smooth(0.999);
        gain  = vslider("Gain", -6, -20.0, 20.0, 0.1) : ba.db2linear : si.smooth(0.999);
    };

    process = tubes;
);

faust!(Tube2,
    import("filters.lib");

    tubes = component("tubes.lib").T1_12AT7 : *(preamp):
        lowpass(1,6531.0) : component("tubes.lib").T2_12AT7 : *(preamp):
        lowpass(1,6531.0) : component("tubes.lib").T3_12AT7 : *(gain) with {
        preamp = vslider("Pregain",-6,-20,20,0.1) : ba.db2linear : si.smooth(0.999);
        gain  = vslider("Gain", -6, -20.0, 20.0, 0.1) : ba.db2linear : si.smooth(0.999);
    };

    process = tubes;
);

faust!(Tube3,
    import("filters.lib");

    tubes = component("tubes.lib").T1_12AU7 : *(preamp):
        lowpass(1,6531.0) : component("tubes.lib").T2_12AU7 : *(preamp):
        lowpass(1,6531.0) : component("tubes.lib").T3_12AU7 : *(gain) with {
        preamp = vslider("Pregain",-6,-20,20,0.1) : ba.db2linear : si.smooth(0.999);
        gain  = vslider("Gain", -6, -20.0, 20.0, 0.1) : ba.db2linear : si.smooth(0.999);
    };

    process = tubes;
);

faust!(Tube4,
    import("filters.lib");

    tubes = component("tubes.lib").T1_6V6 : *(preamp):
        lowpass(1,6531.0) : component("tubes.lib").T2_6V6 : *(preamp):
        lowpass(1,6531.0) : component("tubes.lib").T3_6V6 : *(gain) with {
        preamp = vslider("Pregain",-6,-20,20,0.1) : ba.db2linear : si.smooth(0.999);
        gain  = vslider("Gain", -6, -20.0, 20.0, 0.1) : ba.db2linear : si.smooth(0.999);
    };

    process = tubes;
);

faust!(Tube5,
    import("filters.lib");

    tubes = component("tubes.lib").T1_6DJ8 : *(preamp):
        lowpass(1,6531.0) : component("tubes.lib").T2_6DJ8 : *(preamp):
        lowpass(1,6531.0) : component("tubes.lib").T3_6DJ8 : *(gain) with {
        preamp = vslider("Pregain",-6,-20,20,0.1) : ba.db2linear : si.smooth(0.999);
        gain  = vslider("Gain", -6, -20.0, 20.0, 0.1) : ba.db2linear : si.smooth(0.999);
    };

    process = tubes;
);

faust!(Tube6,
    import("filters.lib");

    tubes = component("tubes.lib").T1_6C16 : *(preamp):
        lowpass(1,6531.0) : component("tubes.lib").T2_6C16 : *(preamp):
        lowpass(1,6531.0) : component("tubes.lib").T3_6C16 : *(gain) with {
        preamp = vslider("Pregain",-6,-20,20,0.1) : ba.db2linear : si.smooth(0.999);
        gain  = vslider("Gain", -6, -20.0, 20.0, 0.1) : ba.db2linear : si.smooth(0.999);
    };

    process = tubes;
);
