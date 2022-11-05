use crate::modules::*;

pub struct Display {
    rate: f32,
    updated: bool,
}

impl Module for Display {
    type Voice = u32;

    const INFO: Info = Info {
        name: "",
                color: Color::RED,
        size: Size::Static(115, 50),
        voicing: Voicing::Polyphonic,
        params: &[],
        inputs: &[
            Pin::Control("Input", 17)
        ],
        outputs: &[],
    };

    fn new() -> Self {
        Self {
            rate: 0.0,
            updated: true,
        }
    }

    fn new_voice(index: u32) -> Self::Voice {
        index
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 10),
            size: (70, 30),
            child: tonevision_types::Display {
                text: || {
                    if self.updated {
                        self.updated = false;
                        Some(format!("{:.1}", self.rate))
                    } else {
                        None
                    }
                },
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _vars: &Vars, voice: &mut Self::Voice, inputs: &IO, _outputs: &mut IO) {
        if *voice == 0 {
            let input = inputs.control[0].get();

            if self.rate != input {
                self.rate = input;
                self.updated = true;
            }
        }
    }
}
