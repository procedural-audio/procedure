#![allow(dead_code)]

use std::ffi::CString;

#[repr(C)]
struct JuceAudioPluginManager;

#[repr(C)]
struct JuceAudioPlugin;

#[link(name="JucePluginLoader", kind="static")]
extern "C" {
    fn create_manager() -> *mut JuceAudioPluginManager;
    fn delete_manager(manager: *mut JuceAudioPluginManager);

    fn create_audio_plugin(manager: *mut JuceAudioPluginManager, name: *const i8) -> *mut JuceAudioPlugin;
    fn audio_plugin_show_gui(plugin: *mut JuceAudioPlugin);
}

/*pub struct AudioPluginManager {
    manager: *mut JuceAudioPluginManager
}

impl AudioPluginManager {
    pub fn new() -> Self {
        Self {
            manager: unsafe { create_audio_plugin_manager() }
        }
    }

    pub fn create_plugin(&self, name: &str) -> Option<AudioPlugin> {
        let name = CString::new(name).unwrap();
        let plugin = unsafe { create_audio_plugin(self.manager, name.as_ptr()) };

        if plugin == std::ptr::null_mut() {
            None
        } else {
            Some(
                AudioPlugin {
                    plugin
                }
            )
        }
    }
}

impl Drop for AudioPluginManager {
    fn drop(&mut self) {
        unsafe {
            destroy_audio_plugin_manager(self.manager);
        }
    }
}

pub struct AudioPlugin {
    plugin: *mut JuceAudioPlugin
}

impl AudioPlugin {
    pub fn show_gui(&self) {
        unsafe { audio_plugin_show_gui(self.plugin); }
    }
}*/