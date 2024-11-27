use cmajor::*;
use cmajor::performer::*;
use cmajor::endpoint::*;

use flutter_rust_bridge::*;
use performer::{InputEvent, InputStream, OutputEvent, OutputStream};
use value::types::{Primitive, Type};

use cmajor::endpoint::*;

use std::{collections::HashMap, ffi::c_void};

use crate::api::cable::Cable;
use crate::api::endpoint::Endpoint;
use crate::api::module::Module;

/// This is a single processor unit in the graph
// #[derive(Clone)]
#[frb(opaque)]
pub struct Node {
    inputs: Vec<Endpoint>,
    outputs: Vec<Endpoint>
}

impl Node {
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

            match info {
                EndpointInfo::Stream(endpoint) => {
                    match endpoint.ty() {
                        Type::Primitive(primitive) => match primitive {
                            Primitive::Float32 => (),
                            Primitive::Void => todo!(),
                            Primitive::Bool => todo!(),
                            Primitive::Int32 => todo!(),
                            Primitive::Int64 => todo!(),
                            Primitive::Float64 => todo!(),
                        },
                        Type::String => todo!(),
                        Type::Array(array) => todo!(),
                        Type::Object(object) => todo!(),
                    }
                },
                EndpointInfo::Event(event_endpoint) => {
                },
                EndpointInfo::Value(value_endpoint) => {
                },
            }
        }

        let performer = engine
            .link()
            .unwrap()
            .performer();

        Self { inputs, outputs }
    }
}
