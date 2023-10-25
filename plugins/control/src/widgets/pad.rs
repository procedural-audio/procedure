use modules::*;

pub struct PadModule {
    value: bool,
}

impl Module for PadModule {
    type Voice = ();

    const INFO: Info = Info {
        title: "",
        id: "default.control.widgets.pad",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(100, 65),
        voicing: Voicing::Monophonic,
        inputs: &[],
        outputs: &[
            Pin::Control("Is Pressed", 25)
        ],
        path: &["Control", "Widgets", "Pad"]
    };
    
    fn new() -> Self {
        Self { value: false }
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
        Box::new(Padding {
            padding: (10, 10, 35, 10),
            child: Button {
                color: Color::rgb(50, 50, 50),
                on_pressed: | down | {
                    self.value = down;
                }
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = if self.value { 1.0 } else { 0.0 };
    }
}
