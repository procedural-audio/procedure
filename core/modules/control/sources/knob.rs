use crate::*;

pub struct KnobModule {
    value: f32,
}

impl Module for KnobModule {
    type Voice = ();

    const INFO: Info = Info {
        title: "",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(100, 75),
        voicing: Voicing::Monophonic,
        inputs: &[],
        outputs: &[
            Pin::Control("Clock Output", 30)
        ],
        path: "Control/Sources/Knob",
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
