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

    fn load(&mut self, _version: &str, state: &State) {
        self.length = state.load("length");

        let mut i = 0;
    }

    fn save(&self, state: &mut State) {
        state.save("length", self.length);
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
