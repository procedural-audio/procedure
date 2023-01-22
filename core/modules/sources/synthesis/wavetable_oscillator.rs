use crate::*;

fn wavetable<T: Fn(f32) -> f32, const C: usize>(f: T) -> [f32; C] {
    let mut array = [0.0; C];
    let mut i = 0;

    while i < C {
        array[i] = f(i as f32 / C as f32 * std::f32::consts::PI * 2.0);
        i += 1;
    }

    return array;
}

pub struct WavetableOscillator {
    wavetable: [f32; 2048]
}

pub struct WavetableOscillatorVoice {
    player: dsp::WavetablePlayer,
}

impl Module for WavetableOscillator {
    type Voice = WavetableOscillatorVoice;

    const INFO: Info = Info {
        title: "Wavetable Oscillator",
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
        path: "Category 1/Category 2/Module Name",
        presets: Presets {
            path: "wavetables",
            extension: ".wavetable"
        }
    };

    fn new() -> Self {
        Self {
            wavetable: [0.0; 2048]
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
                dir: "some/dir/here",
                on_event: | _event | {
                    println!("Some browser event");
                },
                child: WavetablePicker {
                    wavetable: &mut self.wavetable
                }
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