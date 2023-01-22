use crate::*;

pub struct Scale {
    notes: (
        bool,
        bool,
        bool,
        bool,
        bool,
        bool,
        bool,
        bool,
        bool,
        bool,
        bool,
        bool,
    ),
}

impl Module for Scale {
    type Voice = ();

    const INFO: Info = Info {
        title: "Scale",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(300 - 35, 100),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Control("Control Input", 20)
        ],
        outputs: &[
            Pin::Control("Control Output", 20)
        ],
        path: "Category 1/Category 2/Module Name",
        presets: Presets::NONE
    };

        
    fn new() -> Self {
        Self {
            notes: (
                false, false, false, false, false, false, false, false, false, false, false, false,
            ),
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice { () }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Stack {
            children: (
                Stack {
                    children: (
                        Transform {
                            // C
                            position: (30 + 30 * 0, 60),
                            size: (25, 25),
                            child: SimpleButton {
                                text: "",
                                toggle: true,
                                color: Color::RED,
                                pressed: &mut self.notes.0,
                            },
                        },
                        Transform {
                            // C#
                            position: (45 + 30 * 0, 35),
                            size: (25, 25),
                            child: SimpleButton {
                                text: "",
                                toggle: true,
                                color: Color::RED,
                                pressed: &mut self.notes.1,
                            },
                        },
                        Transform {
                            // D
                            position: (30 + 30 * 1, 60),
                            size: (25, 25),
                            child: SimpleButton {
                                text: "",
                                toggle: true,
                                color: Color::RED,
                                pressed: &mut self.notes.2,
                            },
                        },
                        Transform {
                            // D#
                            position: (45 + 30 * 1, 35),
                            size: (25, 25),
                            child: SimpleButton {
                                text: "",
                                toggle: true,
                                color: Color::RED,
                                pressed: &mut self.notes.3,
                            },
                        },
                        Transform {
                            // E
                            position: (30 + 30 * 2, 60),
                            size: (25, 25),
                            child: SimpleButton {
                                text: "",
                                toggle: true,
                                color: Color::RED,
                                pressed: &mut self.notes.4,
                            },
                        },
                        Transform {
                            // F
                            position: (30 + 30 * 3, 60),
                            size: (25, 25),
                            child: SimpleButton {
                                text: "",
                                toggle: true,
                                color: Color::RED,
                                pressed: &mut self.notes.5,
                            },
                        },
                    ),
                },
                Stack {
                    children: (
                        Transform {
                            // F#
                            position: (45 + 30 * 3, 35),
                            size: (25, 25),
                            child: SimpleButton {
                                text: "",
                                toggle: true,
                                color: Color::RED,
                                pressed: &mut self.notes.6,
                            },
                        },
                        Transform {
                            // G
                            position: (30 + 30 * 4, 60),
                            size: (25, 25),
                            child: SimpleButton {
                                text: "",
                                toggle: true,
                                color: Color::RED,
                                pressed: &mut self.notes.7,
                            },
                        },
                        Transform {
                            // G#
                            position: (45 + 30 * 4, 35),
                            size: (25, 25),
                            child: SimpleButton {
                                text: "",
                                toggle: true,
                                color: Color::RED,
                                pressed: &mut self.notes.8,
                            },
                        },
                        Transform {
                            // A
                            position: (30 + 30 * 5, 60),
                            size: (25, 25),
                            child: SimpleButton {
                                text: "",
                                toggle: true,
                                color: Color::RED,
                                pressed: &mut self.notes.9,
                            },
                        },
                        Transform {
                            // A#
                            position: (45 + 30 * 5, 35),
                            size: (25, 25),
                            child: SimpleButton {
                                text: "",
                                toggle: true,
                                color: Color::RED,
                                pressed: &mut self.notes.10,
                            },
                        },
                        Transform {
                            // B
                            position: (30 + 30 * 6, 60),
                            size: (25, 25),
                            child: SimpleButton {
                                text: "",
                                toggle: true,
                                color: Color::RED,
                                pressed: &mut self.notes.11,
                            },
                        },
                    ),
                },
            ),
        });
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let value = inputs.control[0];
        outputs.control[0] = value;

        for i in 0..120 {
            match i % 12 {
                0 => {
                    if !self.notes.0 {
                        continue;
                    }
                }
                1 => {
                    if !self.notes.1 {
                        continue;
                    }
                }
                2 => {
                    if !self.notes.2 {
                        continue;
                    }
                }
                3 => {
                    if !self.notes.3 {
                        continue;
                    }
                }
                4 => {
                    if !self.notes.4 {
                        continue;
                    }
                }
                5 => {
                    if !self.notes.5 {
                        continue;
                    }
                }
                6 => {
                    if !self.notes.6 {
                        continue;
                    }
                }
                7 => {
                    if !self.notes.7 {
                        continue;
                    }
                }
                8 => {
                    if !self.notes.8 {
                        continue;
                    }
                }
                9 => {
                    if !self.notes.9 {
                        continue;
                    }
                }
                10 => {
                    if !self.notes.10 {
                        continue;
                    }
                }
                11 => {
                    if !self.notes.11 {
                        continue;
                    }
                }
                _ => (),
            }

            /*let next = Note::from_num(i);

            if next.pitch() > value {
                let prev = next.flat();

                let delta_1 = value - prev.pitch();
                let delta_2 = next.pitch() - value;

                if delta_1 < delta_2 {
                    outputs.control[0] = prev.pitch();
                } else {
                    outputs.control[0] = next.pitch();
                }

                break;
            }*/
        }

        println!(
            "{} -> {}",
            inputs.control[0],
            outputs.control[0]
        );
    }
}
