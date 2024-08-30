type Patch = u32;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(sync)]
pub struct RawPatch {
    pub patch: Box<Patch>,
}

impl RawPatch {
    pub fn new() -> Self {
        Self {
            patch: Box::new(0),
        }
    }

    pub fn load(&mut self, path: &str) -> Result<Self, String> {
        Ok(Self::new())
    }

    pub fn process(&mut self) {
        // Process the patch
    }
}
