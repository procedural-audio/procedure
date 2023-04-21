use modules::*;
use modules::widget::Key;

pub struct Split {
    keys: [Key; 88],
    split_index: usize
}

impl Module for Split {
    type Voice = u32;

    const INFO: Info = Info {
        title: "Split",
        id: "default.sequencing.split",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Reisizable {
            default: (600, 120),
            min: (200, 110),
            max: (1200, 110)
        },
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 10),
        ],
        outputs: &[
            Pin::Notes("Notes High", 10),
            Pin::Notes("Notes Low", 35)
        ],
        path: &["Notes", "Effects", "Split"],
        presets: Presets::NONE
    };
    
    fn new() -> Self {
        Self {
            keys: [
                Key { down: false }; 88
            ],
            split_index: 0
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice { index }
    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(
            Padding {
                padding: (10, 35, 10, 10),
                child: widget::Keyboard {
                    keys: &mut self.keys,
                    on_event: | event, keys | {
                        match event {
                            KeyEvent::Press(i) => {
                                self.split_index = i;
                                for key in keys.iter_mut().enumerate() {
                                    if key.0 < self.split_index {
                                        key.1.down = true;
                                    } else {
                                        key.1.down = false;
                                    }
                                }
                            },
                            KeyEvent::Release(_) => ()
                        }
                    }
                }
            }
        )
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure: _ } => {
                    if (pitch_to_num(pitch) as usize) < self.split_index {
                        outputs.events[1].push(*msg);
                    } else {
                        outputs.events[0].push(*msg);
                    }
                },
                _ => {
                    outputs.events[0].push(*msg);
                    outputs.events[1].push(*msg);
                }
            }
        }
    }
}
