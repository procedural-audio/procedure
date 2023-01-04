use rand::Rng;

use crate::*;

pub struct Detune {
    rng: rand::rngs::ThreadRng,
    value: f32
}

impl Module for Detune {
    type Voice = ();

    const INFO: Info = Info {
        title: "Detune",
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
        path: "Category 1/Category 2/Module Name"
    };
    
    fn new() -> Self {
        Self {
            rng: rand::thread_rng(),
            value: 0.5
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Amount",
                color: Color::GREEN,
                value: &mut self.value,
                feedback: Box::new(|v| {
                    format!("{:.2}", v)
                }),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if self.value > 0.0 {
            for msg in &inputs.events[0] {
                let detune = (self.rng.gen_range(-self.value..self.value) / 60.0) + 1.0;

                match msg.note {
                    Event::NoteOn { pitch, pressure } => {
                        outputs.events[0].push(
                            NoteMessage {
                                id: msg.id,
                                offset: msg.offset,
                                note: Event::NoteOn {
                                    pitch: pitch * detune,
                                    pressure: pressure
                                }
                            }
                        );
                    },
                    Event::Pitch(pitch) => {
                        outputs.events[0].push(
                            NoteMessage {
                                id: msg.id,
                                offset: msg.offset,
                                note: Event::Pitch(pitch * detune)
                            }
                        );
                    },
                    _ => outputs.events[0].push(*msg)
                }
            }
        } else {
            outputs.events[0].replace(&inputs.events[0]);
        }
    }
}
