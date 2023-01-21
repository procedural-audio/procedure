use crate::*;

pub struct Subtract;

impl Module for Subtract {
    type Voice = ();

    const INFO: Info = Info {
        title: "Sub",
        version: "0.0.0",
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
        path: "Category 1/Category 2/Module Name"
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
            child: Svg {
                path: "operations/subtract.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = inputs.control[0] - inputs.control[1];
    }
}
