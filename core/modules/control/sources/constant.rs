use crate::*;

pub struct Constant {
    value: f32,
}

impl Module for Constant {
    type Voice = ();

    const INFO: Info = Info {
        name: "",
        color: Color::RED,
        size: Size::Static(115, 50),
        voicing: Voicing::Monophonic,
        inputs: &[],
        outputs: &[
            Pin::Control("Control Output", 17)
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
            size: (70, 30),
            child: Input {
                value: 0.0,
                on_changed: | s | {
                    match f32::from_str(s) {
                        Ok(v) => {
                            self.value = v;

                            Ok(v)
                        },
                        Err(_) => {
                            self.value = 0.0;

                            Err(String::from("Not a float"))
                        }
                    }
                }
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = self.value;
    }
}