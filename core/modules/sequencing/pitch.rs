use crate::*;

pub struct Pitch;

impl Module for Pitch {
    type Voice = ();

    const INFO: Info = Info {
        title: Title("Pitch", Color::GREEN),
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 15),
            Pin::Control("Pitch (hz)", 45),
        ],
        outputs: &[Pin::Notes("Notes Output", 30)],
    };

    
    fn new() -> Self {
        Self
    }
    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }
    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 20),
            size: (40, 40),
            child: Svg {
                path: "comparisons/equals.svg",
                color: Color::GREEN,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let new_pitch = inputs.control[0];

        for event in &inputs.events[0] {
            match event {
                Event::NoteOn { note, offset } => {
                    outputs.events[0].push(Event::NoteOn {
                        note: note.with_pitch(new_pitch),
                        offset: *offset,
                    });
                }
                Event::Pitch { id, freq: _ } => {
                    outputs.events[0].push(Event::Pitch {
                        id: *id,
                        freq: new_pitch,
                    });
                }
                _ => outputs.events[0].push(*event),
            }
        }
    }
}
