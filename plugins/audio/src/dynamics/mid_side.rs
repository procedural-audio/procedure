use crate::*;

pub struct MidSide {
    value: f32,
}

impl Module for MidSide {
    type Voice = ();

    const INFO: Info = Info {
        title: "Mid-Side",
        id: "default.effects.dynamics.mid_side",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 25),
            Pin::Control("M/S Amount", 55),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 25)
        ],
        path: &["Audio", "Dynamics", "Mid-Side"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _version: &str, state: &State) {
        self.value = state.load("ms");
    }

    fn save(&self, state: &mut State) {
        state.save("ms", self.value);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "M/S",
                color: Color::BLUE,
                value: &mut self.value,
                feedback: Box::new(| v| {
                    if v == 0.5 {
                        String::from("C")
                    } else if v < 0.5 {
                        format!("{:.1} M", 1.0 - v)
                    } else {
                        format!("{:.1} S", v)
                    }
                })
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let value = if inputs.control.connected(0) {
            inputs.control[0].clamp(0.0, 1.0)
        } else {
            self.value
        };

        outputs.audio[0].copy_from(&inputs.audio[0]);
        outputs.audio[0].apply(| s | {
            let mid = (s.left + s.right) * (1.0 - value);
            let side = (s.left - s.right) * value;

            Stereo {
                left: mid + side,
                right: mid - side
            }
        });
    }
}
