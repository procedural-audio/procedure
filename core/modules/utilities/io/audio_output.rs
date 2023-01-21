use crate::*;

pub struct AudioOutput;

impl Module for AudioOutput {
    type Voice = ();

    const INFO: Info = Info {
        title: "",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(85, 60),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Output", 22)
        ],
        outputs: &[
            Pin::ExternalAudio(0)
        ],
        path: "Category 1/Category 2/Module Name"
    };

    fn new() -> Self {
        Self
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (40, 15),
            size: (30, 30),
            child: Svg {
                path: "logos/audio.svg",
                color: Color::BLUE,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        outputs.audio[0].copy_from(&inputs.audio[0]);
    }
}
