use modules::{Plugin, module};

mod arpeggiator;
mod notes_track;
mod pitch;
mod pressure;
mod step_sequencer;
mod transpose;
mod keyboard;
mod scale;
mod detune;
mod drift;
mod portamento;
mod monophonic;

pub use arpeggiator::*;
pub use notes_track::*;
pub use pitch::*;
pub use pressure::*;
pub use step_sequencer::*;
pub use transpose::*;
pub use keyboard::*;
pub use scale::*;
pub use detune::*;
pub use drift::*;
pub use portamento::*;
pub use monophonic::*;


static PLUGIN: Plugin = Plugin {
    name: "Built-in Notes Modules",
    version: 1,
    modules: &[
        // Sources
        module::<NotesTrack>(),
        module::<StepSequencer>(),
        module::<Arpeggiator>(),
        module::<Keyboard>(),

        // Effects
        module::<Transpose>(),
        module::<Scale>(),
        module::<Pitch>(),
        module::<Pressure>(),
        module::<Detune>(),
        module::<Drift>(),
        module::<Portamento>(),
        module::<Monophonic>(),
    ]
};

#[no_mangle]
pub extern fn export_plugin() -> *const Plugin {
    &PLUGIN
}
