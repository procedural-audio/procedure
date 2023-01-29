use crate::*;

pub struct Mute {
    muted: bool,
}

impl Module for Mute {
    type Voice = ();

    const INFO: Info = Info {
        title: "Mute",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(100, 80),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Input", 25)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 25)
        ],
        path: "Audio Effects/Dynamics/Mute",
        presets: Presets::NONE
    };

    
    fn new() -> Self {
        Self { muted: false }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 30),
            size: (40, 40),
            child: SvgButton {
                path: "speaker.svg",
                color: Color::BLUE,
                pressed: false,
                on_changed: Box::new(|v| {
                    self.muted = v;
                }),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if !self.muted {
            outputs.audio[0].copy_from(&inputs.audio[0]);
        }
    }
}
