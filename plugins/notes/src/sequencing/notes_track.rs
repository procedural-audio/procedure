use pa_dsp::*;
use modules::*;
use pa_dsp::event::NoteEvent;

pub struct NotesTrack {
    events: Vec<NoteEvent>,
    length: usize,
    beat: f64,
    player: NotePlayer,
    callback: Callback
}

impl Module for NotesTrack {
    type Voice = u32;

    const INFO: Info = Info {
        title: "Notes Track",
        id: "default.sequencing.notes_track",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Reisizable {
            default: (800, 500),
            min: (300, 200),
            max: (8000, 1200),
        },
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 10),
            Pin::Time("Time", 10+25)
        ],
        outputs: &[
            Pin::Notes("Notes Output", 10)
        ],
        path: &["Notes", "Sequencing", "Notes Track"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        let id_1 = Id::new();
        let id_2 = Id::new();

        Self {
            events: vec![
                NoteEvent {
                    id: id_1,
                    time: 4.0,
                    note: Event::NoteOn {
                        pitch: 220.0,
                        pressure: 0.3
                    }
                },
                NoteEvent {
                    id: id_1,
                    time: 8.0,
                    note: Event::NoteOff
                },
                NoteEvent {
                    id: id_2,
                    time: 6.0,
                    note: Event::NoteOn {
                        pitch: 220.0 * 1.5,
                        pressure: 0.7
                    }
                },
                NoteEvent {
                    id: id_2,
                    time: 10.0,
                    note: Event::NoteOff
                }
            ],
            length: 4 * 32,
            beat: 0.0,
            player: NotePlayer::new(),
            callback: Callback::new()
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        index
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Padding {
            padding: (5, 35, 5, 5),
            child: Refresh {
                callback: &mut self.callback,
                child: _NotesTrack {
                    notes: &mut self.events,
                    beats: &mut self.length,
                    beat: &self.beat
                }
            }
        });
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let time = inputs.time[0].cycle(self.length as f64);
        self.beat = time.start();

        for msg in &inputs.events[0] {
            println!("Adding note at {}", time.start);

            self.events.push(
                NoteEvent {
                    id: msg.id,
                    time: time.start,
                    note: msg.note
                }
            );

            self.callback.trigger();

            println!("======== start ========");
            for event in &self.events {
                match event.note {
                    Event::NoteOn { pitch, pressure } => {
                        println!("Has note on {}", event.id.num());
                    },
                    Event::NoteOff => {
                        println!("Has note off {}", event.id.num());
                    },
                    _ => ()
                }
            }
            println!("======== end ========");
        }

        if *voice == 0 {
            for event in &self.events {
                if time.contains(event.time) {
                    println!("Playing message {}", event.id.num());
                    self.player.message(NoteMessage {
                        id: event.id,
                        offset: 0,
                        note: event.note
                    });
                }
            }
        }

        self.player.generate(*voice, &mut outputs.events[0]);
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
