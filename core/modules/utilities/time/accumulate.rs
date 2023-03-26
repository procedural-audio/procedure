use crate::*;

pub struct Accumulator {
    last: f32,
    time: f64
}

impl Module for Accumulator {
    type Voice = u32;

    const INFO: Info = Info {
        title: "Acc",
        version: "0.0.0",
        color: Color::PURPLE,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Time("Time Input", 15),
            Pin::Control("Reset", 45)
        ],
        outputs: &[
            Pin::Time("Time Output", 30)
        ],
        path: &["Time", "Accumulate"],
        presets: Presets::NONE
    };

    
    fn new() -> Self {
        Self {
            last: 0.0,
            time: 0.0
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        index
    }
    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (32, 25),
            size: (36, 36),
            child: Icon {
                path: "operations/add.svg",
                color: Color::PURPLE,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if self.last < 0.5 && inputs.control[0] > 0.5 {
            self.time = 0.0;
        }

        self.last = inputs.control[0];
        outputs.time[0] = inputs.time[0].shift(self.time - inputs.time[0].start());

        if *voice == 0 {
            self.time += inputs.time[0].length();
        }
    }
}
