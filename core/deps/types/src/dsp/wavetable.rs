use crate::dsp::*;

#[derive(Copy, Clone)]
pub struct Wavetable {
    array: [f32; 2048],
}

impl Wavetable {
    pub fn from(array: [f32; 2048]) -> Self {
        Self { array }
    }

    pub fn generate<F: Fn(f32) -> f32>(f: F) -> Self {
        let mut array = [0.0; 2048];
        let mut i = 0;

        while i < 2048 {
            array[i] = f(i as f32 / 2048 as f32 * std::f32::consts::PI * 2.0);
            i += 1;
        }

        Self { array }
    }
}

impl Playable for Wavetable {
    type Player = WavetablePlayer;

    fn player(self) -> Self::Player {
        Self::Player {
            wavetable: self,
            pitch: 440.0,
        }
    }
}

pub struct WavetablePlayer {
    wavetable: Wavetable,
    pitch: f32,
}

impl Default for WavetablePlayer {
    fn default() -> Self {
        Self {
            wavetable: Wavetable::generate(f32::sin),
            pitch: 440.0,
        }
    }
}

impl Generator for WavetablePlayer {
    type Item = f32;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn gen(&mut self) -> f32 {
        0.0
    }
}

impl Pitched for WavetablePlayer {
    fn get_pitch(&self) -> f32 {
        self.pitch
    }

    fn set_pitch(&mut self, hz: f32) {
        self.pitch = hz;
    }
}
