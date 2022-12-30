use crate::*;

pub struct Keyboard {
    keys: [Key; 88]
}

impl Module for Keyboard {
    type Voice = ();

    const INFO: Info = Info {
        title: "Keyboard",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Reisizable {
            default: (400, 100),
            min: (200, 100),
            max: (800, 200)
        },
        voicing: Voicing::Polyphonic,
        inputs: &[],
        outputs: &[
            Pin::Notes("Notes Output", 10)
        ],
        path: "Category 1/Category 2/Module Name"
    };
    
    fn new() -> Self {
        Self {
            keys: [
                Key { down: false }; 88
            ]
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(
            Padding {
                padding: (10, 35, 10, 10),
                child: widget::Keyboard {
                    keys: &mut self.keys,
                    on_event: | event, keys | {
                        match event {
                            KeyEvent::KeyPress(i) => {
                                keys[i].down = true;
                            },
                            KeyEvent::KeyRelease(i) => {
                                keys[i].down = false;
                            }
                        }
                    }
                }
            }
        )
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        
    }
}