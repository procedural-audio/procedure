use modules::*;
use modules::widget::Key;

pub struct Chords {
    keys: [Key; 88],
    keys2: [Key; 12]
}

impl Chords {
    fn quantize(&self, pitch: f32) -> f32 {
        let num = pitch_to_num(pitch);
        let mut quantized = num;
        let mut delta = 127;

        for n in 0..127 {
            let k = n as usize % 12;
            if self.keys[k].down {
                let diff = u32::abs_diff(num, n);
                if diff < delta {
                    quantized = n;
                    delta = diff;
                }
            }
        }

        num_to_pitch(quantized)
    }
}

impl Module for Chords {
    type Voice = ();

    const INFO: Info = Info {
        title: "Chords",
        id: "default.sequencing.chords",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(185, 200),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 10),
        ],
        outputs: &[
            Pin::Notes("Notes Output", 10)
        ],
        path: &["Notes", "Effects", "Chords"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            keys: [
                Key { down: false }; 88
            ],
            keys2: [
                Key { down: false }; 12
            ]
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice { () }
    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Padding {
            padding: (5, 35, 5, 5),
            child: Column {
                children: (
                    widget::Keyboard {
                        keys: &mut self.keys,
                        on_event: | event, keys | {
                            match event {
                                KeyEvent::Press(i) => {
                                    keys[i].down = !keys[i].down;
                                },
                                KeyEvent::Release(_) => {},
                            }
                        }
                    },
                    widget::Keyboard {
                        keys: &mut self.keys2,
                        on_event: | event, keys | {
                            match event {
                                KeyEvent::Press(i) => {
                                    keys[i].down = !keys[i].down;
                                },
                                KeyEvent::Release(_) => {},
                            }
                        }
                    }
                )
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure } => {
                    outputs.events[0].push(
                        NoteMessage {
                            id: msg.id,
                            offset: msg.offset,
                            note: Event::NoteOn {
                                pitch: self.quantize(pitch),
                                pressure
                            }
                        }
                    );
                },
                Event::Pitch(pitch) => {
                    outputs.events[0].push(
                        NoteMessage {
                            id: msg.id,
                            offset: msg.offset,
                            note: Event::Pitch(self.quantize(pitch))
                        }
                    );
                },
                _ => outputs.events[0].push(*msg)
            }
        }
    }
}
