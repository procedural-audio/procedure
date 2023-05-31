use crate::*;

use pa_dsp::loadable::{Loadable, Lock};

fn wavetable<T: Fn(f32) -> f32, const C: usize>(f: T) -> [f32; C] {
    let mut array = [0.0; C];
    let mut i = 0;

    while i < C {
        array[i] = f(i as f32 / C as f32 * std::f32::consts::PI * 2.0);
        i += 1;
    }

    return array;
}

pub struct Wavetable {
    pub table: [f32; 2048]
}

impl Wavetable {
    pub fn new() -> Self {
        Self {
            table: wavetable(|x| x.sin())
        }
    }
}

impl Loadable for Wavetable {
    fn load(path: &str) -> Result<Self, String> where Self: Sized {
        Ok( Self { table: wavetable(|x| x.sin()) } )
    }

    fn path(&self) -> String {
        String::from("Some test path")
    }
}

pub struct WavetableOscillator {
    wavetable: Lock<Wavetable>
}

pub struct WavetableOscillatorVoice {
    player: dsp::WavetablePlayer,
}

impl Module for WavetableOscillator {
    type Voice = WavetableOscillatorVoice;

    const INFO: Info = Info {
        title: "Wavetable Oscillator",
        id: "default.synthesis.wavetable",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(400, 300),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Midi Input", 10),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 10)
        ],
        path: &["Audio", "Synthesis", "Wavetable"],
        presets: Presets {
            path: "wavetables",
            extension: ".wavetable"
        }
    };

    fn new() -> Self {
        Self {
            wavetable: Lock::new(Wavetable::new())
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            player: WavetablePlayer::default(),
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Padding {
            padding: (5, 35, 5, 5),
            child: Browser {
                loadable: self.wavetable.clone(),
                directory: Directory::WAVETABLES,
                extensions: &[".wavetable"],
                child: EmptyWidget,
                /*child: WavetablePicker {
                    wavetable: &mut self.wavetable
                }*/
            }
        });
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {
        // Process stuff here
    }
}

/* ========== FFI ========== */

#[repr(C)]
pub struct WavetablePicker<'a> {
    pub wavetable: &'a mut [f32; 2048]
}

impl<'a> WidgetNew for WavetablePicker<'a> {
    fn get_name(&self) -> &'static str {
        "WavetablePicker"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_wavetable_get_index(widget: &mut ButtonGrid) -> usize {
    *widget.index
}