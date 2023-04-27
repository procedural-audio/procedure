use crate::*;

#[repr(C)]
pub struct _NotesTrack<'a> {
    pub notes: &'a mut Vec<NoteEvent>,
    pub beats: &'a mut usize,
    pub beat: &'a f64,
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
pub unsafe extern "C" fn ffi_notes_track_index_get_id(w: &mut _NotesTrack, index: usize) -> u64 {
    w.notes[index].id.num()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_index_get_type(w: &mut _NotesTrack, index: usize) -> u32 {
    match w.notes[index].note {
        Event::NoteOn { pitch, pressure } => 0,
        Event::NoteOff => 1,
        Event::Pitch(freq) => 2,
        Event::Pressure(pressure) => 3,
        Event::Other(name, value) => 5,
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_id_get_time(w: &mut _NotesTrack, id: u64) -> f64 {
    for note in w.notes.iter() {
        if note.id.num() == id {
            return note.time
        }
    }

    unreachable!();
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_id_get_on_time(w: &mut _NotesTrack, id: u64) -> f64 {
    for note in w.notes.iter() {
        if note.id.num() == id {
            match note.note {
                Event::NoteOn { pitch, pressure } => {
                    return note.time;
                },
                _ => ()
            }
        }
    }

    unreachable!();
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_id_get_off_time(w: &mut _NotesTrack, id: u64) -> f64 {
    for note in w.notes.iter() {
        if note.id.num() == id {
            match note.note {
                Event::NoteOff => {
                    return note.time;
                },
                _ => ()
            }
        }
    }

    unreachable!();
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_id_set_time(
    w: &mut _NotesTrack,
    id: u64,
    time: f64,
) {
    for note in w.notes.iter_mut() {
        if note.id.num() == id {
            note.time = time;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_id_set_on_time(
    w: &mut _NotesTrack,
    id: u64,
    time: f64,
) {
    for note in w.notes.iter_mut() {
        if note.id.num() == id {
            match note.note {
                Event::NoteOn { pitch, pressure }=> {
                    note.time = time;
                    return;
                }
                _ => ()
            }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_id_set_off_time(
    w: &mut _NotesTrack,
    id: u64,
    time: f64,
) {
    for note in w.notes.iter_mut() {
        if note.id.num() == id {
            match note.note {
                Event::NoteOff => {
                    note.time = time;
                    return;
                }
                _ => ()
            }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_id_get_note_on_num(w: &mut _NotesTrack, id: u64) -> u32 {
    for note in w.notes.iter() {
        if note.id.num() == id {
            match note.note {
                Event::NoteOn { pitch, pressure } => {
                    return pitch_to_num(pitch);
                }
                _ => ()
            }
        }
    }

    unreachable!();
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_id_set_note_on_num(w: &mut _NotesTrack, id: u64, num: u32) {
    for note in w.notes.iter_mut() {
        if note.id.num() == id {
            match &mut note.note {
                Event::NoteOn { pitch, pressure } => {
                    *pitch = num_to_pitch(num)
                }
                _ => ()
            }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_add_note(
    w: &mut _NotesTrack,
    start: f64,
    length: f64,
    num: u32,
) {
    let id = Id::new();

    w.notes.push(
        NoteEvent {
            id,
            time: start,
            note: Event::NoteOn {
                pitch: num_to_pitch(num),
                pressure: 0.5,
            }
        }
    );

    w.notes.push(
        NoteEvent {
            id,
            time: start + length,
            note: Event::NoteOff
        }
    );
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_id_remove_note(w: &mut _NotesTrack, id_num: u64) {
    w.notes.retain(| n | {
        n.id.num() != id_num
    });
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_get_length(w: &mut _NotesTrack) -> usize {
    *w.beats
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_set_length(w: &mut _NotesTrack, beats: usize) {
    *w.beats = beats;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_notes_track_get_beat(w: &mut _NotesTrack) -> f64 {
    *w.beat
}
