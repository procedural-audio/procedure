use crate::*;

pub struct Noise {
    value: f32,
}

impl Module for Noise {
    type Voice = (); // NoiseProcessor;

    const INFO: Info = Info {
        title: Title("Noise", Color::BLUE),
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        inputs: &[Pin::Control("Noise Type", 25)],
        outputs: &[Pin::Audio("Audio Output", 25)],
    };

    
    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        // NoiseProcessor::new()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Type",
                color: Color::GREEN,
                value: &mut self.value,
                feedback: Box::new(|v| {
                    if v < 1.0 / 3.0 {
                        format!("Brown")
                    } else if v < 2.0 / 3.0 {
                        format!("Pink")
                    } else {
                        format!("White")
                    }
                }),
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        // voice.prepare(sample_rate, block_size);
    }

    fn process(&mut self, voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        // voice.set_param(0, self.value - 1.0);
        // voice.process(&[&[]], &mut outputs.audio[0].as_array_mut());
    }
}

/*faust!(NoiseProcessor,
    freq = hslider("freq[style:numerical]", -0.5, -1.0, 1.0, 0.001) : si.smoo;
    process = no.colored_noise(2, freq);
);*/