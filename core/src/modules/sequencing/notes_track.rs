use tonevision_types::*;

pub struct NoteEvent {
    pub start: f64,  // Start in beats
    pub length: f64, // Length in beats
    pub note: Note,
}

pub struct NotesTrack {
    notes: Vec<NoteEvent>,
    beats: usize,
    beat: f64,
    max_voice: u32,
    queue: Vec<(u32, Event)>,
    output: Vec<Note>,
}

impl Module for NotesTrack {
    type Voice = u32;

    const INFO: Info = Info {
        name: "Notes Track",
                color: Color::GREEN,
        size: Size::Reisizable {
            default: (800, 500),
            min: (300, 200),
            max: (8000, 1200),
        },
        voicing: Voicing::Polyphonic,
        params: &[],
inputs: &[Pin::Time("Time", 10)],
        outputs: &[Pin::Notes("Notes Output", 10)],
    };

    fn new() -> Self {
        Self {
            notes: Vec::with_capacity(256),
            beats: 8 * 4,
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
                notes: &mut self.notes,
                beats: &mut self.beats,
                beat: &self.beat,
            },
        });
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _vars: &Vars, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if *voice == 0 {
            let time = inputs.time[0];
            self.beat = time.cycle(self.beats as f64).start();

            self.queue.clear();

            for event in &self.notes {
                if time.cycle(self.beats as f64).contains(event.start) {
                    self.queue.push((
                        0,
                        Event::NoteOn {
                            note: event.note,
                            offset: 0,
                        },
                    ));
                    println!("Hit note");
                }

                if time
                    .cycle(self.beats as f64)
                    .contains(event.start + event.length)
                {
                    self.queue.push((0, Event::NoteOff { id: event.note.id }));
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
pub unsafe extern "C" fn ffi_notes_track_get_note_count(w: &mut _NotesTrack) -> usize {
    w.notes.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_get_note_start(w: &mut _NotesTrack, index: usize) -> f64 {
    w.notes[index].start
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_get_note_length(w: &mut _NotesTrack, index: usize) -> f64 {
    w.notes[index].length
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_get_note_num(w: &mut _NotesTrack, index: usize) -> u32 {
    w.notes[index].note.num()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_set_note_start(
    w: &mut _NotesTrack,
    index: usize,
    start: f64,
) {
    w.notes[index].start = start;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_set_note_length(
    w: &mut _NotesTrack,
    index: usize,
    length: f64,
) {
    w.notes[index].length = length;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_set_note_num(w: &mut _NotesTrack, index: usize, num: u32) {
    let temp = Note::from_num(num);
    w.notes[index].note = w.notes[index].note.with_pitch(temp.pitch);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_add_note(
    w: &mut _NotesTrack,
    start: f64,
    length: f64,
    num: u32,
) {
    w.notes.push(NoteEvent {
        start,
        length,
        note: Note::from_num(num),
    });
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
