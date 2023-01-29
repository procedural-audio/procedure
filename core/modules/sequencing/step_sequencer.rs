use crate::*;

use rlua::{Function, Lua, Result, UserData, MetaMethod, prelude::LuaUserData, Table, TablePairs, prelude::LuaTable, Nil};
use std::sync::Mutex;

pub struct StepSequencer {
    pads: [[Pad; 7]; 16],
    playing: Vec<(u32, Id)>,
    queue: Vec<NoteMessage>,
    step: usize,
    callback: Callback,
    lua: Mutex<Lua>
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
        size: Size::Static(42 * 16 + 2, 42 * 8 + 11),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Time("Time", 10)
        ],
        outputs: &[
            Pin::Notes("Midi Output", 10)
        ],
        path: "Notes/Effects/Arpeggiator",
        presets: Presets::NONE
    };
    
    fn new() -> Self {
        let lua = Lua::new();

        lua.context( | context | {
            match context.load(r#"
                function onStep(i, pads)
                    print("Step num", i, ", outlined: ", tostring(pads:down()))
                end
            "#).eval::<()>() {
                Ok(_) => println!("Evaluated lua"),
                Err(_) => println!("Failed to evaluate lua")

            }
        });

        Self {
            pads: [[
                Pad {
                    down: false,
                    outlined: false,
                    color: Color::GREEN,
                }; 7]; 16],
            playing: Vec::with_capacity(32),
            queue: Vec::with_capacity(32),
            step: 0,
            callback: Callback::new(),
            lua: Mutex::new(lua)
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice { index }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Padding {
            padding: (5, 35, 5, 5),
            child: Scripter {
                dir: "some/path/here",
                on_update: | script | {
                    println!("Script {}", script);
                },
                child: Refresh {
                    callback: &mut self.callback,
                    child: widget::Pads {
                        pads: &mut self.pads,
                        on_event: | event, pads | {
                            match event {
                                PadEvent::Press(x, y) => {
                                    println!("Pad pressed");
                                    pads[x][y].down = !pads[x][y].down;
                                },
                                PadEvent::Release(x, y) => {
                                    println!("Pad released");
                                },
                            }
                        }
                    }
                }
            }
        });
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        inputs.time[0]
            .cycle(self.pads.len() as f64)
            .on_each(1.0, | step | {
                if voice.index == 0 {
                    self.step = step;

                    for (i, col) in &mut self.pads.iter_mut().enumerate() {
                        for pad in col {
                            pad.outlined = i == step;
                        }
                    }

                    if let Ok(lua) = self.lua.try_lock() {
                        lua.context( | context | {
                            let globals = context.globals();
                            let on_step: Result<Function> = globals.get("onStep");

                            if let Ok(on_step) = on_step {
                                // Maybe can do context.scope(| scope | ) here to borrow pads value?
                                match on_step.call::<(usize, LuaPads<16, 7>), ()>((step, LuaPads(self.pads))) {
                                    Ok(_) => {
                                       // println!("Got onStep return value");
                                    },
                                    Err(e) => {
                                        println!("Error calling onStep {}", e);
                                    }
                                }
                            }

                        });
                    }

                    self.callback.trigger();

                    for (index, pad) in self.pads[step].iter().enumerate() {
                        if pad.down {
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

#[derive(Copy, Clone)]
struct LuaPads<const X: usize, const Y: usize>(pub [[Pad; Y]; X]);

impl<const X: usize, const Y: usize> UserData for LuaPads<X, Y> {
    fn add_methods<'lua, T: rlua::UserDataMethods<'lua, Self>>(methods: &mut T) {
        /*methods.add_meta_function(MetaMethod::Index, | context, pads: LuaPads<X, Y> | {
            Ok(pads[0])
        });*/

        methods.add_method("down", | context, pads, () | {
            Ok(pads.0[0][0].down)
        });
    }

    fn get_uvalues_count(&self) -> std::os::raw::c_int {
        1
    }
}