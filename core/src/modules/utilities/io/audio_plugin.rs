use crate::modules::*;

pub struct AudioPluginModule {
    process: Option<extern "C" fn (u32, *const *mut f32, u32, u32, *mut Event, u32)>,
    id: Option<u32>,
    // plugin: Option<AudioPlugin>
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
        // let manager = AudioPluginManager::new();
        // let plugin = manager.create_plugin("ValhallaRoom").unwrap();

        Self {
            process: None,
            id: None,
            // plugin: Some(plugin),
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
            child: _AudioPlugin {
                process: &mut self.process,
                id: &mut self.id,
                // plugin: &mut self.plugin
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

#[repr(C)]
pub struct _AudioPlugin<'a> {
    pub process: &'a mut Option<extern "C" fn (u32, *const *mut f32, u32, u32, *mut Event, u32)>,
    id: &'a mut Option<u32>,
    // plugin: &'a mut Option<AudioPlugin>
}

impl<'a> WidgetNew for _AudioPlugin<'a> {
    fn get_name(&self) -> &'static str {
        "AudioPlugin"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

#[no_mangle]
extern "C" fn ffi_audio_plugin_set_process_addr(plugin: &mut _AudioPlugin, f: Option<extern "C" fn(u32, *const *mut f32, u32, u32, *mut Event, u32)>) {
    *plugin.process = f;
}

#[no_mangle]
extern "C" fn ffi_audio_plugin_set_module_id(plugin: &mut _AudioPlugin, id: u32) {
    *plugin.id = Some(id);
}

/*#[no_mangle]
extern "C" fn ffi_audio_plugin_show_gui(plugin: &mut _AudioPlugin) {
    if let Some(plugin) = plugin.plugin {
        plugin.show_gui();
    }
}*/