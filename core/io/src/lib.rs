#![allow(dead_code)]

use std::ffi::{CString, c_void};
use pa_dsp::{AudioBuffer, NoteBuffer};

pub trait IOCallback {
    fn process2(&mut self, buffer: &[AudioBuffer], notes: &NoteBuffer);
}

#[no_mangle]
pub unsafe extern "C" fn io_manager_callback(manager: *mut IOManager, inputs: *const *const f32, input_channels: u32, outputs: *mut *mut f32, output_channels: u32, num_samples: u32) {
    (*manager).process(inputs, input_channels, outputs, output_channels, num_samples);
}

#[link(name="JucePluginLoader", kind="static")]
extern "C" {
    fn create_io_manager() -> *mut c_void;
    fn destroy_io_manager(manager: *mut c_void);
    fn io_manager_set_manager(manager: *mut c_void, m: *mut IOManager);

    fn create_audio_plugin_manager() -> *mut c_void;
    fn destroy_audio_plugin_manager(manager: *mut c_void);

    fn create_audio_plugin(manager: *mut c_void, name: *const i8) -> *mut c_void;
    fn destroy_audio_plugin(plugin: *mut c_void);
    fn audio_plugin_show_gui(plugin: *mut c_void);
}

/*pub struct IODevice {
    manager: *mut c_void,
    processor: Box<dyn IOCallback>
}

impl IODevice {
    pub fn from(processor: Box<dyn IOCallback>) -> Box<Self> {
        let mut host = Box::new(Self {
            manager: unsafe { create_io_manager() },
            processor,
        });

        unsafe {
            io_manager_set_manager(host.manager, (&mut *host) as *mut IODevice);
        }

        return host;
    }

    pub fn process(&mut self, inputs: *const *const f32, input_channels: u32, outputs: *mut *mut f32, output_channels: u32, num_samples: u32) {

        // TODO: Should copy inputs to outputs

        if let Some(callback) = self.callback {
            unsafe {
                let size = num_samples as usize;

                println!("Process callback");
                let events = NoteBuffer::new();

                let audio_outputs = [
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(0, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(1, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(2, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(3, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(4, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(5, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(6, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(7, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(8, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(9, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(10, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(11, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(12, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(13, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(14, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(15, output_channels as isize)), size, size),
                ];

                self.processor.process(&audio_outputs[0..output_channels as usize], &events);

                std::mem::forget(audio_outputs);
            }
        }
    }
}

impl Drop for IODevice {
    fn drop(&mut self) {
        unsafe { destroy_io_manager(self.manager) }
    }
}*/

pub struct IOManager {
    manager: *mut c_void,
    callback: Option<&'static mut dyn IOCallback>
}

impl IOManager {
    pub fn new() -> Self {
        let mut host = Self {
            manager: unsafe { create_io_manager() },
            callback: None
        };

        unsafe {
            io_manager_set_manager(host.manager, (&mut host) as *mut IOManager);
        }

        return host;
    }

    pub fn set_callback(&mut self, callback: *mut dyn IOCallback) {
        unsafe {
            self.callback = Some(&mut *callback);
        }
    }

    pub fn clear_callback(&mut self) {
        self.callback = None;
    }

    pub fn process(&mut self, inputs: *const *const f32, input_channels: u32, outputs: *mut *mut f32, output_channels: u32, num_samples: u32) {
        if let Some(callback) = &mut self.callback {
            unsafe {
                let size = num_samples as usize;

                // println!("Process callback");
                let events = NoteBuffer::new();

                // callback.process2(&[], &events);

                /*let audio_outputs = [
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(0, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(1, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(2, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(3, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(4, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(5, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(6, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(7, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(8, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(9, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(10, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(11, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(12, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(13, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(14, output_channels as isize)), size, size),
                    AudioBuffer::from_raw_parts(*outputs.offset(isize::min(15, output_channels as isize)), size, size),
                ];

                (*callback).process(&audio_outputs[0..output_channels as usize], &events);

                std::mem::forget(audio_outputs);*/
            }
        }
    }
}

impl Drop for IOManager {
    fn drop(&mut self) {
        self.callback = None;
        unsafe { destroy_io_manager(self.manager) }
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