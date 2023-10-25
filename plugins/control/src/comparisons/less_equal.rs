use modules::*;

pub struct LessEqual;

impl Module for LessEqual {
    type Voice = ();

    const INFO: Info = Info {
        title: "",
        id: "default.comparisons.less_equal",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Control Input", 15),
            Pin::Control("Control Input", 45),
        ],
        outputs: &[
            Pin::Control("Control Output", 30)
        ],
        path: &["Control", "Comparisons", "Less Equal"]
    };

    fn new() -> Self { Self }
    fn new_voice(&self, _index: u32) -> Self::Voice { () }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 20),
            size: (40, 40),
            child: Icon {
                path: "comparisons/less_equal.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if inputs.control[0] <= inputs.control[1] {
            outputs.control[0] = 1.0;
        } else {
            outputs.control[0] = 0.0;
        }
    }
}
