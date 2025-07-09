use cmajor::endpoint::*;
use cmajor::engine::{Engine, Error, Linked, Loaded};
use cmajor::performer::*;
use cmajor::*;
use endpoints::stream::StreamType;
use value::ValueRef;

use super::endpoint::*;

use cmajor::performer::endpoints::value::{GetOutputValue, SetInputValue};

use std::f32::consts::E;
use std::sync::{Arc, Mutex, RwLock};

use crate::other::voices::*;
use flutter_rust_bridge::*;

/// This is a single processor unit in the graph
#[frb(opaque)]
#[derive(Clone)]
pub struct Node {
    pub id: u32,
    source: Vec<String>,
    inputs: Vec<NodeEndpoint>,
    outputs: Vec<NodeEndpoint>,
    performer: Arc<Mutex<Performer>>,
}

impl PartialEq for Node {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl Node {
    #[frb(sync)]
    pub fn from(source: Vec<String>, id: u32) -> Option<Self> {
        let cmajor = Cmajor::new_from_path(
            "/Users/chase/Code/nodus/flutter/build/libCmajPerformer.dylib",
        )
        .unwrap();

        let mut program = cmajor.create_program();
        for source in &source {
            if let Err(e) = program.parse(source) {
                println!("{}", e);
            }
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
                    Error::FailedToLoad(_engine, message) => {
                        println!("{}", message);
                    }
                    _ => println!("{}", e),
                }

                return None;
            }
        };

        let infos: Vec<EndpointInfo> = engine.program_details().endpoints().collect();

        let mut inputs = Vec::new();
        let mut outputs = Vec::new();

        for info in infos {
            let is_input = info.direction() == EndpointDirection::Input;
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
                    Error::FailedToLink(_engine, message) => {
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
            source,
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
    pub fn get_performer(&self) -> Arc<Mutex<Performer>> {
        self.performer.clone()
    }
}
