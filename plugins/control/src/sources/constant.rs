use modules::*;

pub struct Constant {
    value: f32,
}

impl Module for Constant {
    type Voice = ();

    const INFO: Info = Info {
        title: "",
        id: "default.control.operations.constant",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(115, 50),
        voicing: Voicing::Monophonic,
        inputs: &[],
        outputs: &[
            Pin::Control("Control Output", 17)
        ],
        path: &["Control", "Sources", "Constant"],
        presets: Presets::NONE
    };
    
    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, version: &str, state: &State) {
        self.value = state.load("value");
    }

    fn save(&self, state: &mut State) {
        state.save("value", self.value);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (10, 10),
            size: (70, 30),
            child: Input {
                value: &mut self.value,
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = self.value;
    }
}
