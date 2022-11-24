#![allow(dead_code)]

use std::ffi::{CString, c_void};

#[link(name="JucePluginLoader", kind="static")]
extern "C" {
    fn create_audio_device_manager() -> *mut c_void;
    fn destroy_audio_device_manager(manager: *mut c_void);

    fn create_audio_plugin_manager() -> *mut c_void;
    fn destroy_audio_plugin_manager(manager: *mut c_void);

    fn create_audio_plugin(manager: *mut c_void, name: *const i8) -> *mut c_void;
    fn destroy_audio_plugin(plugin: *mut c_void);
    fn audio_plugin_show_gui(plugin: *mut c_void);
}

#[repr(transparent)]
pub struct AudioDeviceManager {
    manager: *mut c_void
}

impl AudioDeviceManager {
    pub fn new() -> Self {
        Self {
            manager: unsafe { create_audio_device_manager() }
        }
    }
}

impl Drop for AudioDeviceManager {
    fn drop(&mut self) {
        unsafe { destroy_audio_device_manager(self.manager) }
    }
}

#[repr(transparent)]
pub struct AudioPluginManager {
    manager: *mut c_void
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

#[repr(transparent)]
pub struct AudioPlugin {
    plugin: *mut c_void
}

impl AudioPlugin {
    pub fn show_gui(&self) {
        unsafe { audio_plugin_show_gui(self.plugin); }
    }
}

impl Drop for AudioPlugin {
    fn drop(&mut self) {
        unsafe { destroy_audio_plugin(self.plugin); }
    }
}