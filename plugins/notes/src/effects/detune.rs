use modules::*;

pub struct Detune {
    value: f32
}

fn detune(amount: f32) -> f32 {
    (amount * 2.0 - 1.0) * (1.0 / 12.0) + 1.0
}

impl Module for Detune {
    type Voice = ();

    const INFO: Info = Info {
        title: "Detune",
        id: "default.sequencing.detune",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 25),
            Pin::Control("Detune Amount (0 - 1)", 55),
        ],
        outputs: &[
            Pin::Notes("Notes Output", 25)
        ],
        path: &["Notes", "Effects", "Detune"],
        presets: Presets::NONE
    };
    
    fn new() -> Self {
        Self {
            value: 0.5
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Cents",
                color: Color::GREEN,
                value: &mut self.value,
                feedback: Box::new(|v| {
                    format!("{:.2}", v * 200.0 - 100.0)
                }),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let mut d = detune(self.value);

        if inputs.control.connected(0) {
            d = detune(f32::clamp(inputs.control[0], 0.0, 1.0));
        }

        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure } => {
                    outputs.events[0].push(
                        NoteMessage {
                            id: msg.id,
                            offset: msg.offset,
                            note: Event::NoteOn {
                                pitch: pitch * d,
                                pressure
                            }
                        }
                    );
                },
                Event::Pitch(pitch) => {
                    outputs.events[0].push(
                        NoteMessage {
                            id: msg.id,
                            offset: msg.offset,
                            note: Event::Pitch(pitch * d)
                        }
                    );
                },
                _ => outputs.events[0].push(*msg)
            }
        }
    }
}
