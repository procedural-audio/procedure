use cmajor::*;
use cmajor::performer::*;
use cmajor::endpoint::*;

use flutter_rust_bridge::*;

use crate::api::endpoint::Endpoint;

/// This is a single processor unit in the graph
// #[derive(Clone)]
#[frb(non_opaque)]
pub struct Node {
    pub inputs: Vec<Endpoint>,
    pub outputs: Vec<Endpoint>
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
            let id = info.id();
            let is_input = info.direction() == EndpointDirection::Input;

            if is_input {
                inputs.push(Endpoint::from(info));
            } else {
                outputs.push(Endpoint::from(info));
            }
        }

        let performer = engine
            .link()
            .unwrap()
            .performer();

        Self { inputs, outputs }
    }
}
