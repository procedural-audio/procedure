use crate::modules::*;

use rand::Rng;

pub struct Random {
    rng: rand::rngs::ThreadRng,
}

impl Module for Random {
    type Voice = ();

    const INFO: Info = Info {
        name: "",
        color: Color::RED,
        size: Size::Static(85, 60),
        voicing: Voicing::Polyphonic,
        inputs: &[],
        outputs: &[
            Pin::Control("Output (0-1)", 22)
        ],
    };

    
    fn new() -> Self {
        Self {
            rng: rand::thread_rng(),
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }
    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (12, 12),
            size: (36, 36),
            child: Svg {
                path: "random.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = self.rng.gen_range(0.0..=1.0);
    }
}
