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
        module::<Keyboard>(),
        module::<XYSequencer>(),

        // Generative
        module::<Generate>(),
        module::<Arpeggiator>(),

        // Effects
        module::<Transpose>(),
        module::<Scale>(),
        module::<Chords>(),
        module::<GetPitch>(),
        module::<SetPitch>(),
        module::<GetVelocity>(),
        module::<SetVelocity>(),
        module::<Detune>(),
        module::<Drift>(),
        module::<Portamento>(),
        module::<Monophonic>(),
        module::<Split>(),
        module::<Length>(),
    ]
};

#[no_mangle]
pub extern fn export_plugin() -> *const Plugin {
    &PLUGIN
}
