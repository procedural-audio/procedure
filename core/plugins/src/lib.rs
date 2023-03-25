use modules::*;

static PLUGIN: Plugin = Plugin {
    name: "Control Modules Plugin",
    version: 1,
    modules: &[
        module::<And>(),
        module::<Or>(),
        module::<Not>(),
        module::<Xor>(),
        module::<Add>(),
        module::<Subtract>(),
        module::<Multiply>(),
        module::<Divide>(),
        module::<Modulo>(),
        module::<Negative>(),
    ]
};

#[no_mangle]
pub extern fn export_plugin() -> *const Plugin {
    &PLUGIN
}