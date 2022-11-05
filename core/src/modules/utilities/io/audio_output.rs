use crate::modules::*;

pub struct AudioOutput;

impl Module for AudioOutput {
    type Voice = ();

    const INFO: Info = Info {
        name: "Audio Output",
                color: Color::BLUE,
        size: Size::Static(130, 80),
        voicing: Voicing::Monophonic,
        params: &[],
inputs: &[Pin::Audio("Audio Output", 30)],
        outputs: &[],
    };

    fn new() -> Self {
        Self
    }
    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }
    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (50, 30),
            size: (30, 30),
            child: Svg {
                path: "logos/audio.svg",
                color: Color::BLUE,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _vars: &Vars, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {}
}
