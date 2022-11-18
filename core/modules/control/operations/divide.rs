use crate::*;

pub struct Divide;

impl Module for Divide {
    type Voice = ();

    const INFO: Info = Info {
        name: "Div",
        color: Color::RED,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Input 1", 15),
            Pin::Control("Input 2", 45),
        ],
        outputs: &[
            Pin::Control("Output", 30)
        ],
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
            position: (30, 25),
            size: (40, 40),
            child: Svg {
                path: "operations/divide.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = inputs.control[0] / inputs.control[1];
    }
}
