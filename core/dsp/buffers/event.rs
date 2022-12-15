use lazy_static::lazy_static;

use crate::Time;

const NOTE_NAMES: [&'static str; 120] = [
    "C0", "C#0", "D0", "D#0", "E0", "F0", "F#0", "G0", "G#0", "A0", "A#0", "B0", "C1", "C#1", "D1",
    "D#1", "E1", "F1", "F#1", "G1", "G#1", "A1", "A#1", "B1", "C2", "C#2", "D2", "D#2", "E2", "F2",
    "F#2", "G2", "G#2", "A2", "A#2", "B2", "C3", "C#3", "D3", "D#3", "E3", "F3", "F#3", "G3",
    "G#3", "A3", "A#3", "B3", "C4", "C#4", "D4", "D#4", "E4", "F4", "F#4", "G4", "G#4", "A4",
    "A#4", "B4", "C5", "C#5", "D5", "D#5", "E5", "F5", "F#5", "G5", "G#5", "A5", "A#5", "B5", "C6",
    "C#6", "D6", "D#6", "E6", "F6", "F#6", "G6", "G#6", "A6", "A#6", "B6", "C7", "C#7", "D7",
    "D#7", "E7", "F7", "F#7", "G7", "G#7", "A7", "A#7", "B7", "C8", "C#8", "D8", "D#8", "E8", "F8",
    "F#8", "G8", "G#8", "A8", "A#8", "B8", "C9", "C#9", "D9", "D#9", "E9", "F9", "F#9", "G9",
    "G#9", "A9", "A#9", "B9",
];

// Size is 20 bytes

use std::sync::{Arc, Mutex};

lazy_static!(
    static ref LAST_ID: Arc<Mutex<u64>> = Arc::new(Mutex::new(0));
);

#[repr(transparent)]
#[derive(Copy, Clone, PartialEq)]
pub struct Id(u64);

impl Id {
    pub fn new() -> Self {
        let mut last_id = LAST_ID.lock().unwrap();
        *last_id = *last_id + 1;
        return Id(*last_id);
    }
}


#[derive(Copy, Clone, PartialEq)]
#[repr(C, u32)]
pub enum Event {
    NoteOn { note: Note, offset: u16 },
    NoteOff { id: Id },
    Pitch { id: Id, freq: f32 },
    Pressure { id: Id, pressure: f32 },
    Controller { id: Id, value: f32 },
    ProgramChange { id: Id, value: u8 },
    None,
}

#[derive(Copy, Clone, PartialEq)]
#[repr(C)]
pub struct Note {
    pub id: Id,
    pub pitch: f32,
    pub pressure: f32,
}

#[derive(Copy, Clone)]
pub struct NoteMessage {
    pub offset: usize,
    pub note: Note
}

#[derive(Copy, Clone)]
pub struct NoteEvent {
    pub time: Time,
    pub note: Event
}

impl Note {
    pub fn from_pitch(hz: f32) -> Self {
        Self {
            id: Id::new(),
            pitch: hz,
            pressure: 0.5,
        }
    }

    pub fn with_pitch(mut self, hz: f32) -> Self {
        self.pitch = hz;
        self
    }

    pub fn with_pressure(mut self, pressure: f32) -> Self {
        self.pressure = pressure;
        self
    }

    pub fn from_num(num: u32) -> Self {
        let hz = 440.0 * 2.0_f32.powf((num as f32 - 69.0) / 12.0);

        Self {
            id: Id::new(),
            pitch: hz,
            pressure: 0.5,
        }
    }

    pub fn from_name(name: &str) -> Option<Self> {
        let mut i = 12;
        for n in NOTE_NAMES {
            if n == name {
                return Some(Note::from_num(i));
            }

            i += 1;
        }

        return None;
    }

    pub fn pitch(&self) -> f32 {
        self.pitch
    }

    pub fn num(&self) -> u32 {
        (f32::round(f32::log2(self.pitch / 440.0) * 12.0) + 69.0) as u32
    }

    pub fn name(&self) -> &'static str {
        let index = (self.num() - 12) as usize;

        if index > 0 && index < NOTE_NAMES.len() {
            return NOTE_NAMES[index];
        } else {
            return "Unknown";
        }
    }

    pub fn pressure(&self) -> f32 {
        self.pressure
    }

    pub fn sharp(&self) -> Note {
        Note::from_num(self.num() + 1)
    }

    pub fn flat(&self) -> Note {
        Note::from_num(self.num() - 1)
    }

    pub fn transpose(&self, steps: i32) -> Note {
        Note::from_num((self.num() as i32 + steps) as u32)
    }
}

impl std::fmt::Display for Note {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.name())
    }
}

/* Iterator ideas */

// Chromatic iterator
// Scale iterator
// Filter by note name
// Filter by interval

/* Implement operations */
