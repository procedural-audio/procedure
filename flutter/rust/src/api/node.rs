use cmajor::*;
use cmajor::performer::*;
use cmajor::endpoint::*;

use flutter_rust_bridge::*;

use crate::api::endpoint::Endpoint;

use std::sync::{Arc, RwLock};

/// This is a single processor unit in the graph
#[derive(Clone)]
#[frb(opaque)]
pub struct Node {
    inputs: Vec<Endpoint>,
    outputs: Vec<Endpoint>,
    performer: Arc<RwLock<Performer>>,
}

impl Node {
    #[frb(sync)]
    pub fn from(sources: &Vec<String>) -> Self {
        let cmajor = Cmajor::new_from_path("/Users/chasekanipe/Github/cmajor-build/x64/libCmajPerformer.dylib").unwrap();

        let mut program = cmajor.create_program();
        for source in sources {
            program
                .parse(source)
                .unwrap();
        }

        let mut engine = cmajor
            .create_default_engine()
            .build()
            .load(&program)
            .unwrap();

        let infos: Vec<EndpointInfo> = engine
            .program_details()
            .endpoints()
            .collect();

        let mut inputs = Vec::new();
        let mut outputs = Vec::new();

        for info in infos {
            let is_input = info.direction() == EndpointDirection::Input;
            match Endpoint::from(&mut engine, info) {
                Ok(endpoint) => {
                    if is_input {
                        inputs.push(endpoint);
                    } else {
                        outputs.push(endpoint);
                    }
                },
                Err(e) => println!("{}", e),
            }
        }

        let performer = engine
            .link()
            .unwrap()
            .performer();

        Self { inputs, outputs, performer: Arc::new(RwLock::new(performer)) }
    }

    #[frb(sync, getter)]
    pub fn get_inputs(&self) -> Vec<Endpoint> {
        self.inputs.clone()
    }

    #[frb(sync, getter)]
    pub fn get_outputs(&self) -> Vec<Endpoint> {
        self.outputs.clone()
    }
}
