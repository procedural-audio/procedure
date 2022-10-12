use tonevision_types::*;

pub struct And;

impl Module for And {
    type Voice = ();

    const INFO: Info = Info {
        name: "",
        color: Color::Blue,
        size: (100, 75),
        multi_voice: false,
        inputs: &[Pin::Control(10, 15), Pin::Control(10, 45)],
        outputs: &[Pin::Control(75, 30)],
    };

    fn new() -> Self { Self }
    fn new_voice() -> Self::Voice { () }
    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'m, 'w>(&'m mut self, _ui: &'m UI) -> Box<dyn WidgetNew + 'w> where 'm: 'w {
        Box::new(
            Transform {
                position: (30, 20),
                size: (40, 40),
                child: Svg {
                    path: "logic/and.svg",
                    color: Color::Red,
                }
            }
        )
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if inputs.control[0].get() == 0.0 || inputs.control[1].get() == 0.0 {
            outputs.control[0].set(0.0);
        } else {
            outputs.control[0].set(1.0);
        }
    } 
}

