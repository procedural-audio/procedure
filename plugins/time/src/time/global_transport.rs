use crate::*;

pub struct GlobalTransport;

impl Module for GlobalTransport {
    type Voice = ();

    const INFO: Info = Info {
        title: "Global Transport",
        id: "default.time.global_transport",
        version: "0.0.0",
        color: Color::PURPLE,
        size: Size::Static(300, 150),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Control("BPM", 15),
            Pin::Control("Play", 15+25*1),
            Pin::Control("Pause", 15+25*2),
            Pin::Control("Stop", 15+25*3)
        ],
        outputs: &[
            Pin::Time("Time Output", 15)
        ],
        path: &["Time", "Global Transport"],
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
