use modules::*;

pub struct Length {
    value: f32,
}

pub struct LengthVoice {
    playing: Option<(Id, f64)>,
}

impl Module for Length {
    type Voice = LengthVoice;

    const INFO: Info = Info {
        title: "Length",
        id: "default.sequencing.length",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 25),
            Pin::Control("Length (beats)", 50),
            Pin::Time("Time", 50+25),
        ],
        outputs: &[
            Pin::Notes("Notes Output", 25)
        ],
        path: &["Notes", "Effects", "Length"]
    };

    fn new() -> Self {
        Self { value: 0.25 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            playing: None
        }
    }

    fn load(&mut self, _version: &str, state: &State) {
        self.value = state.load("value");
    }

    fn save(&self, state: &mut State) {
        state.save("value", self.value);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Beats",
                color: Color::GREEN,
                value: &mut self.value,
                feedback: Box::new(|v| rate_to_str(linear_to_rate_quantized(v))),
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let mut value = linear_to_rate_quantized(self.value);

        if inputs.control.connected(0) {
            value = inputs.control[0];
        }

        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch: _, pressure: _ } => {
                    if let Some((id, _)) = voice.playing {
                        outputs.events[0].push(
                            NoteMessage {
                                id,
                                offset: 0,
                                note: Event::NoteOff
                            }
                        );
                    } else {
                        voice.playing = Some((msg.id, 0.0));
                        outputs.events[0].push(*msg);
                    }
                },
                Event::NoteOff => (),
                _ => outputs.events[0].push(*msg)
            }
        }

        if let Some((id, time)) = &mut voice.playing {
            *time += f64::abs(inputs.time[0].length);

            if *time >= value as f64 {
                outputs.events[0].push(
                    NoteMessage {
                        id: *id,
                        offset: 0,
                        note: Event::NoteOff
                    }
                );

                voice.playing = None;
            }
        }
    }
}

fn linear_to_rate_quantized(v: f32) -> f32 {
    let v = f32::clamp(v, 0.0, 1.0);
    let v = v - 0.05;

    if v <= 0.0 {
        1.0 / 32.0
    } else if v > 0.0 && v < 0.1 {
        1.0 / 16.0
    } else if v > 0.1 && v <= 0.2 {
        1.0 / 8.0
    } else if v > 0.2 && v <= 0.3 {
        1.0 / 4.0
    } else if v > 0.3 && v <= 0.4 {
        1.0 / 2.0
    } else if v > 0.4 && v <= 0.5 {
        1.0
    } else if v > 0.5 && v <= 0.6 {
        2.0
    } else if v > 0.6 && v <= 0.7 {
        4.0
    } else if v > 0.7 && v <= 0.8 {
        8.0
    } else if v > 0.8 && v <= 0.9 {
        16.0
    } else if v > 0.9 {
        32.0
    } else {
        panic!("Unsupported rate");
    }
}

fn rate_to_str(v: f32) -> String {
    if v == 1.0 / 64.0 {
        String::from("1 / 64")
    } else if v == 1.0 / 32.0 {
        String::from("1 / 32")
    } else if v == 1.0 / 16.0 {
        String::from("1 / 16")
    } else if v == 1.0 / 8.0 {
        String::from("1 / 8")
    } else if v == 1.0 / 4.0 {
        String::from("1 / 4")
    } else if v == 1.0 / 2.0 {
        String::from("1 / 2")
    } else {
        format!("{}", f32::round(v) as u32)
    }
}
