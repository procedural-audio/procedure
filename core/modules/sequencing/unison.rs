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
            Pin::Control("Transpose Amount", 55)
        ],
        outputs: &[
            Pin::Notes("Notes Output", 25)
        ],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        Self {
            value: 0.5,
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(
            Transform {
                position: (35, 30),
                size: (50, 70),
                child: Knob {
                    text: "Steps",
                    color: Color::GREEN,
                    value: &mut self.value,
                    feedback: Box::new(| v | {
                        let steps = f32::round(v * 24.0 - 12.0) as i32;
                        format!("{}", steps)
                    })
                }
            }
        )
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {

    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let mut steps = f32::round(self.value * 24.0 - 12.0);

        if steps < 0.0 {
            steps = steps / 2.0;
        }

        let input = inputs.events[0].as_ref();
        let output = outputs.events[0].as_mut();

        for i in 0..input.len() {
            match &input[i] {
                Event::NoteOn { note, offset } => {
                    output[i] = Event::NoteOn {
                        note: note.with_pitch(note.pitch * (1.0 + steps / 12.0)),
                        offset: *offset,
                    }
                },
                e => output[i] = *e,
            }
        }
    } 
}
