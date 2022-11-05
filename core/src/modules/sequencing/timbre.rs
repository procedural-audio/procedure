use crate::modules::*;

pub struct Timbre;

impl Module for Timbre {
    type Voice = ();

    const INFO: Info = Info {
        name: "Timbre",
                color: Color::GREEN,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        params: &[],
inputs: &[
            Pin::Notes("Notes Input", 15),
            Pin::Control("Timbre (0-1)", 45),
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

    fn process(&mut self, _vars: &Vars, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let new_timbre = inputs.control[0].get();

        for event in &inputs.events[0] {
            match event {
                Event::NoteOn { note, offset } => {
                    outputs.events[0].push(Event::NoteOn {
                        note: note.with_timbre(new_timbre),
                        offset: *offset,
                    });
                }
                Event::Timbre { id, timbre: _ } => {
                    outputs.events[0].push(Event::Timbre {
                        id: *id,
                        timbre: new_timbre,
                    });
                }
                _ => outputs.events[0].push(*event),
            }
        }
    }
}
