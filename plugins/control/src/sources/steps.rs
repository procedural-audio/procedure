use modules::*;

pub struct Steps {
    faders: [f32; 8],
}

impl Module for Steps {
    type Voice = u32;

    const INFO: Info = Info {
        title: "Steps",
        id: "default.control.steps",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(400, 200),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Time("Time", 10)
        ],
        outputs: &[
            Pin::Control("Steps Output", 10)
        ],
        path: &["Control", "Sources", "Steps"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            faders: [0.5; 8],
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice { index }
    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(
            Padding {
                padding: (10, 35, 10, 10),
                child: widget::GridBuilder {
                    columns: 8,
                    state: &mut self.faders,
                    builder: | _i, v | {
                        widget::Fader {
                            value: v,
                            color: Color::RED
                        }
                    }
                }
            }
        )
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        inputs.time[0].on_each(1.0, | beat | {
            outputs.control[0] = self.faders[beat as usize % self.faders.len()];
        });
    }
}
