mod comparisons;
mod effects;
mod logic;
mod operations;
mod sources;
mod widgets;

pub use comparisons::*;
pub use effects::*;
pub use logic::*;
pub use operations::*;
pub use sources::*;
pub use widgets::*;

use modules::Plugin;
use modules::module;

static PLUGIN: Plugin = Plugin {
    name: "Built-in Control Modules",
    version: 1,
    modules: &[
        // Sources
        module::<Constant>(),
        module::<LfoModule>(),
        module::<EnvelopeModule>(),
        module::<Beats>(),
        module::<Random>(),
        // module::<ControlTrack>(),

        // Widgets
        module::<KnobModule>(),
        module::<ButtonModule>(),
        module::<PadModule>(),
        module::<XYPadModule>(),
        module::<Display>(),

        // Effects
        module::<Hold>(),
        module::<Bend>(),
        module::<Slew>(),
        module::<Slope>(),
        module::<Toggle>(),
        module::<Counter>(),
        module::<Multiplexer>(),

        // Logic
        module::<And>(),
        module::<Or>(),
        module::<Not>(),
        module::<Xor>(),

        // Operations
        module::<Add>(),
        module::<Subtract>(),
        module::<Multiply>(),
        module::<Divide>(),
        module::<Modulo>(),
        module::<Negative>(),
        module::<Clamp>(),

        // Comparisons
        module::<Equal>(),
        module::<NotEqual>(),
        module::<Less>(),
        module::<LessEqual>(),
        module::<Greater>(),
        module::<GreaterEqual>(),
    ]
};

#[no_mangle]
pub extern fn export_plugin() -> *const Plugin {
    &PLUGIN
}