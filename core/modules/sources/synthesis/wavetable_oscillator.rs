use crate::*;



// use pa_dsp::buffers::*;

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
    wave_index: u32,
    freq: f32,
    glide: f32,
    wavetable: Wavetable,
}

pub struct WavetableOscillatorVoice {
    player: dsp::WavetablePlayer,
}

impl Module for WavetableOscillator {
    type Voice = WavetableOscillatorVoice;

    const INFO: Info = Info {
        title: "Wavetable Oscillator",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(500, 300),
        voicing: Voicing::Polyphonic,
        inputs: &[Pin::Notes("Midi Input", 20), Pin::Control("Pitch", 50)],
        outputs: &[Pin::Audio("Audio Output", 20)],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        Self {
            wave_index: 0,
            freq: 100.0,
            glide: 0.0,
            wavetable: Wavetable::generate(f32::sin),
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        Self::Voice {
            player: WavetablePlayer::default(),
        }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    // Make it look like pigments: https://youtu.be/8DjnDVWKaEs?t=141

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Transform {
            position: (40, 40),
            size: (350, 220),
            //child: Wavetable::generate(f32::sin)
            child: EmptyWidget,
        });
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {
        // voice.player.set_wavetable(self.wavetable);

        /*
        outputs.audio[0].copy_from(
            voice.player.pitch(self.freq)
        );
        */
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_wavetable_set_value(_knob: &mut _NotesTrack, _value: f32) {}
