use modules::*;

pub struct Drift {
    rng: rand::rngs::ThreadRng,
    value: f32
}

impl Module for Drift {
    type Voice = ();

    const INFO: Info = Info {
        title: "Drift",
        id: "default.sequencing.drift",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 25),
            Pin::Control("Drift Steps", 55),
        ],
        outputs: &[Pin::Notes("Notes Output", 25)],
        path: &["Notes", "Effects", "Drift"],
        presets: Presets::NONE
    };
    
    fn new() -> Self {
        Self {
            rng: rand::thread_rng(),
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

        if inputs.control.connected(0) {
            steps = f32::round(inputs.control[0]);
        }

        if steps < 0.0 {
            steps = steps / 2.0;
        }

        for event in &inputs.events[0] {
            /*match event {
                Event::NoteOn { note, offset } => {
                    outputs.events[0].push(
                        Event::NoteOn {
                            note: note.with_pitch(note.pitch * (1.0 + steps / 12.0)),
                            offset: *offset,
                        }
                    );
                }
                Event::Pitch { id, freq } => {
                    outputs.events[0].push(
                    Event::Pitch {
                            id: *id,
                            freq: freq * (1.0 + steps / 12.0)
                        }
                    );
                }
                e => outputs.events[0].push(*e)
            }*/
        }
    }
}
