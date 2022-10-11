pub mod buffer;
pub mod bus;
pub mod event;

pub use crate::buffers::event::buffer::*;
pub use crate::buffers::event::bus::*;
pub use crate::buffers::event::event::*;

pub struct Notes {
    pub inputs: NotesBus,
    pub outputs: NotesBus,
}

impl Notes {
    pub fn unowned(&self) -> Self {
        Notes {
            inputs: self.inputs.unowned(),
            outputs: self.outputs.unowned(),
        }
    }
}
