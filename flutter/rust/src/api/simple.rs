use flutter_rust_bridge::frb;
use tokio;

use cmajor_rs::*;

#[frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

#[frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[frb(opaque)]
pub struct RawPatch {
    pub patch: Box<usize>,
}

impl RawPatch {
    #[frb(sync)]
    pub fn new() -> Self {
        Self {
            patch: Box::new(0),
        }
    }

    #[frb(dart_async)]
    pub async fn load(path: &str) -> Option<Self> {
        tokio::fs::read(path)
            .await
            .map(|patch| Self {
                patch: Box::new(patch.len()),
            })
            .ok()
    }

    #[frb(sync)]
    pub fn process(&mut self) {
        // Process the patch
    }
}

#[frb(opaque)]
pub struct CmajorLibrary {
    library: Box<Library>
}

impl CmajorLibrary {
    #[frb(sync)]
    pub fn load(path: &str) {
        Library::load(path);
    }
}

#[frb(opaque)]
pub struct CmajorProgram {
    program: Box<Program>
}

impl CmajorProgram {
    #[frb(sync)]
    pub fn new() -> Self {
        Self {
            program: Box::new(Program::new())
        }
    }

    #[frb(sync)]
    pub fn parse(&mut self, path: &str, contents: &str) -> bool {
        let mut messages = DiagnosticMessageList::new();
        let status = self.program.parse(&mut messages, path, contents);

        for (i, message) in messages.messages.iter().enumerate() {
            println!("{}: {}", i, message.get_full_description());
        }

        return status;
    }
}