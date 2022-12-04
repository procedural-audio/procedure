use crate::*;

pub struct KnobModule {
    value: f32,
}

impl Module for KnobModule {
    type Voice = ();

    const INFO: Info = Info {
        title: Title("", Color::RED),
        size: Size::Static(100, 75),
        voicing: Voicing::Monophonic,
        inputs: &[],
        outputs: &[
            Pin::Control("Clock Output", 30)
        ],
    };
    
    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (10, 10),
            size: (60, 60),
            child: Knob {
                text: "",
                color: Color::RED,
                value: &mut self.value,
                feedback: Box::new(|_| String::new()),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = self.value;
    }
}