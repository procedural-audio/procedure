use modules::*;

pub struct SetPitch;

impl Module for SetPitch {
    type Voice = ();

    const INFO: Info = Info {
        title: "Set Hz",
        id: "default.sequencing.set_pitch",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(120, 60),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 10),
            Pin::Control("Pitch (hz)", 35),
        ],
        outputs: &[
            Pin::Notes("Notes Output", 10)
        ],
        path: &["Notes", "Effects", "Set Pitch"]
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
        if inputs.control.connected(0) {
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
        } else {
            for msg in &inputs.events[0] {
                outputs.events[0].push(*msg);
            }
        }
    }
}
