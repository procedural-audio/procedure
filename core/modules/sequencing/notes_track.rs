use pa_dsp::*;
use crate::*;
use pa_dsp::event::NoteEvent;

pub struct NotePlayer {
    max_voice: u32,
    live: Vec<(u32, u32)>, // (Voice ID, Note ID)
    queued: Vec<(u32, Note)> // (Note ID, Note)
}

impl NotePlayer {
    fn play_note(id: u32, note: Note) {
    }

    fn stop_note(id: u32) {

    }
}

/*pub struct NoteEvent {
    pub start: f64,  // Start in beats
    pub length: f64, // Length in beats
    pub note: Note,
}*/

pub struct NotesTrack {
    events: Vec<NoteEvent>,
    length: usize,
    beat: f64,
    max_voice: u32,
    queue: Vec<(u32, Event)>, // (voice index, event)
    output: Vec<Note>,
}

impl Module for NotesTrack {
    type Voice = u32;

    const INFO: Info = Info {
        title: "Notes Track",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Reisizable {
            default: (800, 500),
            min: (300, 200),
            max: (8000, 1200),
        },
        voicing: Voicing::Polyphonic,
        inputs: &[Pin::Time("Time", 10)],
        outputs: &[Pin::Notes("Notes Output", 10)],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        Self {
            events: Vec::with_capacity(256),
            length: 8 * 4,
            beat: 0.0,
            queue: Vec::with_capacity(64),
            output: Vec::with_capacity(64),
            max_voice: 0,
        }
    }

    fn new_voice(index: u32) -> Self::Voice {
        index
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Padding {
            padding: (10, 35, 10, 10),
            child: _NotesTrack {
                notes: &mut self.events,
                beats: &mut self.length,
                beat: &self.beat,
            },
        });
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if *voice == 0 {
            let time = inputs.time[0];
            self.beat = time.cycle(self.length as f64).start();

            self.queue.clear();

            for event in &self.events {
                if time.cycle(self.length as f64).contains(event.time.beat()) {
                    self.queue.push((0, event.note));
                }
            }
        }

        for (index, event) in &self.queue {
            if *index == *voice {
                outputs.events[0].push(*event);
            }
        }

        self.queue.retain(|(i, _e)| *i != *voice);
    }
}

#[repr(C)]
pub struct _NotesTrack<'a> {
    notes: &'a mut Vec<NoteEvent>,
    beats: &'a mut usize,
    beat: &'a f64,
}

impl<'a> WidgetNew for _NotesTrack<'a> {
    fn get_name(&self) -> &'static str {
        "NotesTrack"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_get_event_count(w: &mut _NotesTrack) -> usize {
    w.notes.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_get_event_type(w: &mut _NotesTrack, index: usize) -> u32 {
    match w.notes[index].note {
        Event::NoteOn { note, offset } => 0,
        Event::NoteOff { id } => 1,
        Event::Pitch { id, freq } => 2,
        Event::Pressure { id, pressure } => 3,
        Event::Controller { id, value } => 4,
        Event::ProgramChange { id, value } => 5,
        Event::None => todo!(),
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_get_event_time(w: &mut _NotesTrack, index: usize) -> f64 {
    w.notes[index].time.beat()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_event_get_note_on_num(w: &mut _NotesTrack, index: usize) -> u32 {
    match w.notes[index].note {
        Event::NoteOn { note, offset } => note.num(),
        _ => panic!("Can't get note num for not note_on")
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_event_set_time(
    w: &mut _NotesTrack,
    index: usize,
    time: f64,
) {
    w.notes[index].time = Time(time);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_event_set_note_on_num(w: &mut _NotesTrack, index: usize, num: u32) {
    match w.notes[index].note {
        Event::NoteOn { note, offset } => {
            w.notes[index].note = Event::NoteOn {
                note: note.with_pitch(Note::from_num(num).pitch),
                offset: offset
            };
        },
        _ => panic!("Setting num on wrong type")
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_add_note(
    w: &mut _NotesTrack,
    start: f64,
    length: f64,
    num: u32,
) {
    w.notes.push(
        NoteEvent {
            time: Time(start),
            note: Event::NoteOn {
                note: Note::from_num(num),
                offset: 0
            }
        }
    );

    w.notes.push(
        NoteEvent {
            time: Time(start),
            note: Event::NoteOff {
                id: Id::new()
            }
        }
    );
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_remove_note(w: &mut _NotesTrack, index: usize) {
    w.notes.remove(index);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_get_beats(w: &mut _NotesTrack) -> usize {
    *w.beats
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_set_beats(w: &mut _NotesTrack, beats: usize) {
    *w.beats = beats;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_get_beat(w: &mut _NotesTrack) -> f64 {
    *w.beat
}
