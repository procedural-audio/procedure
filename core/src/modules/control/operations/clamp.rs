use crate::modules::*;

pub struct Clamp;

impl Module for Clamp {
    type Voice = ();

    const INFO: Info = Info {
        name: "Clamp",
                color: Color::RED,
        size: Size::Static(110, 105),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Input", 15),
            Pin::Control("Min", 45),
            Pin::Control("Max", 75),
        ],
        outputs: &[Pin::Control("Output", 45)],
    };

    const PARAMS: Params = &[];

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
                path: "comparisons/clamp.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _vars: &Vars, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = f32::clamp(
            inputs.control[0],
            inputs.control[1],
            inputs.control[2],
        );
    }
}
