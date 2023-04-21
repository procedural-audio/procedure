use std::cmp::Ordering;
use rand::{seq::SliceRandom, rngs::ThreadRng};

use pa_dsp::*;
use modules::*;

pub struct Arpeggiator {
    mode: usize,
    notes: Vec<Note>,
    ordered: Vec<Note>,
    rng: ThreadRng
}

pub struct ArpeggiatorVoice {
    playing: Vec<Id>,
    index: u32
}

impl Module for Arpeggiator {
    type Voice = ArpeggiatorVoice;

    const INFO: Info = Info {
        title: "Arpeggiator",
        id: "default.sequencing.arpeggiator",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(190, 80),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Midi Input", 10),
            Pin::Time("Time", 35)
        ],
        outputs: &[
            Pin::Notes("Midi Output", 10)
        ],
        path: &["Notes", "Generative", "Arpeggiator"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            mode: 0,
            notes: Vec::with_capacity(32),
            ordered: Vec::with_capacity(32),
            rng: rand::thread_rng()
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice {
            playing: Vec::with_capacity(8),
            index
        }
    }

    fn load(&mut self, _version: &str, state: &State) {
        self.mode = state.load("mode");
    }

    fn save(&self, state: &mut State) {
        state.save("mode", self.mode);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(
            Stack {
                children: (
                    Transform {
                        position: (35, 35),
                        size: (120, 35),
                        child: Dropdown {
                            index: &mut self.mode,
                            color: Color::GREEN,
                            elements: &[
                                "As Played",
                                "Chord",
                                "Up",
                                "Down",
                                "Up > Down",
                                "Up > Down+",
                                "Down > Up",
                                "Down > Up+",
                                "Random"
                            ]
                        }
                    }
                )
            }
        );
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure } => {
                    self.notes.push(
                        Note {
                            id: msg.id,
                            pitch,
                            pressure
                        }
                    );
                },
                Event::NoteOff => {
                    self.notes.retain(
                        | note | {
                            note.id != msg.id
                        }
                    );
                },
                Event::Pitch(pitch) => {
                    for note in &mut self.notes {
                        if note.id == msg.id {
                            note.pitch = pitch;
                        }
                    }
                },
                Event::Pressure(pressure) => {
                    for note in &mut self.notes {
                        if note.id == msg.id {
                            note.pressure = pressure;
                        }
                    }
                }
                _ => ()
            }
        }

        inputs.time[0].on_each(1.0, | beat | {
            for id in &voice.playing {
                outputs.events[0].push(
                    NoteMessage {
                        id: *id,
                        offset: 0,
                        note: Event::NoteOff
                    }
                );
            }

            if voice.index == 0 {
                self.ordered.clear();
                for n in &self.notes {
                    self.ordered.push(*n);
                }

                if self.mode == 0 {
                    // Don't reorder
                } else if self.mode == 1 {
                    // Don't reorder
                } else if self.mode == 2 {
                    self.ordered.sort_by(| a, b | {
                        if a.pitch <= b.pitch {
                            Ordering::Less
                        } else {
                            Ordering::Greater
                        }
                    });
                } else if self.mode == 3 {
                    self.ordered.sort_by(| a, b | {
                        if a.pitch <= b.pitch {
                            Ordering::Greater
                        } else {
                            Ordering::Less
                        }
                    });
                } else if self.mode == 4 {
                    self.ordered.sort_by(| a, b | {
                        if a.pitch <= b.pitch {
                            Ordering::Less
                        } else {
                            Ordering::Greater
                        }
                    });

                    let l = self.ordered.len();
                    if l >= 3 {
                        for i in 1..(l-1) {
                            self.ordered.push(self.ordered[l - i - 1]);
                        }
                    }
                } else if self.mode == 5 {
                    self.ordered.sort_by(| a, b | {
                        if a.pitch <= b.pitch {
                            Ordering::Less
                        } else {
                            Ordering::Greater
                        }
                    });

                    let l = self.ordered.len();
                    for i in 0..l {
                        self.ordered.push(self.ordered[l - i - 1]);
                    }
                } else if self.mode == 6 {
                    self.ordered.sort_by(| a, b | {
                        if a.pitch <= b.pitch {
                            Ordering::Greater
                        } else {
                            Ordering::Less
                        }
                    });

                    let l = self.ordered.len();
                    if l >= 3 {
                        for i in 1..(l-1) {
                            self.ordered.push(self.ordered[l - i - 1]);
                        }
                    }
                } else if self.mode == 7 {
                    self.ordered.sort_by(| a, b | {
                        if a.pitch <= b.pitch {
                            Ordering::Greater
                        } else {
                            Ordering::Less
                        }
                    });

                    let l = self.ordered.len();
                    for i in 0..l {
                        self.ordered.push(self.ordered[l - i - 1]);
                    }
                } else if self.mode == 8 {
                    self.ordered.shuffle(&mut self.rng);
                } else {
                    panic!("Unknown dropdown index");
                }
            }

            if self.ordered.len() > 0 {
                if self.mode != 1 {
                    if voice.index == 0 {
                        let note = self.ordered[beat % self.ordered.len()];
                        let id = Id::new();
                        voice.playing.push(id);

                        outputs.events[0].push(
                            NoteMessage {
                                id,
                                offset: 0,
                                note: Event::NoteOn {
                                    pitch: note.pitch,
                                    pressure: note.pressure
                                }
                            }
                        );
                    }
                } else {
                    if (voice.index as usize) < self.ordered.len() {
                        let note = self.ordered[voice.index as usize];
                        let id = Id::new();
                        voice.playing.push(id);

                        outputs.events[0].push(
                            NoteMessage {
                                id,
                                offset: 0,
                                note: Event::NoteOn {
                                    pitch: note.pitch,
                                    pressure: note.pressure
                                }
                            }
                        );
                    }
                }
            }
        });
    }
}
