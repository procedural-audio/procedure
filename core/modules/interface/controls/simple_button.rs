use crate::*;

pub struct SimpleButtonModule {
    value: bool,
}

impl Module for SimpleButtonModule {
    type Voice = ();

    const INFO: Info = Info {
        title: "Simple Button",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        inputs: &[],
        outputs: &[Pin::Control("Control Output", 30)],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        Self { value: false }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Svg {
                path: "operations/add.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        if self.value {
            outputs.control[0] = 1.0;
        } else {
            outputs.control[0] = 0.0;
        }
    }
}
