use crate::modules::*;

pub struct AudioInput;

impl Module for AudioInput {
    type Voice = ();

    const INFO: Info = Info {
        name: "Audio Input",
        features: &[],
        color: Color::BLUE,
        size: Size::Static(100, 100),
        voicing: Voicing::Monophonic,
        vars: &[],
        inputs: &[
            Pin::AudioInput(0)
        ],
        outputs: &[
            Pin::Audio("External Audio 1", 20)
        ],
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
            position: (30, 20),
            size: (40, 40),
            child: Svg {
                path: "logos/audio.svg",
                color: Color::BLUE,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _vars: &Vars, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        outputs.audio[0].copy_from(&inputs.audio[0]);

    }
}
