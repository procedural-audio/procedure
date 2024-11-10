pub mod cable;
pub mod endpoint;
pub mod graph;
pub mod module;
pub mod node;

use flutter_rust_bridge::*;

#[frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

#[frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}