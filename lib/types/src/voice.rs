use crate::buffers::*;

pub trait Voice<T: AudioChannels> {
    fn new() -> Self;
    fn get_current_note() -> u32;
    fn start_note(midi: u32, velocity: f32);
    fn stop_note(velocity: f32);
    fn is_playing() -> bool;
    fn is_key_down() -> bool;
    fn set_sustained(is_down: bool);
    fn is_sustained() -> bool;

    fn prepare(&mut self, sample_rate: u32, block_size: usize);
    fn process(&mut self, inputs: &T, outputs: &mut T);
}
