use super::endpoint::*;
use super::module::*;

use std::sync::{Arc, Mutex, RwLock};

use flutter_rust_bridge::*;

#[frb(opaque)]
#[derive(Clone)]
pub struct Node {
    pub id: u32,
    pub module: Module,
    pub position: (f64, f64),
    inputs: Vec<NodeEndpoint>,
    outputs: Vec<NodeEndpoint>,
    performer: Arc<Mutex<cmajor::performer::Performer>>,
}

impl PartialEq for Node {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl Node {
    #[frb(sync)]
    pub fn from(id: u32, module: Module, position: (f64, f64)) -> Option<Self> {
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
            let endpoint = NodeEndpoint::from(&mut engine, info, id);
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
            id,
            module,
            position,
            inputs,
            outputs,
            performer,
        })
    }

    #[frb(sync, getter)]
    pub fn get_inputs(&self) -> Vec<NodeEndpoint> {
        self.inputs.clone()
    }

    #[frb(sync, getter)]
    pub fn get_outputs(&self) -> Vec<NodeEndpoint> {
        self.outputs.clone()
    }

    #[frb(ignore)]
    pub fn clone_performer(&self) -> Arc<Mutex<cmajor::performer::Performer>> {
        self.performer.clone()
    }
}
