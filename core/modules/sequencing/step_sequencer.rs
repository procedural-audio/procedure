use crate::*;

use rlua::{Function, Lua, Result};
use std::sync::RwLock;

pub struct StepSequencer {
    grid: Vec<Vec<bool>>,
    playing: Vec<(u32, Id)>,
    queue: Vec<NoteMessage>,
    step: usize,
    lua: RwLock<Lua>,
}

pub struct StepSequencerVoice {
    index: u32,
}

impl Module for StepSequencer {
    type Voice = StepSequencerVoice;

    const INFO: Info = Info {
        title: "Step Sequencer",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(20 + 80 + 42 * 16, 20 + 20 + 42 * 8),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Time("Time", 10)
        ],
        outputs: &[
            Pin::Notes("Midi Output", 10)
        ],
        path: "Category 1/Category 2/Module Name"
    };
    
    fn new() -> Self {
        let lua = Lua::new();

        lua.context( | ctx | {
            ctx.load(r#"
                function onNote(num)
                    print("LUA recieved note num", num)
                    return num
                end
            "#).eval::<()>().unwrap();
        });

        Self {
            grid: vec![vec![]],
            playing: Vec::with_capacity(32),
            queue: Vec::with_capacity(32),
            step: 0,
            lua: RwLock::new(lua),
        }
    }

    fn new_voice(index: u32) -> Self::Voice {
        Self::Voice { index }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Padding {
            padding: (10, 35, 10, 10),
            child: Tabs {
                tabs: (
                    Tab {
                        icon: Icon {
                            path: "logos/audio.svg",
                            color: Color::BLUE
                        },
                        child: widget::StepSequencer {
                            grid: &mut self.grid,
                            pad_size: (40.0, 40.0),
                            pad_radius: 10.0,
                            step: &self.step,
                        }
                    },
                    Tab {
                        icon: Icon {
                            path: "logos/audio.svg",
                            color: Color::BLUE,
                        },
                        child: LuaEditor {},
                    },
                )
            }
        });
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        inputs.time[0]
            .cycle(self.grid.len() as f64)
            .on_each(1.0, | step | {

                for (index, id) in &self.playing {
                    if *index == voice.index {
                        outputs.events[0].push(NoteMessage {
                            id: *id,
                            offset: 0,
                            note: Event::NoteOff
                        })
                    }
                }

                self.playing.retain(| (index, _id) | {
                    *index != voice.index
                });

                if voice.index == 0 {
                    self.step = step;
                    for (index, down) in self.grid[step].iter().enumerate() {
                        if *down {
                            if let Ok(lua) = self.lua.try_read() {
                                lua.context( | ctx | {
                                    let globals = ctx.globals();
                                    let on_note: Result<Function> = globals.get("onNote");
                                    match on_note {
                                        Ok(on_note) => {
                                            match on_note.call::<usize, u32>(index) {
                                                Ok(num) => self.queue.push(
                                                    NoteMessage {
                                                        id: Id::new(),
                                                        offset: 0,
                                                        note: Event::NoteOn {
                                                            pitch: num_to_pitch(num),
                                                            pressure: 0.5
                                                        }
                                                    },
                                                ),
                                                Err(_) => ()
                                            }
                                        },
                                        Err(_) => (),
                                    }
                                });
                            }
                        }
                    }
                }
            }
        );

        if let Some(msg) = self.queue.pop() {
            outputs.events[0].push(msg);
            self.playing.push((voice.index, msg.id));
        }
    }
}
