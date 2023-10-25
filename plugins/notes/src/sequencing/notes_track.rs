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
        path: &["Notes", "Sequencing", "Notes Track"]
    };

    fn new() -> Self {
        Self {
            events: Vec::with_capacity(512),
            length: 4 * 32,
            beat: 0.0,
            player: NotePlayer::new(),
            callback: Callback::new()
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        index
    }

    fn load(&mut self, _version: &str, state: &State) {
        self.length = state.load("length");

        let mut i = 0;
        while let Some(id_num) = state.try_load(i * 3 + 0) {
            let id_num: usize = id_num;
            let id: Id = Id(id_num as u64);
            let time: f32 = state.load(i * 3 + 1);
            let time = time as f64;
            let s: String = state.load(i * 3 + 2);
            let note = serde_json::from_str::<NoteEvent>(&s).unwrap();

            self.events.push(
                NoteEvent {
                    id,
                    time,
                    note: note.note
                }
            );

            i += 1;
        }
    }

    fn save(&self, state: &mut State) {
        state.save("length", self.length);

        for (i, event) in self.events.iter().enumerate() {
            state.save(i * 3 + 0, event.id.num() as usize);
            state.save(i * 3 + 1, event.time as f32);
            state.save(i * 3 + 2, serde_json::to_string(event).unwrap());
        }
    }

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
                    println!("Queueing message {}", event.id.num());
                    self.player.message(NoteMessage {
                        id: event.id,
                        offset: 0,
                        note: event.note
                    });
                }
            }
        }

        self.player.generate(*voice, &mut outputs.events[0]);

        for event in &outputs.events[0] {
            println!("Playing message {}, voice {}, {}", event.id.num(), *voice, event.note);
        }
    }
}
