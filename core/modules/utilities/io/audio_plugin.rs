use crate::*;
use nodio::*;

pub struct AudioPluginModule {
    process: Option<extern "C" fn (u32, *const *mut f32, u32, u32, *mut Event, u32)>,
    id: Option<u32>,
    manager: AudioPluginManager,
    plugin: Option<AudioPlugin>,
}

impl Module for AudioPluginModule {
    type Voice = ();

    const INFO: Info = Info {
        name: "Audio Plugin",
        color: Color::BLUE,
        size: Size::Static(270, 90),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Input", 15),
            Pin::Notes("Notes Input", 45),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 15),
            Pin::Notes("Notes Output", 45),
        ],
    };

    fn new() -> Self {
        let manager = AudioPluginManager::new();

        Self {
            process: None,
            id: None,
            manager,
            plugin: None,
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 40),
            size: (200, 35),
            child: SearchableDropdown {
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
                    self.plugin = self.manager.create_plugin(element);

                    if let Some(plugin) = &self.plugin {
                        plugin.show_gui();
                    }
                }
            }
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, _sample_rate: u32, block_size: usize) {
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        outputs.audio[0].copy_from(&inputs.audio[0]);
        outputs.events[0].copy_from(&inputs.events[0]);

        if let Some(f) = self.process {
            if let Some(id) = self.id {
                let arr = [
                    outputs.audio[0].left.as_mut_ptr(),
                    outputs.audio[0].right.as_mut_ptr()
                ];

                (f)(id, arr.as_ptr(), 2, outputs.audio[0].left.len() as u32, outputs.events[0].as_mut_ptr(), outputs.events[0].len() as u32);
            }
        }
    }
}
