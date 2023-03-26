use crate::*;

pub struct Pitch;

impl Module for Pitch {
    type Voice = ();

    const INFO: Info = Info {
        title: "Pitch",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 15),
            Pin::Control("Pitch (hz)", 45),
        ],
        outputs: &[Pin::Notes("Notes Output", 30)],
        path: &["Notes", "Effects", "Pitch"],
        presets: Presets::NONE
    };

    
    fn new() -> Self {
        Self
    }
    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }
    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 20),
            size: (40, 40),
            child: Icon {
                path: "comparisons/equals.svg",
                color: Color::GREEN,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let new_pitch = inputs.control[0];

        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch: _, pressure } => {
                    outputs.events[0].push(
                        NoteMessage {
                            id: msg.id,
                            offset: msg.offset,
                            note: Event::NoteOn {
                                pitch: new_pitch,
                                pressure
                            }
                        }
                    );
                },
                Event::Pitch(_) => {
                    outputs.events[0].push(
                        NoteMessage {
                            id: msg.id,
                            offset: msg.offset,
                            note: Event::Pitch(new_pitch)
                        }
                    );
                }
                _ => outputs.events[0].push(*msg),
            }
        }
    }
}
