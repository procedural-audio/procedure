use crate::*;

pub struct NotesToControl;

impl Module for NotesToControl {
    type Voice = ();

    const INFO: Info = Info {
        title: "",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(120, 135),
        voicing: Voicing::Polyphonic,
        inputs: &[Pin::Notes("Notes Input", 15)],
        outputs: &[
            Pin::Control("Gate", 15),
            Pin::Control("Pitch", 45),
            Pin::Control("Pressure", 75),
            Pin::Control("Timbre", 105)
        ],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        Self
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 20),
            size: (40, 40),
            child: Svg {
                path: "comparisons/greater_equal.svg",
                color: Color::RED, // MAKE THIS A GRADIENT IF POSSIBLE
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        /*outputs.control[0] = 0.0; // Set gate to 0.0

        for event in &inputs.events[0] {
            match event {
                Event::NoteOn { note: _, offset: _ } => {
                    outputs.control[0] = 1.0;
                }
                Event::NoteOff { id: _ } => {}
                Event::Pitch { id: _, freq: _ } => {}
                Event::Pressure { id: _, pressure: _ } => {}
                Event::Controller { id: _, value: _ } => {}
                Event::ProgramChange { id: _, value: _ } => {}
                Event::None => {
                    break;
                }
            }
        }*/
    }
}
