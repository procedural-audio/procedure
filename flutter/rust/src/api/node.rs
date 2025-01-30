use cmajor::*;
use cmajor::engine::{Engine, Loaded, Linked, Error};
use cmajor::endpoint::*;
use cmajor::performer::*;
use endpoints::stream::StreamType;
use value::ValueRef;

use super::endpoint::*;

use cmajor::performer::endpoints::value::{GetOutputValue, SetInputValue};

use std::f32::consts::E;
use std::sync::{Arc, RwLock, Mutex};

use flutter_rust_bridge::*;
use super::voices::*;

/// This is a single processor unit in the graph
#[frb(opaque)]
#[derive(Clone)]
pub struct Node {
    pub id: u32,
    source: String,
    inputs: Vec<NodeEndpoint>,
    outputs: Vec<NodeEndpoint>,
    voices: Arc<Mutex<Voices>>,
}

impl PartialEq for Node {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl Node {
    #[frb(sync)]
    pub fn from(source: &str, id: u32) -> Option<Self> {
        let cmajor = Cmajor::new_from_path("/Users/chasekanipe/Github/cmajor-build/x64/libCmajPerformer.dylib").unwrap();

        let mut program = cmajor.create_program();
        if let Err(e) = program.parse(source) {
            println!("{}", e);
            return None;
        }

        let mut engine = match cmajor
            .create_default_engine()
            .build()
            .load(&program) {
                Ok(engine) => engine,
                Err(e) => {
                    match e {
                        Error::FailedToLoad(_engine, message) => {
                            println!("{}", message);
                        },
                        _ => println!("{}", e),
                    }

                    return None;
                }
            };

        let infos: Vec<EndpointInfo> = engine
            .program_details()
            .endpoints()
            .collect();

        let mut inputs = Vec::new();
        let mut outputs = Vec::new();

        for info in infos {
            let is_input = info.direction() == EndpointDirection::Input;
            match NodeEndpoint::from(&mut engine, info, id) {
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

        let engine = match engine
            .link() {
                Ok(engine) => engine,
                Err(e) => {
                    match e {
                        Error::FailedToLink(_engine, message) => {
                            println!("{}", message);
                        },
                        _ => println!("{}", e),
                    }

                    return None;
                }
            };

        let voices = if id == 0 {
            Arc::new(Mutex::new(Voices::Mono(engine.performer())))
        } else {
            Arc::new(Mutex::new(Voices::Mono(engine.performer())))
        };

        Some(
            Self {
                id,
                source: source.to_string(),
                inputs,
                outputs,
                voices
            }
        )
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
    pub fn voices(&self) -> Arc<Mutex<Voices>> {
        self.voices.clone()
    }
}
