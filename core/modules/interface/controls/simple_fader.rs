use crate::*;

pub struct SimpleFaderModule {
    value: f32,
}

impl Module for SimpleFaderModule {
    type Voice = ();

    const INFO: Info = Info {
        title: "Simple Fader",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        inputs: &[],
        outputs: &[Pin::Control("Control Output", 30)],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Svg {
                path: "operations/add.svg",
                color: Color::RED,
            },
        })
    }

    fn build_ui<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(SimpleFader {
            text: "Gain",
            color: Color::GREEN,
            value: 0.0,
            control: &0.0,
            on_changed: Box::new(|mut v| {
                if v > 1.0 {
                    v = 1.0;
                } else if v < 0.0 {
                    v = 0.0;
                }

                self.value = v;
            }),
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = self.value;
    }
}
