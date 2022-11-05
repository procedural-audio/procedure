use crate::modules::*;

pub struct Reverse;

impl Module for Reverse {
    type Voice = ();

    const INFO: Info = Info {
        name: "Rev",
                color: Color::PURPLE,
        size: Size::Static(100, 75),
        voicing: Voicing::Monophonic,
        params: &[],
inputs: &[
            Pin::Time("Time Input", 15),
            Pin::Control("Reverse (bool)", 45),
        ],
        outputs: &[Pin::Time("Time Output", 30)],
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
            position: (32, 25),
            size: (36, 36),
            child: Svg {
                path: "operations/negative.svg",
                color: Color::PURPLE,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _vars: &Vars, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {
        /*if inputs.control[0].get() < 0.5 {
            outputs.time[0].set(inputs.time[0].get());
        } else {
            outputs.time[0].set(-inputs.time[0].get());
        }*/
    }
}
