use cmajor_rs::*;

use flutter_rust_bridge::*;

use std::{collections::HashMap, ffi::c_void};

use crate::api::cable::Cable;
use crate::api::endpoint::Endpoint;
use crate::api::module::Module;

/// This is a single processor unit in the graph
// #[derive(Clone)]
#[frb(opaque)]
pub struct Node {
    id: u32,
    /*performer: Performer,
    inputs: Vec<Endpoint>,
    outputs: Vec<Endpoint>,
    block_size: usize*/
}

impl Node {
    pub fn from(module: &Module) -> Self {
        Self {
            id: 0
        }
    }

    // Creates as new node from a module specification
    /*pub fn create(id: u32, settings: &BuildSettings, program: &Program) -> Result<Self, String> {
        let mut engine = Engine::create("").unwrap();

        engine.set_build_settings(settings);

        let mut messages = DiagnosticMessageList::new();
        if !engine.load(&mut messages, program, get_external_variable, get_external_function) {
            return Err("Failed to load engine".to_string());
        }

        if !engine.link(&mut messages, None) {
            return Err("Failed to link engine".to_string());
        }

        let mut inputs = Vec::new();
        let mut outputs = Vec::new();

        for details in &engine.get_input_endpoints() {
            let annotation = details
                .annotation
                .clone()
                .unwrap_or(serde_json::Value::String(String::new()));

            println!(" > Found input handle \'{}\' {} {}", details.id, details.ty, annotation);
            // let handle = engine.get_endpoint_handle(&details.id).unwrap();
            // inputs.push(Endpoint::new(handle, details));
        }

        for details in &engine.get_output_endpoints(){
            let annotation = details
                .annotation
                .clone()
                .unwrap_or(serde_json::Value::String(String::new()));
            
            println!(" > Found output handle \'{}\' {} {}", details.id, details.ty, annotation);
            // let handle = engine.get_endpoint_handle(&details.id).unwrap();
            // outputs.push(Endpoint::new(handle, details));
        }

        let performer = engine.create_performer()?;

        Ok(Self {
            id,
            performer,
            inputs,
            outputs,
            block_size: 0
        })
    }*/

    /*pub fn get_id(&self) -> u32 {
        self.id
    }

    pub fn get_input_endpoints(&self) -> Vec<Endpoint> {
        self.inputs.clone()
    }

    pub fn get_output_endpoints(&self) -> Vec<Endpoint> {
        self.outputs.clone()
    }

    pub fn prepare(&mut self, block_size: u32) {
        self.performer.set_block_size(block_size);
        self.block_size = block_size as usize;
    }

    pub fn process(&mut self, endpoint_type: EndpointType) {
        // Do some performer processing
    }*/
}

fn handle(
    context: *const c_void,
    generated_code: *const i8,
    generated_code_size: usize,
    main_class_name: *const i8,
    message_list_json: *const i8,
) {
    println!("Generate code callback");
}

fn get_external_variable(v: &ExternalVariable) -> Value {
    println!("Get external variable");
    todo!()
}

fn get_external_function(s: *const i8, ts: Span<Type>) -> *const c_void {
    println!("Get external function");
    todo!()
}

#[no_mangle]
extern "C" fn cosf(f: f32) -> f32 {
    f32::cos(f)
}

#[no_mangle]
extern "C" fn powf(f: f32, n: f32) -> f32 {
    f32::powf(f, n)
}
