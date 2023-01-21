use crate::*;

pub struct Pressure;

impl Module for Pressure {
    type Voice = ();

    const INFO: Info = Info {
        title: "Pressure",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 15),
            Pin::Control("Pressure (0-1)", 45),
        ],
        outputs: &[Pin::Notes("Notes Output", 30)],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        Self
    }
    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }
    fn load(&mut self, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
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
        let new_pressure = inputs.control[0];

        /*for event in &inputs.events[0] {
            match event {
                Event::NoteOn { note, offset } => {
                    outputs.events[0].push(Event::NoteOn {
                        note: note.with_pressure(new_pressure),
                        offset: *offset,
                    });
                }
                Event::Pressure { id, pressure: _ } => {
                    outputs.events[0].push(Event::Pressure {
                        id: *id,
                        pressure: new_pressure,
                    });
                }
                _ => outputs.events[0].push(*event),
            }
        }*/
    }
}
