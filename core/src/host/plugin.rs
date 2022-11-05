use std::ffi::c_void;
use tonevision_types::*;

use libloading::{Library, Symbol};

#[no_mangle]
extern "C" fn ffi_host_create_audio_plugin_manager(
        ptr: *const c_void, 
        create_plugin_callback: extern "C" fn (*const c_void, *const u8) -> *const c_void,
        manager_delete_callback: extern "C" fn (*const c_void),
        plugin_prepare: extern "C" fn (*const c_void, u32, usize),
        plugin_process: extern "C" fn (*const c_void, *const *mut f32),
        plugin_delete_callback: extern "C" fn (*const c_void),
    ) -> AudioPluginManager {

    panic!("unimplemented");
    /*AudioPluginManager {
        ptr,
        create_plugin_callback,
        manager_delete_callback,
        plugin_prepare,
        plugin_process,
        plugin_delete_callback
    }*/
}

#[repr(C)]
pub struct AudioPluginManager {
    library: Library,
    manager: *const c_void,
    // manager_create_plugin: extern "C" fn (*const u8) -> *const c_void,
    manager_delete: extern "C" fn (*const c_void),
    // plugin_prepare: extern "C" fn (*const c_void, u32, usize),
    // plugin_process: extern "C" fn (*const c_void, *const *mut f32),
    // plugin_delete: extern "C" fn (*const c_void),
}

impl AudioPluginManager {
    pub fn new() -> AudioPluginManager {
        unsafe {
            let library = Library::new("/Users/chasekanipe/Github/nodus/build/out/core/release/libaudio_plugin_loader.dylib").unwrap();

            let manager_create: Symbol<unsafe extern "C" fn() -> *const c_void> = library.get(b"create_manager").unwrap();

            let manager = (manager_create)();
            if manager == std::ptr::null() {
                panic!("Failed to get manager");
            }

            // let create_plugin = *library.get(b"create_plugin").unwrap();
            let manager_delete = *library.get(b"create_plugin").unwrap();
            // let plugin_prepare = *library.get(b"create_plugin").unwrap();
            // let plugin_process = *library.get(b"create_plugin").unwrap();

            AudioPluginManager {
                library,
                manager,
                // create_plugin,
                manager_delete,
                // plugin_prepare,
                // plugin_process,
                // plugin_delete
            }
        }
    }

    pub fn create_plugin(&self, name: String) -> Option<AudioPlugin> {
        return None;
        /*let name = std::ffi::CString::new(name).unwrap();
        let ptr = (self.create_plugin_callback)(self.ptr, name.as_ptr() as *const u8);

        if ptr != std::ptr::null_mut() {
            Some(AudioPlugin {
                ptr,
                plugin_prepare: self.plugin_prepare,
                plugin_process: self.plugin_process,
                plugin_delete_callback: self.plugin_delete_callback
            })
        } else {
            None
        }*/
    }
}

impl Drop for AudioPluginManager {
    fn drop(&mut self) {
        todo!()
    }
}

pub struct AudioPlugin {
    ptr: *const c_void,
    plugin_prepare: extern "C" fn (*const c_void, u32, usize),
    plugin_process: extern "C" fn (*const c_void, *const *mut f32),
    plugin_delete_callback: extern "C" fn (*const c_void),
}

impl AudioPlugin {
    pub fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        (self.plugin_prepare)(self.ptr, sample_rate, block_size);
    }

    pub fn process(&mut self, input: &mut Stereo, output: &mut Stereo) {
        output.copy_from(input);
        let buffer = [output.left.as_mut_ptr(), output.right.as_mut_ptr()];
        (self.plugin_process)(self.ptr, buffer.as_ptr());
    }
}

impl Drop for AudioPlugin {
    fn drop(&mut self) {
        (self.plugin_delete_callback)(self.ptr);
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
