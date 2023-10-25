use crate::*;

pub struct Spacetime;

impl Module for Spacetime {
    type Voice = ();

    const INFO: Info = Info {
        title: "Spacetime",
        id: "default.time.space_time",
        version: "0.0.0",
        color: Color::PURPLE,
        size: Size::Static(160, 215),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Time("Proper Time", 10),
            Pin::Control("Reference Velocity", 10+25),
            Pin::Control("Relative Velocity 1", 22+25*2),
            Pin::Control("Relative Velocity 2", 22+25*4),
            Pin::Control("Relative Velocity 3", 22+25*6),
        ],
        outputs: &[
            Pin::Time("Relative Time 1", 10+25*2),
            Pin::Control("Length Contraction 1", 10+25*3),
            Pin::Time("Relative Time 2", 10+25*4),
            Pin::Control("Length Contraction 2", 10+25*5),
            Pin::Time("Relative Time 3", 10+25*6),
            Pin::Control("Length Contraction 3", 10+25*7),
        ],
        path: &["Time", "Clocks", "Spacetime"]
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
            position: (35, 60),
            size: (30, 30),
            child: EmptyWidget
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {
        // println!("Global time: {} {} {}", outputs.time[0].start(), outputs.time[0].end(), outputs.time[0].length());
    }
}
