use crate::*;

pub struct Scale {
    keys: [Key; 12]
}

impl Scale {
    fn quantize(&self, pitch: f32) -> f32 {
        // TODO: Implement pitch quantization
        pitch
    }
}

impl Module for Scale {
    type Voice = ();

    const INFO: Info = Info {
        title: "Scale",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(200, 120),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 10),
        ],
        outputs: &[
            Pin::Notes("Notes Output", 10)
        ],
        path: "Category 1/Category 2/Module Name"
    };

    fn new() -> Self {
        Self {
            keys: [
                Key { down: false }; 12
            ]
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice { () }
    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Padding {
            padding: (10, 35, 10, 10),
            child: widget::Keyboard {
                keys: &mut self.keys,
                on_event: | event, keys | {
                    match event {
                        KeyEvent::Press(i) => {
                            keys[i].down = !keys[i].down;
                        },
                        KeyEvent::Release(_) => {},
                    }
                }
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure } => {
                    outputs.events[0].push(
                        NoteMessage {
                            id: msg.id,
                            offset: msg.offset,
                            note: Event::NoteOn {
                                pitch: self.quantize(pitch),
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
                            note: Event::Pitch(self.quantize(pitch))
                        }
                    );
                },
                _ => outputs.events[0].push(*msg)
            }
        }
    }
}