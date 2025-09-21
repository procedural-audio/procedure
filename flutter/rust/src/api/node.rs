use super::endpoint::*;
use super::module::*;

use std::sync::{Arc, Mutex};

use flutter_rust_bridge::*;
use serde::{Serialize, Deserialize};
use serde_json;

#[frb(opaque)]
#[derive(Clone, Serialize)]
pub struct Node {
    pub id: u32,
    pub module: Module,
    pub position: (f64, f64),
    #[serde(skip)]
    inputs: Vec<NodeEndpoint>,
    #[serde(skip)]
    outputs: Vec<NodeEndpoint>,
    #[serde(skip)]
    performer: Arc<Mutex<cmajor::performer::Performer>>,
}

impl PartialEq for Node {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl Node {
    // Remove the id parameter since we're eliminating ID-based approach
    #[frb(sync)]
    pub fn from_module(module: Module, position: (f64, f64)) -> Option<Self> {
        let cmajor = cmajor::Cmajor::new_from_path(
            "/Users/chase/Code/nodus/flutter/build/libCmajPerformer.dylib",
        )
        .unwrap();

        let mut program = cmajor.create_program();
        if let Err(e) = program.parse(&module.source) {
            println!("{}", e);
        }

        let mut engine = match cmajor
            .create_default_engine()
            .with_sample_rate(44100.0)
            .build()
            .load(&program)
        {
            Ok(engine) => engine,
            Err(e) => {
                match e {
                    cmajor::engine::Error::FailedToLoad(_engine, message) => {
                        println!("{}", message);
                    }
                    _ => println!("{}", e),
                }

                return None;
            }
        };

        let infos = engine.program_details().endpoints().collect::<Vec<_>>();

        let mut inputs = Vec::new();
        let mut outputs = Vec::new();

        for info in infos {
            let is_input = info.direction() == cmajor::endpoint::EndpointDirection::Input;
            let endpoint = NodeEndpoint::from(&mut engine, info, 0); // Temporary ID, will be removed
            if is_input {
                inputs.push(endpoint);
            } else {
                outputs.push(endpoint);
            }
        }

        let engine = match engine.link() {
            Ok(engine) => engine,
            Err(e) => {
                match e {
                    cmajor::engine::Error::FailedToLink(_engine, message) => {
                        println!("{}", message);
                    }
                    _ => println!("{}", e),
                }

                return None;
            }
        };

        let performer = Arc::new(Mutex::new(engine.performer()));

        Some(Self {
            id: 0, // Temporary, will be removed completely
            module,
            position,
            inputs,
            outputs,
            performer,
        })
    }

    #[frb(sync)]
    pub fn to_json(&self) -> String {
        // Only id, module, position will be serialized due to #[serde(skip)]
        serde_json::to_string(self).unwrap_or_else(|_| "{}".to_string())
    }

    #[frb(sync)]
    pub fn from_json(json: String) -> Option<Self> {
        #[derive(Deserialize)]
        struct NodeSerde {
            id: u32,
            module: Module,
            position: (f64, f64),
        }

        let parsed: NodeSerde = match serde_json::from_str(&json) {
            Ok(p) => p,
            Err(_) => return None,
        };

        let mut node = Self::from_module(parsed.module, parsed.position)?;
        node.id = parsed.id;
        Some(node)
    }

    #[frb(sync)]
    pub fn get_inputs(&self) -> Vec<NodeEndpoint> {
        self.inputs.clone()
    }

    #[frb(sync)]
    pub fn get_outputs(&self) -> Vec<NodeEndpoint> {
        self.outputs.clone()
    }

    #[frb(sync)]
    pub fn set_position(&mut self, position: (f64, f64)) {
        self.position = position;
    }

    #[frb(ignore)]
    pub fn clone_performer(&self) -> Arc<Mutex<cmajor::performer::Performer>> {
        self.performer.clone()
    }

    // Check if this node has a specific endpoint (by comparing annotations)
    #[frb(sync)]
    pub fn has_endpoint(&self, endpoint: &NodeEndpoint) -> bool {
        self.inputs.iter().any(|ep| ep.annotation == endpoint.annotation) ||
        self.outputs.iter().any(|ep| ep.annotation == endpoint.annotation)
    }

    // Get an endpoint by its annotation
    #[frb(sync)]
    pub fn get_endpoint_by_annotation(&self, annotation: String) -> Option<NodeEndpoint> {
        self.inputs.iter()
            .chain(self.outputs.iter())
            .find(|ep| ep.annotation == annotation)
            .cloned()
    }

    // Get an input endpoint by its annotation
    #[frb(sync)]
    pub fn get_input_by_annotation(&self, annotation: String) -> Option<NodeEndpoint> {
        self.inputs.iter()
            .find(|ep| ep.annotation == annotation)
            .cloned()
    }

    // Get an output endpoint by its annotation
    #[frb(sync)]
    pub fn get_output_by_annotation(&self, annotation: String) -> Option<NodeEndpoint> {
        self.outputs.iter()
            .find(|ep| ep.annotation == annotation)
            .cloned()
    }

}
