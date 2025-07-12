use flutter_rust_bridge::frb;
use serde::{Serialize, Deserialize};
use cmajor::{endpoint::EndpointInfo, engine::{Engine, Error, Linked, Loaded}, Cmajor};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Module {
    pub source: String,
    pub title: Option<String>,
    pub title_color: Option<String>,
    pub icon: Option<String>,
    pub icon_size: Option<i32>,
    pub icon_color: Option<String>,
    pub size: (u32, u32),
}

impl Module {
    #[frb(sync)]
    pub fn from(source: String) -> Self {
        Self {
            source,
            title: None,
            title_color: None,
            icon: None,
            icon_size: None,
            icon_color: None,
            size: (1, 1),
        }
    }
}