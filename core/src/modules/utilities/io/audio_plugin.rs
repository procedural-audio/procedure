use audio_plugin_loader::{AudioPluginManager, AudioPlugin};

use crate::modules::*;

pub struct AudioPluginModule {
    manager: AudioPluginManager,
    plugin: Option<AudioPlugin>
}

impl Module for AudioPluginModule {
    type Voice = ();

    const INFO: Info = Info {
        name: "Audio Plugin",
        features: &[],
        color: Color::BLUE,
        size: Size::Static(160, 100),
        voicing: Voicing::Monophonic,
        vars: &[],
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
        let plugin = manager.create_plugin("Diva");
        
        if let Some(plugin) = &plugin {
            // plugin.show_gui();
        }

        Self {
            manager,
            plugin,
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 30),
            size: (40, 40),
            child: _AudioPlugin {
                plugin: &self.plugin,
                manager: &self.manager
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _vars: &Vars, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
    }
}

#[repr(C)]
pub struct _AudioPlugin<'a> {
    pub plugin: &'a Option<AudioPlugin>,
    pub manager: &'a AudioPluginManager,
}

impl<'a> WidgetNew for _AudioPlugin<'a> {
    fn get_name(&self) -> &'static str {
        "AudioPlugin"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_audio_plugin_show_gui(widget: &mut _AudioPlugin) {
    if let Some(plugin) = widget.plugin {
        plugin.show_gui();
    }
}