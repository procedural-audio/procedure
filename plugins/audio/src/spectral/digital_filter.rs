use crate::*;

use pa_dsp::*;

pub struct DigitalFilter {
    selected: usize,
    cutoff: f32,
    resonance: f32,
}

pub struct DigitalFilterVoice {
}

impl Module for DigitalFilter {
    type Voice = DigitalFilterVoice;

    const INFO: Info = Info {
        title: "Digital Filter",
        id: "default.effects.filters.digital_filter",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(200, 160),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 20),
            Pin::Control("Control Input", 50),
            Pin::Control("Control Input", 80),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 20)
        ],
        path: &["Audio", "Spectral", "Digital Filter"],
        presets: Presets::NONE
    };

    
    fn new() -> Self {
        Self {
            selected: 0,
            cutoff: 1.0,
            resonance: 0.0,
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Stack {
            children: (
                Transform {
                    position: (40, 110),
                    size: (120, 40),
                    child: Dropdown {
                        index: &mut self.selected,
                        color: Color::BLUE,
                        elements: &[
                            "Korg 35",
                            "Diode",
                            "Oberheim",
                            "Ladder",
                            "Half Ladder",
                            "Moog",
                            "Sallen Key",
                        ],
                    },
                },
                Transform {
                    position: (40, 35),
                    size: (60, 70),
                    child: Knob {
                        text: "Cutoff", // Cutoff
                        color: Color::BLUE,
                        value: &mut self.cutoff,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70, 35),
                    size: (60, 70),
                    child: Knob {
                        text: "Res", // Resonance
                        color: Color::BLUE,
                        value: &mut self.resonance,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
            ),
        });
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let input = inputs.audio[0].as_slice();
        let output = outputs.audio[0].as_slice_mut();
        let cutoff = f32::clamp(inputs.control[0], 0.0, 1.0);
    }
}

/*
import("stdfaust.lib");
freq = hslider("freq",0.5,0,1,0.001);
res = hslider("res",1,0.5,10,0.01);
process = fi.svf.lp(freq, q);
*/
