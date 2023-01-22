use crate::*;

pub struct MidiOutput;

impl Module for MidiOutput {
    type Voice = ();

    const INFO: Info = Info {
        title: "",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(100, 100),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Notes("Midi Output", 30)
        ],
        outputs: &[],
        path: "Category 1/Category 2/Module Name",
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
            child: Svg {
                path: "logos/midi2.svg",
                color: Color::GREEN,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {}
}
