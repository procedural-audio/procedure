use cmajor::*;
use cmajor::endpoint::EndpointInfo;

use flutter_rust_bridge::*;

use std::ffi::c_void;
use std::sync::Mutex;

use crate::api::node::Node;
use crate::api::endpoint::*;

#[frb(opaque)]
pub struct Module {
    path: String,
    name: String,
    version: String,
    category: Vec<String>,
    description: String,
    // program: Mutex<Program>,
    width: u32,
    height: u32,
    inputs: Vec<Endpoint>,
    outputs: Vec<Endpoint>
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

        let cmajor = Cmajor::new_from_path("/Users/chasekanipe/Github/cmajor-build/x64/libCmajPerformer.dylib").unwrap();

        let mut program = cmajor.create_program();
        let parent = std::path::Path::new(path.as_str()).parent().unwrap();

        for source in &sources {
            let path = parent.join(source);
            let contents = std::fs::read_to_string(path).unwrap();
            program.parse(&contents).unwrap();
        }

        let mut engine = cmajor
            .create_default_engine()
            .build();

        engine.load(&program).unwrap();

        let mut inputs = Vec::new();
        let mut outputs = Vec::new();

        /*for endpoint in engine.get_input_endpoints() {
            inputs.push(EndpointInfo::from(&endpoint)); 
        }

        for endpoint in engine.get_output_endpoints() {
            outputs.push(EndpointInfo::from(&endpoint)); 
        }*/

        // let details = engine.get_program_details();
        // println!("Details: {}", details);

        let width = 300;
        let height = 200;


        Some(Self {
            path,
            name,
            version,
            category,
            description,
            // program: Mutex::new(program),
            width,
            height,
            inputs,
            outputs
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

    #[frb(sync, getter)]
    pub fn get_width(&self) -> u32 {
        self.width
    }

    #[frb(sync, getter)]
    pub fn get_height(&self) -> u32 {
        self.height
    }

    #[frb(sync, getter)]
    pub fn get_inputs(&self) -> Vec<Endpoint> {
        self.inputs.clone()
    }

    #[frb(sync, getter)]
    pub fn get_outputs(&self) -> Vec<Endpoint> {
        self.outputs.clone()
    }

    #[frb(sync)]
    pub fn create_node(&self) -> Node {
        Node::from(self)
    }
}

/*fn get_external_variable(v: &ExternalVariable) -> Value {
    println!("Get external variable");
    todo!()
}

fn get_external_function(s: *const i8, ts: Span<Type>) -> *const c_void {
    println!("Get external function");
    todo!()
}*/