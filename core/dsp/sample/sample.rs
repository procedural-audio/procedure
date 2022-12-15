use crate::buffers::*;

use crate::AudioChannel;

use crate::sample::cache::*;
use crate::Source;
use crate::Voice;

use dasp_interpolate;
use dasp_signal;

use std::sync::Arc;
use std::time::Duration;

use dasp_interpolate::linear::Linear;
use dasp_signal::{interpolate::Converter, Signal};

#[derive(Clone)]
pub struct Sample<const C: usize> {
    buffer: Arc<Stereo>,
    path: String,
    pitch: f32,
    sample_rate: u32,
}

impl Sample<2> {
    pub fn from(buffer: Arc<Stereo>, pitch: f32, sample_rate: u32, path: String) -> Self {
        return Self {
            buffer,
            path,
            pitch,
            sample_rate,
        };
    }

    pub fn load(path: &str) -> Self {
        load_sample(path)
    }

    pub fn path(&self) -> &str {
        &self.path
    }

    pub fn sample_rate(&self) -> u32 {
        self.sample_rate
    }

    pub fn duration(&self) -> Duration {
        Duration::from_millis(self.buffer.left.len() as u64 / self.sample_rate as u64 * 1000)
    }
}

impl AudioChannel<2> for Sample<2> {
    fn as_array<'a>(&'a self) -> [&'a [f32]; 2] {
        [self.buffer.left.as_slice(), self.buffer.right.as_slice()]
    }
}

/* ===== Sample Voice ===== */

pub struct SamplePlayer {
    sample: Option<Sample<2>>,
    sample_pitch: f32,
    active: bool,
    note_off: bool,
    index: usize,
    playback_pitch: f32,
    playback_rate: f32,
    id: Id,
    sample_rate: u32,
    start: f32,
    end: f32,
    attack: f32,
    release: f32,
    should_loop: bool,
    loop_start: f32,
    loop_end: f32,
    one_shot: bool,
    reverse: bool,
    attack_sample: usize,
    release_sample: usize,
}

struct Playhead<A> {
    pub index: usize,
    buffer: A,
}

impl SamplePlayer {
    pub fn set_sample(&mut self, sample: Sample<2>) {
        self.index = f64::round(sample.len() as f64 * self.start as f64) as usize;
        self.sample = Some(sample);
    }

    pub fn set_start(&mut self, start: f32) {
        self.start = start;
    }

    pub fn set_end(&mut self, end: f32) {
        self.end = end;
    }

    pub fn set_attack(&mut self, attack: f32) {
        self.attack = attack;
    }

    pub fn set_release(&mut self, release: f32) {
        self.release = release;
    }

    pub fn set_loop(&mut self, should_loop: bool) {
        self.should_loop = should_loop;
    }

    pub fn set_loop_start(&mut self, loop_start: f32) {
        self.loop_start = loop_start;
    }

    pub fn set_loop_end(&mut self, loop_end: f32) {
        self.loop_end = loop_end;
    }

    pub fn set_one_shot(&mut self, one_shot: bool) {
        self.one_shot = one_shot;
    }

    pub fn set_reverse(&mut self, reverse: bool) {
        self.reverse = reverse;
    }
}

impl Source for SamplePlayer {
    type Output = Stereo;

    fn new() -> Self {
        Self {
            sample: None,
            active: false,
            note_off: false,
            index: 0,
            id: Id::new(),
            playback_rate: 1.0,
            playback_pitch: 195.0,
            sample_pitch: 195.0,
            sample_rate: 44100,
            start: 0.0,
            end: 1.0,
            attack: 0.0,
            release: 0.0,
            should_loop: false,
            loop_start: 0.2,
            loop_end: 0.8,
            one_shot: false,
            reverse: false,
            attack_sample: 0,
            release_sample: 0,
        }
    }

    fn reset(&mut self) {
        println!("Should reset voice here");
    }

    fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
        self.sample_rate = sample_rate;
    }

    fn process(&mut self, buffer: &mut Stereo) {
        let pitch_scale = self.playback_pitch as f64 / self.sample_pitch as f64;

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
        }
    }
}

impl Voice for SamplePlayer {
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

    fn note_on(&mut self, id: Id, _offset: u16, _note: Note, _pressure: f32) {
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
}
