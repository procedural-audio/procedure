use pa_dsp::*;
use crate::*;

pub struct Tube {
    selected: u32,
    pregain: f32,
    gain: f32,
}

pub struct TubeVoice {
    /*tube1_l: Tube1,
    tube1_r: Tube1,
    tube2_l: Tube2,
    tube2_r: Tube2,
    tube3_l: Tube3,
    tube3_r: Tube3,
    tube4_l: Tube4,
    tube4_r: Tube4,
    tube5_l: Tube5,
    tube5_r: Tube5,
    tube6_l: Tube6,
    tube6_r: Tube6,*/
}

impl Module for Tube {
    type Voice = TubeVoice;

    const INFO: Info = Info {
        title: Title("Tube", Color::BLUE),
        size: Size::Static(200, 170),
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
            gain: 0.0,
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        Self::Voice {
            /*tube1_l: Tube1::new(),
            tube1_r: Tube1::new(),
            tube2_l: Tube2::new(),
            tube2_r: Tube2::new(),
            tube3_l: Tube3::new(),
            tube3_r: Tube3::new(),
            tube4_l: Tube4::new(),
            tube4_r: Tube4::new(),
            tube5_l: Tube5::new(),
            tube5_r: Tube5::new(),
            tube6_l: Tube6::new(),
            tube6_r: Tube6::new(),*/
        }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Stack {
            children: (
                Transform {
                    position: (50, 40 + 70),
                    size: (100, 40),
                    child: Dropdown {
                        index: &mut self.selected,
                        color: Color::BLUE,
                        elements: &["Tube 1", "Tube 2", "Tube 3", "Tube 4", "Tube 5", "Tube 6"],
                    },
                },
                Transform {
                    position: (40, 40),
                    size: (60, 70),
                    child: Knob {
                        text: "Pregain",
                        color: Color::BLUE,
                        value: &mut self.pregain,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70, 40),
                    size: (60, 70),
                    child: Knob {
                        text: "Gain",
                        color: Color::BLUE,
                        value: &mut self.gain,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
            ),
        });
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        /*voice.tube1_l.prepare(sample_rate, block_size);
        voice.tube1_r.prepare(sample_rate, block_size);
        voice.tube2_l.prepare(sample_rate, block_size);
        voice.tube2_r.prepare(sample_rate, block_size);
        voice.tube3_l.prepare(sample_rate, block_size);
        voice.tube3_r.prepare(sample_rate, block_size);
        voice.tube4_l.prepare(sample_rate, block_size);
        voice.tube4_r.prepare(sample_rate, block_size);
        voice.tube5_l.prepare(sample_rate, block_size);
        voice.tube5_r.prepare(sample_rate, block_size);
        voice.tube6_l.prepare(sample_rate, block_size);
        voice.tube6_r.prepare(sample_rate, block_size);*/
    }

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {
        /*let input_l = inputs.audio[0].left.as_channel().as_array();
        let input_r = inputs.audio[0].right.as_channel().as_array();

        let pregain = self.pregain * 40.0 - 20.0;
        let gain = self.gain * 40.0 - 20.0;

        match self.selected {
            0 => {
                voice.tube1_l.set_param(0, pregain);
                voice.tube1_r.set_param(0, pregain);
                voice.tube1_l.set_param(1, gain);
                voice.tube1_r.set_param(1, gain);
                voice.tube1_l.process(&input_l, &mut outputs.audio[0].as_array_mut());
                voice.tube1_r.process(&input_r, &mut outputs.audio[0].as_array_mut()[0..]);
            },
            1 => {
                voice.tube2_l.set_param(0, pregain);
                voice.tube2_r.set_param(0, pregain);
                voice.tube2_l.set_param(1, gain);
                voice.tube2_r.set_param(1, gain);
                voice.tube2_l.process(&input_l, &mut outputs.audio[0].left.as_channel_mut().as_array_mut());
                voice.tube2_r.process(&input_r, &mut outputs.audio[0].right.as_channel_mut().as_array_mut());
            },
            2 => {
                voice.tube3_l.set_param(0, pregain);
                voice.tube3_r.set_param(0, pregain);
                voice.tube3_l.set_param(1, gain);
                voice.tube3_r.set_param(1, gain);
                voice.tube3_l.process(&input_l, &mut outputs.audio[0].left.as_channel_mut().as_array_mut());
                voice.tube3_r.process(&input_r, &mut outputs.audio[0].right.as_channel_mut().as_array_mut());
            },
            3 => {
                voice.tube4_l.set_param(0, pregain);
                voice.tube4_r.set_param(0, pregain);
                voice.tube4_l.set_param(1, gain);
                voice.tube4_r.set_param(1, gain);
                voice.tube4_l.process(&input_l, &mut outputs.audio[0].left.as_channel_mut().as_array_mut());
                voice.tube4_r.process(&input_r, &mut outputs.audio[0].right.as_channel_mut().as_array_mut());
            },
            4 => {
                voice.tube5_l.set_param(0, pregain);
                voice.tube5_r.set_param(0, pregain);
                voice.tube5_l.set_param(1, gain);
                voice.tube5_r.set_param(1, gain);
                voice.tube5_l.process(&input_l, &mut outputs.audio[0].left.as_channel_mut().as_array_mut());
                voice.tube5_r.process(&input_r, &mut outputs.audio[0].right.as_channel_mut().as_array_mut());
            },
            5 => {
                voice.tube6_l.set_param(0, pregain);
                voice.tube6_r.set_param(0, pregain);
                voice.tube6_l.set_param(1, gain);
                voice.tube6_r.set_param(1, gain);
                voice.tube6_l.process(&input_l, &mut outputs.audio[0].left.as_channel_mut().as_array_mut());
                voice.tube6_r.process(&input_r, &mut outputs.audio[0].right.as_channel_mut().as_array_mut());
            },
            _ => panic!("Dropdown value out of range"),
        }*/
    }
}

/*faust!(Tube1,
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
*/