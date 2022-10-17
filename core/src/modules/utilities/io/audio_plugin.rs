use crate::modules::*;

pub struct AudioPluginModule {
    process: Option<fn (u32, *mut *mut f32, u32, u32)>,
    id: Option<u32>,
}

impl Module for AudioPluginModule {
    type Voice = usize;

    const INFO: Info = Info {
        name: "Audio Plugin",
        features: &[],
        color: Color::BLUE,
        size: Size::Static(270, 90),
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
        Self {
            process: None,
            id: None,
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        256
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 40),
            size: (200, 35),
            child: _AudioPlugin {
                process: &mut self.process,
                id: &mut self.id
            }
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, _sample_rate: u32, block_size: usize) {
        *voice = block_size;
    }

    fn process(&mut self, _vars: &Vars, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        outputs.audio[0].copy_from(&inputs.audio[0]);

        match self.process {
            Some(f) => {
                match self.id {
                    Some(id) => {
                        (f)(id, &mut [
                            outputs.audio[0].left.as_mut_ptr(),
                            outputs.audio[0].right.as_mut_ptr(),
                        ] as *mut *mut f32, 2, *voice as u32);
                    },
                    None => ()
                }
            }
            None => ()
        }
    }
}

#[repr(C)]
pub struct _AudioPlugin<'a> {
    pub process: &'a mut Option<fn (u32, *mut *mut f32, u32, u32)>,
    id: &'a mut Option<u32>
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
extern "C" fn ffi_audio_plugin_set_process_addr(plugin: &mut _AudioPlugin, addr: u64) {
    if addr == 0 {
        *plugin.process = None;
    } else {
        unsafe {
            *plugin.process = Some(std::mem::transmute(addr));
        }
    }
}

#[no_mangle]
extern "C" fn ffi_audio_plugin_set_module_id(plugin: &mut _AudioPlugin, id: u32) {
    *plugin.id = Some(id);
}