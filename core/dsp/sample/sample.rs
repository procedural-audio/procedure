use crate::buffers::*;

use std::sync::Arc;
use std::time::Duration;

pub use crate::cache::FileLoad;
use crate::Player;
use crate::Generator;
use crate::Pitched;

#[derive(Clone)]
pub struct SampleFile<T: SampleTrait> {
    buffer: Arc<Buffer<T>>,
    path: String,
    pitch: f32,
    sample_rate: u32,
}

impl<T: SampleTrait> SampleFile<T> {
    pub fn from(buffer: Arc<Buffer<T>>, pitch: f32, sample_rate: u32, path: String) -> Self {
        return Self {
            buffer,
            path,
            pitch,
            sample_rate,
        };
    }

    pub fn path(&self) -> &str {
        &self.path
    }

    pub fn sample_rate(&self) -> u32 {
        self.sample_rate
    }

    pub fn as_slice(&self) -> &[T] {
        self.buffer.as_slice()
    }

    pub fn duration(&self) -> Duration {
        Duration::from_millis(self.len() as u64 / self.sample_rate as u64 * 1000)
    }

    pub fn len(&self) -> usize {
        self.buffer.len()
    }
}

/*impl<T: SampleTrait> Playable for SampleFile<T> {
    type Player = SamplePlayer<T>;

    fn player(self) -> Self::Player {
        SamplePlayer::new()
    }
}*/

/*impl<T: SampleTrait> Player for SamplePlayer<T> {
    fn play(&mut self) {
        self.playing = true;
    }

    fn pause(&mut self) {
        self.playing = false;
    }

    fn stop(&mut self) {
        self.playing = false;
        self.index = 0;
    }
}*/

/*impl<T: SampleTrait> Generator for SamplePlayer<T> {
    type Item = T;

    fn reset(&mut self) {
        todo!()
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        todo!()
    }

    fn gen(&mut self) -> Self::Item {
        
    }
}*/

impl<T: SampleTrait> Pitched for SamplePlayer<T> {
    fn get_pitch(&self) -> f32 {
        self.pitch
    }

    fn set_pitch(&mut self, hz: f32) {
        self.pitch = hz;
    }
}

impl<T: SampleTrait> Generator for SamplePlayer<T> {
    type Item = T;

    fn reset(&mut self) {
        todo!()
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        self.sample_rate = sample_rate;
    }

    fn gen(&mut self) -> Self::Item {
        todo!()
    }

    fn generate_block(&mut self, output: &mut Buffer<T>) {
        if self.playing {
            if let Some(sample) = &self.sample {
                if self.index + output.len() < sample.buffer.len() {
                    let end = self.index + output.len();
                    for (buf, out) in sample.buffer.as_slice()[self.index..end].iter().zip(&mut output.into_iter()) {
                        *out = *buf;
                    }

                    self.index += output.len();
                } else {
                    self.playing = false;
                }
            }
        }
    }
}

/* ===== Sample Voice ===== */

pub struct SamplePlayer<T: SampleTrait> {
    sample: Option<SampleFile<T>>,
    playing: bool,
    index: usize,
    pitch: f32,
    sample_rate: u32
}

impl<T: SampleTrait> SamplePlayer<T> {
    pub fn new() -> Self {
        Self {
            sample: None,
            playing: false,
            index: 0,
            pitch: 440.0,
            sample_rate: 44100
        }
    }

    pub fn set_sample(&mut self, sample: SampleFile<T>) {
        // self.index = f64::round(sample.len() as f64 * self.start as f64) as usize;
        self.index = 0;
        self.sample = Some(sample);
    }

    pub fn play(&mut self) {
        self.playing = true;
    }

    pub fn pause(&mut self) {
        self.playing = false;
    }

    pub fn stop(&mut self) {
        self.playing = false;
        self.index = 0;
    }

    fn process_old(&mut self, buffer: &mut Buffer<T>) {
        /*let pitch_scale = self.playback_pitch as f64 / self.sample_pitch as f64;
        if let Some(sample) = &self.sample {
            if self.should_loop == false {
                /* Shouldn't loop */

                let end = f32::round(self.end * sample.len() as f32) as usize;

                if self.index + buffer.len() < end {
                    /* Render full block */

                    let start = self.index;

                    let mut source_left =
                        dasp_signal::from_iter(sample.as_array()[0].iter().cloned());
                    let first_left = source_left.next();
                    let second_left = source_left.next();
                    let interp_left = Linear::new(first_left, second_left);
                    let mut conv_left =
                        Converter::scale_playback_hz(source_left, interp_left, pitch_scale);

                    let mut source_right =
                        dasp_signal::from_iter(sample.as_array()[1].iter().cloned());
                    let first_right = source_right.next();
                    let second_right = source_right.next();
                    let interp_right = Linear::new(first_right, second_right);
                    let mut conv_right =
                        Converter::scale_playback_hz(source_right, interp_right, pitch_scale);

                    for _ in 0..start {
                        conv_left.next(); // TOO EXPENSIVE. MAY INTERPOLATE ENTIRE SAMPLE
                        conv_right.next();
                    }

                    for dest in &mut buffer.left {
                        *dest += conv_left.next();
                    }

                    for dest in &mut buffer.right {
                        *dest += conv_right.next();
                    }

                    self.index += buffer.len();
                } else {
                    /* Sample end */

                    if self.index < end {
                        buffer.left.add_from2(&sample.as_array()[0][self.index..end]);
                        buffer
                            .right
                            .add_from2(&sample.as_array()[1][self.index..end]);
                    }

                    self.index = end;
                    self.active = false;
                }
            } else {
                /* Should loop */

                let start = self.index;
                let loop_start = f32::round(self.loop_start * sample.len() as f32) as usize;
                let loop_end = f32::round(self.loop_end * sample.len() as f32) as usize;

                if start + buffer.len() < loop_end {
                    /* Render full block */

                    let mut source_left =
                        dasp_signal::from_iter(sample.as_array()[0].iter().cloned());
                    let first_left = source_left.next();
                    let second_left = source_left.next();
                    let interp_left = Linear::new(first_left, second_left);
                    let mut conv_left =
                        Converter::scale_playback_hz(source_left, interp_left, pitch_scale);

                    let mut source_right =
                        dasp_signal::from_iter(sample.as_array()[1].iter().cloned());
                    let first_right = source_right.next();
                    let second_right = source_right.next();
                    let interp_right = Linear::new(first_right, second_right);
                    let mut conv_right =
                        Converter::scale_playback_hz(source_right, interp_right, pitch_scale);

                    for _ in 0..start {
                        conv_left.next(); // TOO EXPENSIVE. MAY INTERPOLATE ENTIRE SAMPLE
                        conv_right.next();
                    }

                    for dest in &mut buffer.left {
                        *dest += conv_left.next();
                    }

                    for dest in &mut buffer.right {
                        *dest += conv_right.next();
                    }

                    self.index = start + buffer.len();
                } else {
                    /* Sample end */

                    if start < loop_end {
                        buffer.left.add_from2(&sample.as_array()[0][start..loop_end]);
                        buffer
                            .right
                            .add_from2(&sample.as_array()[1][start..loop_end]);
                        self.index = loop_start;
                    } else {
                        self.index = loop_start;
                    }
                }
            }

            /* Attack fade in */

            let attack_samples = f32::round(self.attack * sample.len() as f32) as usize;

            if self.attack_sample < attack_samples {
                for (l, r) in buffer.into_iter() {
                    let m = self.attack_sample as f32 / attack_samples as f32;

                    *l = *l * m;
                    *r = *r * m;

                    self.attack_sample += 1;

                    if self.attack_sample >= attack_samples {
                        break;
                    }
                }
            }

            /* Release fade out */

            if self.note_off {
                let decay_samples = f32::round(self.release * sample.len() as f32) as usize;

                for (l, r) in buffer.into_iter() {
                    let m = (decay_samples - self.release_sample) as f32 / decay_samples as f32;

                    *l = *l * m;
                    *r = *r * m;

                    self.release_sample += 1;

                    if self.release_sample >= decay_samples {
                        self.active = false;

                        *l = 0.0;
                        *r = 0.0;
                    }
                }
            }
        }*/
    }
}

/*impl Voice for SamplePlayer {
    fn play(&mut self) {
        match &self.sample {
            Some(sample) => {
                self.active = true;
                self.index = f64::round(sample.len() as f64 * self.start as f64) as usize;
            }
            None => {
                self.active = true;
                self.index = 0;
            }
        }
    }

    fn note_on(&mut self, id: Id, _offset: u16, _note: NoteMessage, _pressure: f32) {
        match &self.sample {
            Some(sample) => {
                self.active = true;
                self.id = id;
                self.index = f64::round(sample.len() as f64 * self.start as f64) as usize;
                self.attack_sample = 0;
                self.release_sample = 0;
                self.note_off = false;
            }
            None => {
                self.active = true;
                self.id = id;
                self.index = 0;
                self.attack_sample = 0;
                self.release_sample = 0;
                self.note_off = false;
            }
        }
    }

    fn note_off(&mut self) {
        self.note_off = true;
    }

    fn set_pitch(&mut self, freq: f32) {
        self.playback_pitch = freq;
    }

    fn set_pressure(&mut self, _pressure: f32) {}

    fn is_active(&self) -> bool {
        self.active
    }

    fn id(&self) -> Id {
        self.id
    }

    fn position(&self) -> usize {
        self.index
    }
}*/