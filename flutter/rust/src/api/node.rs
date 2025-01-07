use cmajor::*;
use cmajor::performer::*;
use cmajor::endpoint::*;

use std::sync::mpsc::*;
use std::sync::{Arc, RwLock, Mutex};

use flutter_rust_bridge::*;

use crate::api::endpoint::Endpoint;

#[derive(Copy, Clone)]
pub struct ParameterChange {
    id: u32
}

pub enum Voices {
    Mono(Performer),
    Poly(Vec<Performer>)
}

/// This is a single processor unit in the graph
#[frb(opaque)]
#[derive(Clone)]
pub struct Node {
    pub id: u32,
    source: String,
    inputs: Vec<Endpoint>,
    outputs: Vec<Endpoint>,
    sender: Sender<ParameterChange>,
    reciever: Arc<Mutex<Receiver<ParameterChange>>>,
    voices: Arc<Mutex<Voices>>,
}

impl Node {
    #[frb(sync)]
    pub fn from(source: &str) -> Self {
        let cmajor = Cmajor::new_from_path("/Users/chasekanipe/Github/cmajor-build/x64/libCmajPerformer.dylib").unwrap();

        let mut program = cmajor.create_program();
        program
            .parse(source)
            .unwrap();

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

        let engine = engine
            .link()
            .unwrap();

        // Allocate a performer for each voice
        let performer = engine.performer();

        let (sender, reciever) = std::sync::mpsc::channel();

        Self {
            id: 0,
            source: source.to_string(),
            inputs,
            outputs,
            sender,
            reciever: Arc::new(Mutex::new(reciever)),
            voices: Arc::new(Mutex::new(Voices::Mono(performer)))
        }
    }

    #[frb(ignore)]
    pub fn prepare(&self, sample_rate: f64, block_size: u32) {
        if let Ok(mut voices) = self.voices.try_lock() {
            match *voices {
                Voices::Mono(ref mut voice) => {
                    voice.set_block_size(block_size);
                },
                Voices::Poly(ref mut voices) => {
                    for voice in voices{
                        voice.set_block_size(block_size);
                    }
                }
            }
        }
    }

    // This method is not mutable
    #[frb(ignore)]
    pub fn process(&self) {
        if let Ok(messages) = self.reciever.try_lock() {
            for msg in messages.try_iter() {
                // Update the parameter on each voice
            }
        }
        
        if let Ok(mut voices) = self.voices.try_lock() {
            match *voices {
                Voices::Mono(ref mut voice) => {
                    voice.advance();
                },
                Voices::Poly(ref mut voices) => {
                    for voice in voices{
                        voice.advance();
                    }
                }
            }
        }
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
    pub fn set_parameter(&self, id: u32, value: f64) {
        self.sender.send(ParameterChange { id }).unwrap();
    }
}
