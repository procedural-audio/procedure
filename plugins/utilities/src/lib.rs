use modules::*;

mod conversions;
mod io;
mod time;
//mod math;
//mod scripting;

pub use conversions::*;
pub use io::*;
pub use time::*;
//pub use math::*;
//pub use scripting::*;

static PLUGIN: Plugin = Plugin {
    name: "Built-in Utility Modules",
    version: 1,
    modules: &[
        // Conversions
        module::<ControlToNotes>(),
        module::<NotesToControl>(),

        // IO
        module::<AudioInput>(),
        module::<AudioOutput>(),
        module::<MidiInput>(),
        module::<MidiOutput>(),
        // module::<AudioPluginModule>(),

        // Scripting
        // module::<LuaScripter>(),
        // module::<FaustScripter>(),
        // module::<DSPDesigner>(),

        // Time
        module::<GlobalTime>(),
        module::<GlobalTransport>(),
        module::<Rate>(),
        module::<Reverse>(),
        module::<Accumulator>(),
        // module::<Loop>(),
        // module::<Shift>(),
    ]
};

#[no_mangle]
pub extern fn export_plugin() -> *const Plugin {
    &PLUGIN
}
