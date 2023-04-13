use modules::*;

mod conversions;
mod io;
//mod math;
//mod scripting;

pub use conversions::*;
pub use io::*;
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
    ]
};

#[no_mangle]
pub extern fn export_plugin() -> *const Plugin {
    &PLUGIN
}
