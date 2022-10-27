use std::ffi::c_void;
use tonevision_types::*;

#[no_mangle]
extern "C" fn ffi_create_audio_plugin_manager(ptr: c_void) -> AudioPluginManager {
    AudioPluginManager {
        ptr,
        categories: Vec::new()
    }
}

pub struct AudioPluginManager {
    ptr: c_void,
    categories: Vec<AudioPluginCategory>
}

impl AudioPluginManager {
    pub fn create_plugin(&self) -> Option<AudioPlugin> {
        todo!()
    }
}

impl Drop for AudioPluginManager {
    fn drop(&mut self) {
        todo!()
    }
}

pub struct AudioPlugin {
    ptr: c_void
}

impl AudioPlugin {
    pub fn prepare(&mut self, sample_rate: u32, block_size: usize) {

    }

    pub fn process(&mut self, input: &mut Stereo, output: &mut Stereo) {

    }
}

pub struct AudioPluginCategory {
    name: String,
    plugins: Vec<AudioPluginInfo>
}

pub struct AudioPluginInfo {
    name: String,
    path: String
}

impl AudioPluginInfo {
    pub fn new(path: String) -> Self {
        AudioPluginInfo {
            name: String::new(),
            path: String::new(),
        }
    }
}
