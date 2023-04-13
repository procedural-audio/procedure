use crate::*;

pub struct Flanger {
    delay: f32,
    offset: f32,
    speed: f32,
    depth: f32,
}

impl Module for Flanger {
    type Voice = (); // FlangerDsp;

    const INFO: Info = Info {
        title: "Flanger",
        id: "default.effects.modulation.flanger",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(310 - 40 - 70, 200),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Input", 20),
            Pin::Control("Control 1", 50)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 20)
        ],
        path: &["Audio", "Modulation", "Flanger"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Flanger {
            delay: 0.5,
            offset: 0.5,
            speed: 0.5,
            depth: 0.5,
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        () // FlangerDsp::new()
    }

    fn load(&mut self, _version: &str, _state: &State) {
        // Should use generics like serde
    }

    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        let _size = 50;

        return Box::new(Stack {
            children: (
                Transform {
                    position: (40 + 70 * 0, 40 + 80 * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Delay",
                        color: Color::BLUE,
                        value: &mut self.delay,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70 * 1, 40 + 80 * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Offset",
                        color: Color::BLUE,
                        value: &mut self.offset,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70 * 0, 40 + 80 * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "Speed",
                        color: Color::BLUE,
                        value: &mut self.speed,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70 * 1, 40 + 80 * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "Depth",
                        color: Color::BLUE,
                        value: &mut self.depth,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
            ),
        });
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        // voice.prepare(sample_rate, block_size);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        /*voice.process(
            &inputs.audio[0].as_array(),
            &mut outputs.audio[0].as_array_mut(),
        );*/
    }
}

/*faust!(FlangerDsp,
    import("math.lib");

    dmax = 2048;

    lfol = component("oscillator.lib").oscrs;
    lfor = component("oscillator.lib").oscrc;

    dflange = 0.001 * SR * hslider("[1] Flange Delay [unit:ms] [style:knob]", 10, 0, 20, 0.001);
    odflange = 0.001 * SR * hslider("[2] Delay Offset [unit:ms] [style:knob]", 1, 0, 20, 0.001);
    freq  = hslider("[1] Speed [unit:Hz] [style:knob]", 0.5, 0, 10, 0.01);
    depth = hslider("[2] Depth [style:knob]", 1, 0, 1, 0.001);
    fb = hslider("[3] Feedback [style:knob]", 0, -0.999, 0.999, 0.001);
    level = hslider("Flanger Output Level [unit:dB]", 0, -60, 10, 0.1) : db2linear;

    curdel1 = odflange+dflange*(1 + lfol(freq))/2;
    curdel2 = odflange+dflange*(1 + lfor(freq))/2;

    process = _,_ : pf.flanger_stereo(dmax,curdel1,curdel2,depth,fb,0) : _,_;
);*/