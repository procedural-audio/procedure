use crate::*;

pub struct Rate;

impl Module for Rate {
    type Voice = ();

    const INFO: Info = Info {
        title: "Rate",
        id: "default.time.rate",
        version: "0.0.0",
        color: Color::PURPLE,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Time("Time Input", 15),
            Pin::Control("Rate", 45)
        ],
        outputs: &[
            Pin::Time("Time Output", 30)
        ],
        path: &["Time", "Effects", "Rate"]
    };

    
    fn new() -> Self {
        Self
    }
    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }
    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (32, 25),
            size: (36, 36),
            child: Icon {
                path: "operations/multiply.svg",
                color: Color::PURPLE,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let rate = inputs.control[0] as f64;
        let new_time = inputs.time[0].rate(rate);
        outputs.time[0] = new_time;
    }
}
