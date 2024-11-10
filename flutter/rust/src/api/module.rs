use cmajor_rs::*;

use flutter_rust_bridge::*;

use crate::api::node::Node;

#[frb(opaque)]
pub struct Module {
    name: String    
}

impl Module {
    pub fn load(path: &str) -> Self {
        Self {
            name: path.to_string()
        }
    }

    pub fn create_node(&self) -> Node {
        todo!()
    }
}