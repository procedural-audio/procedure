use crate::*;

pub struct Transpose {
    value: f32,
}

impl Module for Transpose {
    type Voice = ();

    const INFO: Info = Info {
        title: "Transpose",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 25),
            Pin::Control("Transpose Steps", 55),
        ],
        outputs: &[Pin::Notes("Notes Output", 25)],
        path: "Category 1/Category 2/Module Name"
    };
    
    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Steps",
                color: Color::GREEN,
                value: &mut self.value,
                feedback: Box::new(|v| {
                    let steps = f32::round(v * 24.0 - 12.0) as i32;
                    format!("{}", steps)
                }),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let mut steps = f32::round(self.value * 24.0 - 12.0);

        if inputs.control.is_connected(0) {
            steps = f32::round(inputs.control[0]);
        }

        if steps < 0.0 {
            steps = steps / 2.0;
        }

        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure } => {
                    outputs.events[0].push(
                        NoteMessage {
                            id: msg.id,
                            offset: msg.offset,
                            note: Event::NoteOn {
                                pitch: pitch * (1.0 + steps / 12.0),
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
                            note: Event::Pitch(pitch * (1.0 + steps / 12.0))
                        }
                    );
                },
                _ => outputs.events[0].push(*msg)
            }
        }
    }
}
