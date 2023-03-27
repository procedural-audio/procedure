use crate::*;

pub struct Counter;

pub struct CounterVoice {
    last_value: f32,
    last_reset: f32,
    count: u32
}

impl Module for Counter {
    type Voice = CounterVoice;

    const INFO: Info = Info {
        title: "Count",
        id: "default.control.effects.count",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Control Input", 15),
            Pin::Control("Reset", 45),
        ],
        outputs: &[
            Pin::Control("Control Output", 30)
        ],
        path: &["Control", "Effects", "Counter"],
        presets: Presets::NONE
    };

    fn new() -> Self { Self }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            last_value: 0.0,
            last_reset: 0.0,
            count: 0
        }
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 25),
            size: (40, 40),
            child: Icon {
                path: "waveforms/square.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let reset = inputs.control[1];
        if reset >= 0.5 && voice.last_reset < 0.5 {
            voice.count = 0;
        }

        voice.last_reset = reset;

        let value = inputs.control[0];
        if value >= 0.5 && voice.last_value < 0.5 {
            voice.count += 1;
        }

        voice.last_value = value;

        outputs.control[0] = voice.count as f32;
    }
}
