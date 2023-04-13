use crate::*;

pub struct Reverse;

impl Module for Reverse {
    type Voice = ();

    const INFO: Info = Info {
        title: "Arr",
        id: "default.time.reverse",
        version: "0.0.0",
        color: Color::PURPLE,
        size: Size::Static(100, 75),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Time("Time Input", 15),
            Pin::Control("Reverse (bool)", 45),
        ],
        outputs: &[Pin::Time("Time Output", 30)],
        path: &["Time", "Arrangement", "Arranger"],
        presets: Presets::NONE
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
                path: "operations/negative.svg",
                color: Color::PURPLE,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {
        /*if inputs.control[0] < 0.5 {
            outputs.time[0].set(inputs.time[0].get());
        } else {
            outputs.time[0].set(-inputs.time[0].get());
        }*/
    }
}
