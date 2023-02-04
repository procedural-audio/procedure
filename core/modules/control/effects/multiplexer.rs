use crate::*;

pub struct Multiplexer;

impl Module for Multiplexer {
    type Voice = ();

    const INFO: Info = Info {
        title: "Mult",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(100, 45+25*8),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Input 1", 10+25*0),
            Pin::Control("Input 2", 10+25*1),
            Pin::Control("Input 3", 10+25*2),
            Pin::Control("Input 4", 10+25*3),
            Pin::Control("Input 5", 10+25*4),
            Pin::Control("Input 6", 10+25*5),
            Pin::Control("Input 7", 10+25*6),
            Pin::Control("Input 8", 10+25*7),
            Pin::Control("Selector (0-7)", 20+25*8),
        ],
        outputs: &[
            Pin::Control("Output", 7+25*4),
        ],
        path: "Control/Effects/Multiplexer",
        presets: Presets::NONE
    };

    fn new() -> Self { Self }
    fn new_voice(&self, _index: u32) -> Self::Voice { () }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 100),
            size: (40, 40),
            child: Icon {
                path: "comparisons/equal.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let index = f32::clamp(f32::round(inputs.control[8]), 0.0, 7.0) as usize;
        outputs.control[0] = inputs.control[index];
    }
}
