use crate::*;


pub struct Crossover {
    value: f32,
}

impl Module for Crossover {
    type Voice = ();

    const INFO: Info = Info {
        title: "Crossover",
        id: "default.effects.spectral.crossover",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Input", 25),
            Pin::Control("Linear Crossover", 55),
        ],
        outputs: &[Pin::Audio("Audio High", 25), Pin::Audio("Audio Low", 55)],
        path: &["Audio", "Spectral", "Crossover"],
        presets: Presets::NONE
    };

    
    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Crossover",
                color: Color::GREEN,
                value: &mut self.value,
                feedback: Box::new(|_v| String::new()),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        outputs.audio[0].copy_from(&inputs.audio[0]);
    }
}

/*faust!(CrossoverDSP,
    freq = hslider("freq",0.5,0,1,0.001) : si.smoo;
    process = fi.crossover2LR4(freq);
);*/
