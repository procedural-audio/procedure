use crate::*;

pub struct GlobalTime;

impl Module for GlobalTime {
    type Voice = ();

    const INFO: Info = Info {
        title: "",
        id: "default.time.global_time",
        version: "0.0.0",
        color: Color::PURPLE,
        size: Size::Static(85, 60),
        voicing: Voicing::Monophonic,
        inputs: &[],
        outputs: &[Pin::Time("Time Output", 22)],
        path: &["Time", "Clocks", "Global Time"]
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
            position: (15, 15),
            size: (30, 30),
            child: Icon {
                path: "clock.svg",
                color: Color::PURPLE,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {
        // println!("Global time: {} {} {}", outputs.time[0].start(), outputs.time[0].end(), outputs.time[0].length());
    }
}
