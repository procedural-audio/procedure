use modules::*;

pub struct Monophonic {
    msgs: Vec<NoteMessage>,
    playing: Option<Id>
}

pub struct MonophonicVoice {
    index: u32
}

impl Module for Monophonic {
    type Voice = MonophonicVoice;

    const INFO: Info = Info {
        title: "Mono",
        id: "default.sequencing.monophonic",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Input", 30),
        ],
        outputs: &[
            Pin::Notes("Output", 30)
        ],
        path: &["Notes", "Effects", "Monophonic"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            msgs: Vec::with_capacity(32),
            playing: None
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice {
            index
        }
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 20),
            size: (40, 40),
            child: Icon {
                path: "comparisons/equal.svg",
                color: Color::GREEN,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            self.msgs.push(*msg);
        }

        if voice.index == 0 {
            for msg in &self.msgs {
                match msg.note {
                    Event::NoteOn { pitch: _, pressure: _ } => {
                        self.playing = Some(msg.id);
                        outputs.events[0].push(*msg);
                    },
                    Event::NoteOff => {
                        if let Some(id) = self.playing {
                            if id == msg.id {
                                self.playing = None;
                                outputs.events[0].push(*msg);
                            }
                        }
                    },
                    _ => {
                        if let Some(id) = self.playing {
                            if id == msg.id {
                                outputs.events[0].push(*msg);
                            }
                        }
                    }
                }
            }

            self.msgs.clear();
        }
    }
}
