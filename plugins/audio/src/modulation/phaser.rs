use crate::*;

pub struct Phaser {
    level: f32,
    freq: f32,
    delay: f32,
    depth: f32,
    feedback: f32,
    width: f32,
}

impl Module for Phaser {
    type Voice = (); // PhaserDsp;

    const INFO: Info = Info {
        title: "Phaser",
        id: "default.effects.modulation.phaser",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(310 - 40, 200),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Input", 20),
            Pin::Control("Control 1", 50)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 20)
        ],
        path: &["Audio", "Modulation", "Phaser"],
        presets: Presets::NONE
    };

    
    fn new() -> Self {
        Phaser {
            level: 0.5,
            freq: 0.5,
            delay: 0.5,
            depth: 0.5,
            feedback: 0.5,
            width: 0.5,
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        () // PhaserDsp::new()
    }

    fn load(&mut self, _version: &str, _state: &State) {
        // Should use generics like serde
    }

    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Stack {
            children: (
                Transform {
                    position: (40 + 70 * 0, 40 + 80 * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Level",
                        color: Color::BLUE,
                        value: &mut self.level,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70 * 1, 40 + 80 * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Freq",
                        color: Color::BLUE,
                        value: &mut self.freq,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70 * 0, 40 + 80 * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "Delay",
                        color: Color::BLUE,
                        value: &mut self.delay,
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
                Transform {
                    position: (40 + 70 * 2, 40 + 80 * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Feedback",
                        color: Color::BLUE,
                        value: &mut self.feedback,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70 * 2, 40 + 80 * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "Width",
                        color: Color::BLUE,
                        value: &mut self.width,
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

/*faust!(PhaserDsp,
    import("math.lib");

    // Notches: number of spectral notches (MACRO ARGUMENT - not a signal)
    // width: approximate width of spectral notches in Hz
    // frqmin: approximate minimum frequency of first spectral notch in Hz
    // fratio: ratio of adjacent notch frequencies
    // frqmax: approximate maximum frequency of first spectral notch in Hz
    // speed: LFO frequency in Hz (rate of periodic notch sweep cycles)
    // depth: effect strength between 0 and 1 (1 typical) (aka "intensity") when depth=2, "vibrato mode" is obtained (pure allpass chain)
    // fb: feedback gain between -1 and 1 (0 typical)
    // invert: 0 for normal, 1 to invert sign of flanging sum

    // _,_ : phaser2_stereo(Notches,width,frqmin,fratio,frqmax,speed,depth,fb,invert) : _,_

    Notches = 5;
    width = 60;
    frqmin = 100;
    fratio = 2;
    frqmax = 5000;
    speed = 5;
    depth = hslider("Depth", 0, 0, 1, 0.001);
    fb = hslider("Feedback", 0, -0.999, 0.999, 0.001);
    invert = 0;

    process = _,_ : pf.phaser2_stereo(Notches,width,frqmin,fratio,frqmax,speed,depth,fb,invert) : _,_;
);*/