use crate::*;

use rlua::{Function, Lua, Result, Table, TablePairs, prelude::LuaTable, Nil};
use std::sync::RwLock;

pub struct StepSequencer {
    grid: Vec<Vec<bool>>,
    playing: Vec<(u32, Id)>,
    queue: Vec<NoteMessage>,
    step: usize,
    lua: RwLock<Lua>,
}

impl StepSequencer {
    fn step(&mut self, index: usize) {
        if let Ok(lua) = self.lua.try_read() {
            lua.context( | ctx | {
                let globals = ctx.globals();
                let grid: Table = globals.get("grid").unwrap();

                let on_step: Result<Function> = globals.get("onStep");
                match on_step {
                    Ok(on_step) => {
                        // on_step.call::<(usize, LuaTable<'_>), _>((index, grid));
                        // CALL RLUA HERE
                    },
                    Err(_) => (),
                }
            });
        }
    }

    fn update_outlines(&mut self) {
        if let Ok(lua) = self.lua.try_read() {
            lua.context( | ctx | {
                let globals = ctx.globals();
                let grid: Table = globals.get("grid").unwrap();
                let cols: TablePairs<u32, Table> = grid.pairs();

                for col in cols {
                    match col {
                        Ok((i, col)) => {
                            let pads: TablePairs<u32, Table> = col.pairs();

                            for pad in pads {
                                match pad {
                                    Ok((j, pad)) => {
                                        // SET PAD OUTLINE/COLOR HERE
                                    },
                                    _ => ()
                                }
                            }
                        }
                        _ => ()
                    }
                }
            });
        }

    }
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
        size: Size::Static(20 + 42 * 16, 20 + 20 + 42 * 8),
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
            /*let grid = ctx.create_table().unwrap();

            for i in 0..16 {
                let column = ctx.create_table().unwrap();
                for j in 0..8 {
                    let pad = ctx.create_table().unwrap();
                    pad.set("", value)
                    column.set(0, value);
                }
                grid.set(key, value)
            }
            grid.set(0, value)*/

            ctx.load(r#"
                grid = {}

                ncol = 0
                while ncol < 16 do
                    nrow = 0
                    grid[ncol] = {}
                    while nrow < 8 do
                        note = {}
                        note.pressed = false
                        note.outlined = false

                        grid[ncol][nrow] = note

                        nrow = nrow + 1
                    end
                    ncol = ncol + 1
                end

                function playNote(num)
                    print("Playing note", num)
                end

                function onStep(num, grid)
                    print("Stepping from lua")

                    for i,pads in pairs(grid) do
                        for j,pad in pairs(pads) do
                            pad.outlined = false
                        end
                    end

                    for i,pad in pairs(grid[num]) do
                        pad.outlined = true
                        if pad.pressed then
                            playNote(i)
                        end
                    end
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
                self.step(step);
                self.update_outlines();

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

                    
                }
            }
        );

        if let Some(msg) = self.queue.pop() {
            outputs.events[0].push(msg);
            self.playing.push((voice.index, msg.id));
        }
    }
}
