use crate::modules::*;

pub struct Negative;

impl Module for Negative {
    type Voice = ();

    const INFO: Info = Info {
        name: "Neg",
                color: Color::RED,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        params: &[],
        inputs: &[
            Pin::Control("Control Input", 15),
            Pin::Control("Control Input", 45),
        ],
        outputs: &[Pin::Control("Control Output", 30)],
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
                path: "operations/negative.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _vars: &Vars, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = inputs.control[0] - inputs.control[1];
    }
}
