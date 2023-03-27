use crate::*;

use rand::Rng;

pub struct Random {
    rng: rand::rngs::ThreadRng,
}

impl Module for Random {
    type Voice = ();

    const INFO: Info = Info {
        title: "",
        id: "default.control.operations.random",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(85, 60),
        voicing: Voicing::Polyphonic,
        inputs: &[],
        outputs: &[
            Pin::Control("Output (0-1)", 22)
        ],
        path: &["Control", "Sources", "Random"],
        presets: Presets::NONE
    };
    
    fn new() -> Self {
        Self {
            rng: rand::thread_rng(),
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (12, 12),
            size: (36, 36),
            child: Icon {
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
