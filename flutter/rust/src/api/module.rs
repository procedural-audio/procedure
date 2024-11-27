use std::{fs::read_to_string, path::Path};

use flutter_rust_bridge::*;

use crate::api::node::Node;

#[frb(non_opaque)]
pub struct Module {
    pub path: String,
    pub name: String,
    pub version: String,
    pub category: Vec<String>,
    pub description: String,
    pub size: (u32, u32),
    pub color: u32,
    pub sources: Vec<String>
}

impl Module {
    pub fn load(path: &str) -> Option<Self> {
        let contents = std::fs::read_to_string(path).unwrap();
        let value: serde_json::Value = serde_json::from_str(&contents).unwrap();

        let path = path.to_string();
        let name = value["name"]
            .as_str()
            .unwrap_or("Unnamed")
            .to_string();
        let version = value["version"]
            .as_str()
            .unwrap_or("1.0")
            .to_string();
        let category = value["category"]
            .as_str()
            .unwrap_or("Uncategorized")
            .split(".")
            .map(|s| s.to_string())
            .collect();
        let description = value["description"]
            .as_str()
            .unwrap_or("")
            .to_string();
        let sources: Vec<String> = vec![value["source"]
            .as_str()
            .unwrap()
            .to_string()
        ];
    
        let sources: Vec<String> = sources.iter().map(| name | {
            let parent = Path::new(path.as_str()).parent().unwrap();
            let path = parent.join(name);
            read_to_string(path).unwrap()
        }).collect();

        let size = (300, 200);
        let color = 0xFF0000;

        Some(Self {
            path,
            name,
            version,
            category,
            description,
            size,
            color,
            sources
        })
    }

    #[frb(ignore)]
    pub fn get_sources(&self) -> Vec<String> {
        self.sources.clone()
    }

    #[frb(sync)]
    pub fn create_node(&self) -> Node {
        Node::from(&self.sources)
    }
}
