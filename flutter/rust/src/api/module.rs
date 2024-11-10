use cmajor_rs::*;

use flutter_rust_bridge::*;

use crate::api::node::Node;

#[frb(opaque)]
pub struct Module {
    path: String,
    name: String,
    version: String,
    category: Vec<String>,
    description: String,
    program: Program
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
            .to_string()];

        let mut program = Program::new();
        let mut messages = DiagnosticMessageList::new();
        let parent = std::path::Path::new(path.as_str()).parent().unwrap();
        for source in &sources {
            let path = parent.join(source);
            let contents = std::fs::read_to_string(path).unwrap();
            if (!program.parse(&mut messages, &contents, source)) {
                println!("Parse failed");
                return None;
            }
        }

        Some(Self {
            path,
            name,
            version,
            category,
            description,
            program
        })
    }

    #[frb(sync, getter)]
    pub fn get_path(&self) -> String {
        self.path.clone()
    }

    #[frb(sync, getter)]
    pub fn get_name(&self) -> String {
        self.name.clone()
    }

    #[frb(sync, getter)]
    pub fn get_category(&self) -> Vec<String> {
        self.category.clone()
    }

    #[frb(sync, getter)]
    pub fn get_description(&self) -> String {
        self.description.clone()
    }

    #[frb(sync, getter)]
    pub fn get_color(&self) -> u32 {
        0xFF0000
    }

    #[frb(sync)]
    pub fn create_node(&self) -> Node {
        Node::from(self)
    }
}
