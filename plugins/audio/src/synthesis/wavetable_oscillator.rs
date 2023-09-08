use crate::*;

use pa_dsp::loadable::{Loadable, Lock};
use pa_algorithms::*;

pub struct WavetableOscillator {
    wavetable: Lock<Wavetable<f32, 2048>>
}

pub struct WavetableOscillatorVoice {
    player: WavetablePlayer,
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
        let path = "/home/chase/github/assets/wavetables/serum/reddit-pack/Classic Synths/01_RESO1.WAV";
        let wavetable = Wavetable::load(path).unwrap();

        Self {
            wavetable: Lock::new(wavetable)
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
        // _voice.player.generate_block(&mut outputs.audio[0]);
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
