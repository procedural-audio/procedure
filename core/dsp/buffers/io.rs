use crate::time::*;
use crate::float::frame::*;
use crate::buffers::bus::*;

pub struct IO {
    pub audio: Bus<StereoBuffer>,
    pub events: Bus<NoteBuffer>,
    pub control: Bus<Box<f32>>,
    pub time: Bus<Box<TimeMessage>>,
}
