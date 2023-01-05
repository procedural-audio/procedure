use rand::{seq::IteratorRandom, Rng};
use pa_dsp::*;
use crate::*;

pub struct Arpeggiator {
    indicators: [Color; 16],
    velocities: [f32; 16],
    range_start: f32,
    range_end: f32,
    dropdowns: [u32; 4],
    knob_1: f32,
    knob_2: f32,
    knob_3: f32,
    beat: usize,
    callback: Callback,
    arp: Arp,
}

impl Module for Arpeggiator {
    type Voice = ();

    const INFO: Info = Info {
        title: "Arpeggiator",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(640, 290),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Midi Input", 20),
            Pin::Time("Time", 50)
        ],
        outputs: &[
            Pin::Notes("Midi Output", 20)
        ],
        path: "Category 1/Category 2/Module Name"
    };

    fn new() -> Self {
        Self {
            indicators: [Color::GREEN; 16],
            velocities: [0.5; 16],
            range_start: 0.0,
            range_end: 0.5,
            dropdowns: [0; 4],
            knob_1: 0.0,
            knob_2: 0.0,
            knob_3: 0.0,
            beat: 0,
            callback: Callback::new(),
            arp: Arp::new(),
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Stack {
            children: (
                // Feedback Indicator
                Transform {
                    position: (40, 40),
                    size: (35 * 16 as u32, 5),
                    child: Refresh {
                        callback: &mut self.callback,
                        child: GridBuilder {
                            columns: 16,
                            state: &mut self.indicators,
                            builder: |_index, color| {
                                return Padding {
                                    padding: (0, 0, 5, 0),
                                    child: Indicator { color },
                                };
                            },
                        },
                    },
                },
                // Velocity Faders
                Transform {
                    position: (40, 50),
                    size: (35 * 16 as u32, 120),
                    child: GridBuilder {
                        columns: 16,
                        state: &mut self.velocities,
                        builder: |_index, state| {
                            return Padding {
                                padding: (0, 0, 5, 0),
                                child: Fader {
                                    value: state,
                                    color: Color::GREEN,
                                },
                            };
                        },
                    },
                },
                // Range Slider
                Transform {
                    position: (20, 50 + 120 - 5),
                    size: (40 * 15, 40),
                    child: RangeSlider {
                        min: &mut self.range_start,
                        max: &mut self.range_end,
                        divisions: 16,
                        color: Color::GREEN,
                    },
                },
                // Dropdowns Row 1
                Transform {
                    position: (40, 205),
                    size: (120 * 2, 85),
                    child: GridBuilder {
                        columns: 2,
                        state: &mut self.dropdowns,
                        builder: |index, state| {
                            return Padding {
                                padding: (0, 0, 10, 10),
                                child: Dropdown {
                                    index: state,
                                    color: Color::GREEN,
                                    elements: if index == 0 {
                                        &[
                                            "As Played",
                                            "Chord",
                                            "Up",
                                            "Down",
                                            "Up > Down",
                                            "Down > Up",
                                            "Random",
                                        ] // Playback order
                                    } else if index == 1 {
                                        &["1/4", "1/4 t", "1/8", "1/8 t", "1/16", "1/16 t"]
                                    // Rate
                                    } else if index == 2 {
                                        &["1 Octave", "2 Octaves", "3 Octaves", "4 Octaves"]
                                    // Octaves
                                    } else if index == 3 {
                                        &["Unknown"]
                                    } else {
                                        panic!("Too many dropdowns in row");
                                    },
                                },
                            };
                        },
                    },
                },
                // Knobs
                Transform {
                    position: (400, 205),
                    size: (50, 70),
                    child: Knob {
                        text: "Length",
                        color: Color::GREEN,
                        value: &mut self.knob_1,
                        feedback: Box::new(|v| format!("{:.2}", v)),
                    },
                },
                Transform {
                    position: (400 + 70, 205),
                    size: (50, 70),
                    child: Knob {
                        text: "Jitter",
                        color: Color::GREEN,
                        value: &mut self.knob_2,
                        feedback: Box::new(|v| format!("{:.2}", v)),
                    },
                },
                Transform {
                    position: (400 + 70 * 2, 205),
                    size: (50, 70),
                    child: Knob {
                        text: "Unk",
                        color: Color::GREEN,
                        value: &mut self.knob_3,
                        feedback: Box::new(|v| format!("{:.2}", v)),
                    },
                },
            ),
        });
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        /* Arpeggiator Inputs */

        /*for event in &inputs.events[0] {
            match event {
                Event::NoteOn { note, offset: _ } => self.arp.note_on(*note),
                Event::NoteOff { id } => self.arp.note_off(*id),
                Event::Pitch { id, freq } => self.arp.note_pitch(*id, *freq),
                Event::Pressure { id, pressure } => self.arp.note_pressure(*id, *pressure),
                _ => (),
            }
        }*/

        /* Set Indicators */

        let rate: f64 = match self.dropdowns[1] {
            0 => 1.0,
            1 => 1.0 * 3.0 / 2.0,
            2 => 2.0,
            3 => 2.0 * 3.0 / 2.0,
            4 => 4.0,
            5 => 4.0 * 3.0 / 2.0,
            _ => panic!("Rate out of range"),
        };

        let min = (self.range_start * 16.0).round() as usize;
        let max = (self.range_end * 16.0).round() as usize;

        let mut beat = 0;

        if max == min {
            beat = min; // Freeze if they're equal
        } else {
            beat = (((inputs.time[0].start() * rate).round() as usize) % (max - min)) + min;
        }

        if self.beat != beat {
            self.beat = beat;

            for (index, color) in self.indicators.iter_mut().enumerate() {
                if index == beat {
                    *color = Color::PURPLE;
                } else {
                    *color = Color::GREEN;
                }
            }

            self.callback.trigger();

            /* Step arpeggiator */

            self.arp.set_mode(match self.dropdowns[0] {
                0 => ArpMode::AsPlayed,
                1 => ArpMode::Chord,
                2 => ArpMode::Up,
                3 => ArpMode::Down,
                4 => ArpMode::UpDown,
                5 => ArpMode::DownUp,
                6 => ArpMode::Random,
                _ => panic!("Invalid arp mode"),
            });

            self.arp.set_octaves(self.dropdowns[2] + 1);

            self.arp.set_step(beat);
        }

        /* Arpeggiator Outputs */

        /*for event in &mut outputs.events[0] {
            *event = match self.arp.gen() {
                Event::NoteOn { note, offset } => {
                    println!("Pressure is {}", self.velocities[beat]);
                    Event::NoteOn {
                        note: note.with_pressure(self.velocities[beat]),
                        offset,
                    }
                }
                e => e,
            }
        }*/
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
