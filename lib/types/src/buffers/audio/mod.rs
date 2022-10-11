mod buffer;
mod bus;
mod channels;

pub use crate::buffers::audio::buffer::*;
pub use crate::buffers::audio::bus::*;
pub use crate::buffers::audio::channels::*;

pub struct Audio<T: AudioChannels> {
    pub inputs: AudioBus<T>,
    pub outputs: AudioBus<T>,
}

impl<T: AudioChannels> Audio<T> {
    pub fn unowned(&self) -> Self {
        Audio {
            inputs: self.inputs.unowned(),
            outputs: self.outputs.unowned(),
        }
    }
}
