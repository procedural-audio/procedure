pub mod cable;
pub mod endpoint;
pub mod graph;
pub mod node;

use cmajor::*;

pub use std::sync::{Arc, Mutex};
pub use cmajor::performer::Performer;

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
