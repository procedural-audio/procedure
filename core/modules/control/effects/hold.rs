use crate::*;

pub struct Hold {
    hold: bool,
    value: f32,
}

impl Module for Hold {
    type Voice = ();

    const INFO: Info = Info {
        name: "Hold",
        color: Color::RED,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Input", 15),
            Pin::Control("Hold (boolean)", 45),
        ],
        outputs: &[
            Pin::Control("Output", 30)
        ],
    };

        
    fn new() -> Self {
        Hold {
            hold: false,
            value: 0.0,
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }
    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 32),
            size: (30, 30),
            child: Svg {
                path: "hold.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let value = inputs.control[0];

        if self.hold {
            if inputs.control[1] < 0.5 {
                outputs.control[0] = value;
                self.hold = false;
            } else {
                outputs.control[0] = self.value;
            }
        } else {
            if inputs.control[1] < 0.5 {
                outputs.control[0] = value;
            } else {
                self.hold = true;
                self.value = value;
                outputs.control[0] = value;
            }
        }
    }
}