use std::sync::Mutex;

use modules::*;
use nodio::*;

static PLUGIN: Plugin = Plugin {
    name: "Built-in Utility Modules",
    version: 1,
    modules: &[
        module::<AudioPluginModule>(),
    ]
};

#[no_mangle]
pub extern fn export_plugin() -> *const Plugin {
    &PLUGIN
}

pub struct AudioPluginModule {
    manager: AudioPluginManager,
    plugin: Mutex<Option<AudioPlugin>>,
    sample_rate: u32,
    block_size: usize
}

pub struct AudioPluginVoice {
    index: u32,
    sample_rate: u32,
    block_size: usize
}

impl Module for AudioPluginModule {
    type Voice = AudioPluginVoice;

    const INFO: Info = Info {
        title: "Audio Plugin",
        id: "default.io.audio_plugin",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(260, 80),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Input", 15),
            Pin::Notes("Notes Input", 45),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 15),
            Pin::Notes("Notes Output", 45)
        ],
        path: &["Utilities", "IO", "Audio Plugin"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            manager: AudioPluginManager::new(),
            plugin: Mutex::new(None),
            sample_rate: 44100,
            block_size: 512
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice {
            index,
            sample_rate: 44100,
            block_size: 512
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Padding {
            padding: (35, 35, 35, 5),
            child: Row {
                children: (
                    SizedBox {
                        size: (30, 30),
                        child: IconButton {
                            icon: Icon {
                                path: "icons/icon.svg",
                                color: Color::BLUE,
                            },
                            on_pressed: | down | {
                                if down {
                                    let plugin = &mut *self.plugin.lock().unwrap();
                                    if let Some(plugin) = plugin {
                                        plugin.show_gui();
                                    }
                                }
                            }
                        }
                    },
                    SizedBox {
                        size: (4, 0),
                        child: EmptyWidget
                    },
                    SearchableDropdown {
                        categories: vec![
                            Category {
                                name: String::from("Category 1"),
                                elements: vec![
                                    String::from("Element 1"),
                                    String::from("Element 2"),
                                    String::from("Element 3"),
                                ]
                            }
                        ],
                        on_select: | element | {
                            let mut plugin = &mut *self.plugin.lock().unwrap();
                            *plugin = self.manager.create_plugin(element);

                            if let Some(plugin) = &mut plugin {
                                plugin.prepare(self.sample_rate, self.block_size);
                            }
                        }
                    }
                )
            }
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        if voice.index == 0 {
            voice.sample_rate = sample_rate;
            voice.block_size = block_size;

            let plugin = &mut *self.plugin.lock().unwrap();
            if let Some(plugin) = plugin {
                plugin.prepare(sample_rate, block_size);
            }
        }
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if voice.index == 0 {
            if let Ok(plugin) = &mut self.plugin.try_lock() {
                if let Some(plugin) = &mut **plugin {
                    plugin.process(&inputs.audio[0], &inputs.events[0], &mut outputs.audio[0]);
                }
            }
        }
    }
}
