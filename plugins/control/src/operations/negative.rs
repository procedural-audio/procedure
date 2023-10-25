use modules::*;

pub struct Negative;

impl Module for Negative {
    type Voice = ();

    const INFO: Info = Info {
        title: "Neg",
        id: "default.control.operations.negative",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Input 1", 15),
        ],
        outputs: &[
            Pin::Control("Output", 30)
        ],
        path: &["Control", "Operations", "Negative"]
    };
    
    fn new() -> Self {
        Self
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 25),
            size: (40, 40),
            child: Icon {
                path: "operations/negative.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = inputs.control[0];
    }
}
