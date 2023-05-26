use crate::*;

pub struct SpectralTilt {
    value: f32,
}

impl Module for SpectralTilt {
    type Voice = ();

    const INFO: Info = Info {
        title: "Crossover",
        id: "default.effects.spectral.crossover",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 25),
            Pin::Control("Crossover (0-1)", 55),
        ],
        outputs: &[
            Pin::Audio("Audio High", 25),
            Pin::Audio("Audio Low", 55)
        ],
        path: &["Audio", "Spectral", "Crossover"],
        presets: Presets::NONE
    };
    
    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
		()
    }

    fn load(&mut self, _version: &str, _state: &State) {

    }

    fn save(&self, _state: &mut State) {

    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Crossover",
                color: Color::BLUE,
                value: &mut self.value,
                feedback: Box::new(| v| {
                    format!("{:.2} hz", v * 10000.0)
                }),
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, _block_size: usize) {
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
    }
}

/*
import("stdfaust.lib");
freq = hslider("freq", 0.5, 0, 1, 0.0001);
process = _ : fi.crossover2LR4(freq) : si.bus(2);
*/
