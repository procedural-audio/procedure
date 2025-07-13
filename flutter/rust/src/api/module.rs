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
        let mut module = Self {
            source: source.clone(),
            title: None,
            title_color: None,
            icon: None,
            icon_size: None,
            icon_color: None,
            size: (1, 1),
        };
        
        // Parse annotations from the source
        module.parse_annotations();
        module
    }
    
    fn parse_annotations(&mut self) {
        // Look for processor or graph definitions with main
        for line in self.source.lines() {
            if (line.contains("processor") || line.contains("graph")) && line.contains("main") {
                // Find annotations between [[ and ]]
                if let Some(start) = line.find("[[") {
                    if let Some(end) = line.find("]]") {
                        let annotations = &line[start + 2..end];
                        // Parse each annotation
                        for element in annotations.split(',') {
                            let element = element.trim();
                            if let Some(colon_pos) = element.find(':') {
                                let key = element[..colon_pos].trim();
                                let value = element[colon_pos + 1..].trim().trim_matches('"');
                                
                                match key {
                                    "width" => {
                                        if let Ok(w) = value.parse::<u32>() {
                                            self.size.0 = w;
                                        }
                                    }
                                    "height" => {
                                        if let Ok(h) = value.parse::<u32>() {
                                            self.size.1 = h;
                                        }
                                    }
                                    "title" => {
                                        self.title = Some(value.to_string());
                                    }
                                    "titleColor" => {
                                        self.title_color = Some(value.to_string());
                                    }
                                    "icon" => {
                                        // For now, just store the icon path
                                        // Loading the actual icon content would be done later
                                        println!("Skipping icon: {}", value);
                                    }
                                    "iconSize" => {
                                        if let Ok(size) = value.parse::<i32>() {
                                            self.icon_size = Some(size);
                                        }
                                    }
                                    "iconColor" => {
                                        self.icon_color = Some(value.to_string());
                                    }
                                    _ => {}
                                }
                            }
                        }
                    }
                }
                break; // Only process the first matching line
            }
        }
    }
}