use std::cmp::Ordering;

use rand::{seq::IteratorRandom, Rng};
use pa_dsp::*;
use crate::*;

pub struct Arpeggiator {
    mode: usize,
    notes: Vec<Note>
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
        size: Size::Static(200, 100),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Midi Input", 20),
            Pin::Time("Time", 50)
        ],
        outputs: &[
            Pin::Notes("Midi Output", 20)
        ],
        path: &["Notes", "Sources", "Arpeggiator"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            mode: 0,
            notes: Vec::with_capacity(32)
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice {
            playing: Vec::with_capacity(8),
            index
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(
            Stack {
                children: (
                    Transform {
                        position: (35, 40),
                        size: (130, 40),
                        child: Dropdown {
                            index: &mut self.mode,
                            color: Color::GREEN,
                            elements: &[
                                "As Played",
                                "Chord",
                                "Up",
                                "Down",
                                "Up > Down",
                                "Down > Up",
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

            self.notes.sort_by(| a, b | {
                if self.mode == 0 {
                    Ordering::Less
                } else if self.mode == 1 || self.mode == 2 {
                    if a.pitch <= b.pitch {
                        Ordering::Less
                    } else {
                        Ordering::Greater
                    }
                } else if self.mode == 3 {
                    if a.pitch <= b.pitch {
                        Ordering::Greater
                    } else {
                        Ordering::Less
                    }
                // } else if self.mode == 4 {
                // } else if self.mode == 5 {
                // } else if self.mode == 6 {
                } else {
                    Ordering::Less
                }
            });

            if self.notes.len() > 0 {
                if voice.index == 0 {
                    println!("Beat {}", beat);

                    let note = self.notes[beat % self.notes.len()];
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
                } else if self.mode == 1 {
                    if beat < self.notes.len() {
                        let note = self.notes[beat];
                        let id = Id::new();
                        voice.playing.push(id);

                        outputs.events[0].push(
                            NoteMessage {
                                id: Id::new(),
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

pub enum ArpMode {
    Chord,
    AsPlayed,
    Up,
    Down,
    UpDown,
    DownUp,
    Random,
}

pub struct Arp {
    inputs: Vec<NoteMessage>,
    outputs: Vec<NoteMessage>,
    queue: Vec<Event>,
    mode: ArpMode,
    octaves: u32,
    rand: rand::rngs::ThreadRng,
}

impl Arp {
    pub fn new() -> Self {
        Self {
            inputs: Vec::with_capacity(64),
            outputs: Vec::with_capacity(64),
            queue: Vec::with_capacity(64),
            mode: ArpMode::AsPlayed,
            octaves: 1,
            rand: rand::thread_rng(),
        }
    }

    pub fn note_on(&mut self, pitch: f32, pressure: f32) {
        // self.inputs.push(note);
    }

    pub fn note_off(&mut self, id: Id) {
        self.inputs.retain(|n| n.id != id)
    }

    pub fn note_pitch(&mut self, id: Id, pitch: f32) {
        for note in &mut self.inputs {
            if note.id == id {
                // note.pitch = pitch;
            }
        }
    }

    pub fn note_pressure(&mut self, id: Id, pressure: f32) {
        for note in &mut self.inputs {
            if note.id == id {
                // note.pressure = pressure;
            }
        }
    }

    pub fn set_mode(&mut self, mode: ArpMode) {
        self.mode = mode;
    }

    pub fn set_octaves(&mut self, octaves: u32) {
        self.octaves = octaves;
    }

    /// Step the arpeggiator state. Fill the queue.
    pub fn set_step(&mut self, num: usize) {
        /*use std::cmp::Ordering;

        self.queue.clear();

        let mut notes = [NoteMessage::from_num(0); 16];
        let mut count = 0;

        for octave in 1..(self.octaves + 1) {
            for note in &self.inputs {
                notes[count] = note.with_pitch(note.pitch * f32::powi(2.0, octave as i32));
                count += 1;
            }
        }

        let notes = &mut notes[0..count];

        match self.mode {
            ArpMode::Chord => {
                for note in notes {
                    self.queue.push(Event::NoteOn {
                        note: *note,
                        offset: 0,
                    })
                }
            }
            ArpMode::AsPlayed => match notes.iter().cycle().skip(num).next() {
                Some(note) => self.queue.push(Event::NoteOn {
                    note: *note,
                    offset: 0,
                }),
                None => (),
            },
            ArpMode::Up => {
                notes.sort_by(|a, b| {
                    if a.pitch < b.pitch {
                        Ordering::Less
                    } else if b.pitch > a.pitch {
                        Ordering::Greater
                    } else {
                        Ordering::Equal
                    }
                });

                match notes.iter().cycle().skip(num).next() {
                    Some(note) => self.queue.push(Event::NoteOn {
                        note: *note,
                        offset: 0,
                    }),
                    None => (),
                }
            }
            ArpMode::Down => {
                notes.sort_by(|a, b| {
                    if a.pitch > b.pitch {
                        Ordering::Less
                    } else if b.pitch < a.pitch {
                        Ordering::Greater
                    } else {
                        Ordering::Equal
                    }
                });

                match notes.iter().cycle().skip(num).next() {
                    Some(note) => self.queue.push(Event::NoteOn {
                        note: *note,
                        offset: 0,
                    }),
                    None => (),
                }
            }
            ArpMode::UpDown => {
                notes.sort_by(|a, b| {
                    if a.pitch < b.pitch {
                        Ordering::Less
                    } else if b.pitch > a.pitch {
                        Ordering::Greater
                    } else {
                        Ordering::Equal
                    }
                });

                match notes
                    .iter()
                    .chain(notes.iter().rev())
                    .cycle()
                    .skip(num)
                    .next()
                {
                    Some(note) => self.queue.push(Event::NoteOn {
                        note: *note,
                        offset: 0,
                    }),
                    None => (),
                }
            }
            ArpMode::DownUp => {
                notes.sort_by(|a, b| {
                    if a.pitch > b.pitch {
                        Ordering::Less
                    } else if b.pitch < a.pitch {
                        Ordering::Greater
                    } else {
                        Ordering::Equal
                    }
                });

                match notes
                    .iter()
                    .chain(notes.iter().rev())
                    .cycle()
                    .skip(num)
                    .next()
                {
                    Some(note) => self.queue.push(Event::NoteOn {
                        note: *note,
                        offset: 0,
                    }),
                    None => (),
                }
            }
            ArpMode::Random => match notes.iter().choose(&mut self.rand) {
                Some(note) => self.queue.push(Event::NoteOn {
                    note: *note,
                    offset: 0,
                }),
                None => (),
            },
        }*/
    }
}

impl Generator for Arp {
    type Item = Event;

    fn reset(&mut self) {
        self.inputs.clear();
        self.queue.clear();

        for note in &self.outputs {
            // self.queue.push(Event::NoteOff { id: note.id });
        }

        self.outputs.clear();
    }

    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn gen(&mut self) -> Self::Item {
        panic!("Not implemented");
        /*let event = self.queue.pop();

        match event {
            Some(event) => match event {
                Event::NoteOn { note, offset: _ } => {
                    self.outputs.push(note);
                    return event;
                }
                Event::NoteOff { id } => {
                    self.outputs.retain(|n| n.id != id);

                    return event;
                }
                _ => event,
            },
            None => Event::None,
        }*/
    }
}
