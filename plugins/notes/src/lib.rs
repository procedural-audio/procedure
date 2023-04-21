use modules::{Plugin, module};

mod sequencing;
mod generative;
mod effects;

pub use sequencing::*;
pub use generative::*;
pub use effects::*;

static PLUGIN: Plugin = Plugin {
    name: "Built-in Notes Modules",
    version: 1,
    modules: &[
        // Sources
        module::<NotesTrack>(),
        module::<StepSequencer>(),
        module::<Arpeggiator>(),
        module::<Keyboard>(),
        module::<Rene>(),

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
