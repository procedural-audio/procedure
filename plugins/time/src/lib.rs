use modules::*;

mod time;

pub use time::*;

static PLUGIN: Plugin = Plugin {
    name: "Built-in Time Modules",
    version: 1,
    modules: &[
        // Time
        module::<GlobalTime>(),
        module::<GlobalTransport>(),
        module::<Rate>(),
        module::<Reverse>(),
        module::<Accumulator>(),
        // module::<Loop>(),
        // module::<Shift>(),
        module::<Arranger>(),
    ]
};

#[no_mangle]
pub extern fn export_plugin() -> *const Plugin {
    &PLUGIN
}
