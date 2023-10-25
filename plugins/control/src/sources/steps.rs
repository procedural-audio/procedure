use modules::*;

pub struct Steps {
    faders: [(f32, Color); 8],
    callback: Callback,
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
        path: &["Control", "Sources", "Steps"]
    };

    fn new() -> Self {
        Self {
            faders: [(0.5, Color::RED); 8],
            callback: Callback::new(),
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        index
    }

    fn load(&mut self, _version: &str, state: &State) {
        for (i, (v, _c)) in self.faders.iter_mut().enumerate() {
            *v = state.load(i);
        }
    }

    fn save(&self, state: &mut State) {
        for (i, (v, _c)) in self.faders.iter().enumerate() {
            state.save(i, *v);
        }
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(
            Padding {
                padding: (5, 35, 5, 5),
                child: Refresh {
                    callback: &mut self.callback,
                    child: widget::GridBuilder {
                        columns: 8,
                        state: &mut self.faders,
                        builder: | _i, v | {
                            Padding {
                                padding: (1, 0, 1, 0),
                                child: widget::Fader {
                                    value: &mut v.0,
                                    color: &v.1,
                                }
                            }
                        }
                    }
                }
            }
        )
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        inputs.time[0].on_each(1.0, | beat | {
            let length = self.faders.len();
            if *voice == 0 {
                for (i, fader) in &mut self.faders.iter_mut().enumerate() {
                    if i == (beat % length) {
                        fader.1 = Color::PURPLE;
                    } else {
                        fader.1 = Color::RED;
                    }
                }

                self.callback.trigger();
            }

            outputs.control[0] = self.faders[beat % self.faders.len()].0;
        });
    }
}
