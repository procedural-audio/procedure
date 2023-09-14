use crate::*;
use pa_algorithms::*;

pub struct SineModule;

impl Module for SineModule {
    type Voice = PitchedPlayer<Sine<Stereo<f32>>>;

    const INFO: Info = Info {
        title: "Sin",
        id: "default.synthesis.sine",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[Pin::Notes("Notes", 15)],
        outputs: &[Pin::Audio("Audio Output", 15)],
        path: &["Audio", "Synthesis", "Sine"],
        presets: Presets::NONE
    };

    fn new() -> Self { Self }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        PitchedPlayer::from(Sine::new())
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 25),
            size: (40, 40),
            child: Icon {
                path: "waveforms/sine.svg",
                color: Color::BLUE,
            }
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.prepare(sample_rate, block_size);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        voice.process_block(&inputs.events[0], &mut outputs.audio[0]);

        for sample in outputs.audio[0].as_slice_mut() {
            sample.left *= 0.1;
            sample.right *= 0.1;
        }
    }
}
