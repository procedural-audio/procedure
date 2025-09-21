use flutter_rust_bridge::frb;
use serde::{Serialize, Deserialize};
use std::fs;
use std::path::{Path, PathBuf};
use cmajor::{endpoint::EndpointInfo, engine::{Engine, Error, Linked, Loaded}, Cmajor};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Module {
    pub source: String,
    pub name: Option<String>,
    pub category: Vec<String>,
    pub title: Option<String>,
    pub color: Option<String>,
    pub menu_icon: Option<String>,
    pub module_icon: Option<String>,
    pub size: (u32, u32),
}

impl Module {
    #[frb(sync)]
    pub fn from(source: String) -> Self {
        let mut module = Self {
            source: source.clone(),
            name: None,
            category: Vec::new(),
            title: None,
            color: None,
            menu_icon: None,
            module_icon: None,
            size: (1, 1),
        };
        
        // Parse annotations from the source
        module.parse_annotations(None);
        module
    }
    
    fn parse_annotations(&mut self, base_dir: Option<&Path>) {
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
                                    "color" => {
                                        self.color = Some(value.to_string());
                                    }
                                    "menuIcon" => {
                                        if let Some(dir) = base_dir {
                                            let p = dir.join(value);
                                            if let Ok(svg) = fs::read_to_string(&p) {
                                                self.menu_icon = Some(svg);
                                            }
                                        }
                                        if self.menu_icon.is_none() {
                                            self.menu_icon = Some(value.to_string());
                                        }
                                    }
                                    "moduleIcon" => {
                                        if let Some(dir) = base_dir {
                                            let p = dir.join(value);
                                            if let Ok(svg) = fs::read_to_string(&p) {
                                                self.module_icon = Some(svg);
                                            }
                                        }
                                        if self.module_icon.is_none() {
                                            self.module_icon = Some(value.to_string());
                                        }
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

    // Load a module from a file path; category is supplied by caller
    #[frb]
    pub async fn load(path: String, category: Vec<String>) -> Result<Self, String> {
        let path_buf = PathBuf::from(&path);
        let base_dir = path_buf.parent().ok_or_else(|| "Invalid path".to_string())?;
        let source = fs::read_to_string(&path_buf).map_err(|e| e.to_string())?;

        // Derive name from filename; category comes from argument
        let name = path_buf
            .file_stem()
            .and_then(|s| s.to_str())
            .map(|s| s.to_string());

        let mut module = Self {
            source,
            name,
            category,
            title: None,
            color: None,
            menu_icon: None,
            module_icon: None,
            size: (1, 1),
        };

        module.parse_annotations(Some(base_dir));
        Ok(module)
    }
}