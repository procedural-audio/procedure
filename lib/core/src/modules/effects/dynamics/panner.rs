use crate::modules::*;
use metasampler_macros::*;

pub struct Panner {
    value: f32,
}

impl Module for Panner {
    type Voice = PannerDSP;

    const INFO: Info = Info {
        name: "Panner",
        features: &[],
        color: Color::BLUE,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        vars: &[],
inputs: &[
            Pin::Audio("Audio Input", 25),
            Pin::Control("Pan Amount", 55),
        ],
        outputs: &[Pin::Audio("Audio Output", 25)],
    };

    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        PannerDSP::new()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Pan",
                color: Color::BLUE,
                value: &mut self.value,
                feedback: Box::new(|_v| String::new()),
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.prepare(sample_rate, block_size)
    }

    fn process(&mut self, _vars: &Vars, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        voice.set_param(0, self.value);

        voice.process(
            &inputs.audio[0].as_array(),
            &mut outputs.audio[0].as_array_mut(),
        );
    }
}

faust!(PannerDSP,
    pan = hslider("value", 0.5, 0, 1, 0.0001) : si.smoo;
    process = sp.panner(pan);
);
