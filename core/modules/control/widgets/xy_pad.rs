use crate::*;

pub struct XYPadModule {
    x: f32,
    y: f32
}

impl Module for XYPadModule {
    type Voice = ();

    const INFO: Info = Info {
        title: "",
        id: "default.control.widgets.xy_pad",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(250 + 35, 250),
        voicing: Voicing::Polyphonic,
        inputs: &[],
        outputs: &[
            Pin::Control("X", 10),
            Pin::Control("Y", 35),
        ],
        path: &["Control", "Widgets", "XY Pad"],
        presets: Presets::NONE
    };
    
    fn new() -> Self {
        Self {
            x: 0.5,
            y: 0.5
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _version: &str, state: &State) {
        self.x = state.load("x");
        self.y = state.load("y");
    }

    fn save(&self, state: &mut State) {
        state.save("x", self.x);
        state.save("y", self.y);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(
            Padding {
                padding: (5, 5, 35, 5),
                child: XYPad {
                    x: &mut self.x,
                    y: &mut self.y
                }
            }
        )
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = self.x;
        outputs.control[1] = self.y;
    }
}
