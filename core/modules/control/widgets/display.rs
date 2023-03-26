use crate::*;

pub struct Display {
    value: f32,
    updated: bool,
}

impl Module for Display {
    type Voice = u32;

    const INFO: Info = Info {
        title: "",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(115, 50),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Input", 17)
        ],
        outputs: &[],
        path: &["Control", "Widgets", "Display"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            value: 0.0,
            updated: true
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        index
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 10),
            size: (70, 30),
            child: widget::Display {
                text: || {
                    if self.updated {
                        self.updated = false;
                        Some(format!("{:.2}", self.value))
                    } else {
                        None
                    }
                },
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, _outputs: &mut IO) {
        if *voice == 0 {
            let input = inputs.control[0];

            if self.value != input {
                self.value = input;
                self.updated = true;
            }
        }
    }
}
