use crate::*;

pub struct LocalTime;

impl Module for LocalTime {
    type Voice = ();

    const INFO: Info = Info {
        title: "Time",
        version: "0.0.0",
        color: Color::PURPLE,
        size: Size::Static(100, 75),
        voicing: Voicing::Monophonic,
        inputs: &[],
        outputs: &[Pin::Time("Time Output", 30)],
        path: &["Time", "Local Time"],
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
            position: (30, 20),
            size: (40, 40),
            child: Icon {
                path: "comparisons/greater_equal.svg",
                color: Color::PURPLE,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {
        // Time buffer automatically set
    }
}
