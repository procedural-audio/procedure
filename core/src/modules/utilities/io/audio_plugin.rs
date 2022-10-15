use crate::modules::*;

pub struct AudioPluginModule {
    prepare: Option<fn (u32, usize)>,
    process: Option<fn (&mut [f32])>
}

impl Module for AudioPluginModule {
    type Voice = ();

    const INFO: Info = Info {
        name: "Audio Plugin",
        features: &[],
        color: Color::BLUE,
        size: Size::Static(190, 85),
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
            prepare: None,
            process: None
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 35),
            size: (120, 35),
            child: _AudioPlugin {
                prepare: &mut self.prepare,
                process: &mut self.process
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _vars: &Vars, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
    }
}

#[repr(C)]
pub struct _AudioPlugin<'a> {
    pub prepare: &'a mut Option<fn (u32, usize)>,
    pub process: &'a mut Option<fn (&mut [f32])>,
}

impl<'a> WidgetNew for _AudioPlugin<'a> {
    fn get_name(&self) -> &'static str {
        "AudioPlugin"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}