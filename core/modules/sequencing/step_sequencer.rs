use crate::*;

// use rlua::{Function, Lua, Result, Table, TablePairs, prelude::LuaTable, Nil};
// use std::sync::RwLock;

pub struct StepSequencer {
    grid: [[bool; 7]; 16],
    playing: Vec<(u32, Id)>,
    queue: Vec<NoteMessage>,
    step: usize,
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
        size: Size::Static(20 + 42 * 16, 42 * 8),
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
        Self {
            grid: [[false; 7]; 16],
            playing: Vec::with_capacity(32),
            queue: Vec::with_capacity(32),
            step: 0,
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
            child: widget::StepSequencer {
                grid: &mut self.grid,
                step: &self.step,
            }
        });
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        inputs.time[0]
            .cycle(self.grid.len() as f64)
            .on_each(1.0, | step | {
                if voice.index == 0 {
                    self.step = step;

                    for (index, pad) in self.grid[step].iter().enumerate() {
                        if *pad {
                            self.queue.push(NoteMessage {
                                id: Id::new(),
                                offset: 0,
                                note: Event::NoteOn {
                                    pitch: num_to_pitch(index as u32),
                                    pressure: 1.0
                                }
                            });
                        }
                    }
                }

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
            }
        );

        if let Some(msg) = self.queue.pop() {
            outputs.events[0].push(msg);
            self.playing.push((voice.index, msg.id));
        }
    }
}
