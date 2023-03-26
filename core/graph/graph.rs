use std::mem::swap;
use std::rc::Rc;
use std::sync::Mutex;

use serde::de::{self, MapAccess, SeqAccess, Visitor};
use serde::{ser::*, Deserialize, Deserializer, Serialize, Serializer};
use std::fmt;

use crate::plugins::*;
use crate::processor::*;

use modules::*;

static mut CURRENT_ID: i32 = 1;

#[derive(Serialize, Deserialize, Clone)]
pub struct Connection {
    pub module_id: i32,
    pub pin_index: i32,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct Connector {
    pub start: Connection,
    pub end: Connection,
}

/* Node */

pub struct Node {
    pub id: i32,
    pub position: (i32, i32),
    pub module: Box<dyn PolyphonicModule>,
}

impl Serialize for Node {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut state = serializer.serialize_struct("Node", 3)?;
        state.serialize_field("node_id", &self.id)?;
        state.serialize_field("module_id", &self.module.module_id())?;
        state.serialize_field("position", &self.position)?;
        state.serialize_field("version", &self.info().version)?;

        let mut module_state = State::new();
        self.module.save(&mut module_state);

        state.serialize_field("state", &module_state)?;
        state.end()
    }
}

impl<'de> Deserialize<'de> for Node {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        enum Field {
            NodeId,
            ModuleId,
            Position,
            Version,
            State,
        }

        impl<'de> Deserialize<'de> for Field {
            fn deserialize<D>(deserializer: D) -> Result<Field, D::Error>
            where
                D: Deserializer<'de>,
            {
                struct FieldVisitor;

                impl<'de> Visitor<'de> for FieldVisitor {
                    type Value = Field;

                    fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                        formatter.write_str("`id` or `position` or `name` or `state`")
                    }

                    fn visit_str<E>(self, value: &str) -> Result<Field, E>
                    where
                        E: de::Error,
                    {
                        match value {
                            "node_id" => Ok(Field::NodeId),
                            "module_id" => Ok(Field::ModuleId),
                            "position" => Ok(Field::Position),
                            "version" => Ok(Field::Version),
                            "state" => Ok(Field::State),
                            _ => Err(de::Error::unknown_field(value, FIELDS)),
                        }
                    }
                }

                deserializer.deserialize_identifier(FieldVisitor)
            }
        }

        struct NodeVisitor;

        impl<'de> Visitor<'de> for NodeVisitor {
            type Value = Node;

            fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
                formatter.write_str("struct Node")
            }

            fn visit_seq<V>(self, mut _seq: V) -> Result<Node, V::Error>
            where
                V: SeqAccess<'de>,
            {
                /*let id = seq.next_element()?
                    .ok_or_else(|| de::Error::invalid_length(0, &self))?;
                let position = seq.next_element()?
                    .ok_or_else(|| de::Error::invalid_length(1, &self))?;
                let name = seq.next_element()?
                    .ok_or_else(|| de::Error::invalid_length(2, &self))?;
                let state = seq.next_element()?
                    .ok_or_else(|| de::Error::invalid_length(3, &self))?;
                    */

                panic!("Should load module here");
                //let mut module = Modules::new(name).expect("Failed to find module by name");
                //module.load(&state);

                //let info = module.info();

                //Ok(Node { id, position, module })
            }

            fn visit_map<V>(self, mut map: V) -> Result<Node, V::Error>
            where
                V: MapAccess<'de>,
            {
                let mut node_id: Option<i32> = None;
                let mut module_id: Option<String> = None;
                let mut position: Option<(i32, i32)> = None;
                let mut version: Option<String> = None;
                let mut state: Option<State> = None;

                while let Some(key) = map.next_key()? {
                    match key {
                        Field::NodeId => {
                            if node_id.is_some() {
                                return Err(de::Error::duplicate_field("node_id"));
                            }
                            node_id = Some(map.next_value()?);
                        }
                        Field::ModuleId => {
                            if module_id.is_some() {
                                return Err(de::Error::duplicate_field("module_id"));
                            }
                            module_id = Some(map.next_value()?);
                        }
                        Field::Position => {
                            if position.is_some() {
                                return Err(de::Error::duplicate_field("position"));
                            }
                            position = Some(map.next_value()?);
                        }
                        Field::Version => {
                            if version.is_some() {
                                return Err(de::Error::duplicate_field("version"));
                            }
                            version = Some(map.next_value()?);
                        }
                        Field::State => {
                            if state.is_some() {
                                return Err(de::Error::duplicate_field("state"));
                            }
                            state = Some(map.next_value()?);
                        }
                    }
                }

                let node_id = node_id.ok_or_else(|| de::Error::missing_field("node_id"))?;
                let module_id = module_id.ok_or_else(|| de::Error::missing_field("module_id"))?;
                let position = position.ok_or_else(|| de::Error::missing_field("position"))?;
                let version = version.ok_or_else(|| de::Error::missing_field("version"))?;
                let state = state.ok_or_else(|| de::Error::missing_field("state"))?;

                let module_specs = get_modules();
                for module in &module_specs {
                    if module.id == module_id {
                        let mut module = module.create();
                        module.load(&version, &state);

                        let node = Node {
                            id: node_id,
                            position,
                            module
                        };

                        return Ok(node);
                    }
                }

                panic!("Couldn't find module");
            }
        }

        const FIELDS: &'static [&'static str] = &["node_id", "module_id", "position", "name", "state"];
        deserializer.deserialize_struct("Node", FIELDS, NodeVisitor)
    }
}

impl Node {
    pub fn new(module: Box<dyn PolyphonicModule>) -> Self {
        unsafe {
            CURRENT_ID += 1;
        }

        return Node {
            id: unsafe { CURRENT_ID },
            position: (100, 100),
            module: module,
        };
    }

    pub fn info(&self) -> Info {
        self.module.info()
    }

    pub fn set_position(&self, _x: i32, _y: i32) {}
}

impl PartialEq for Node {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

/* Graph */

#[derive(Serialize, Deserialize)]
pub struct Graph {
    pub nodes: Vec<Rc<Node>>,
    pub connectors: Vec<Connector>,
    #[serde(skip_serializing, skip_deserializing)]
    pub nodes_updated: Option<Vec<Rc<Node>>>,
    #[serde(skip_serializing, skip_deserializing)]
    pub processor: GraphProcessor,
    #[serde(skip_serializing, skip_deserializing)]
    pub updated: Mutex<Option<GraphProcessor>>,
    #[serde(skip_serializing, skip_deserializing)]
    pub block_size: usize,
    #[serde(skip_serializing, skip_deserializing)]
    pub sample_rate: u32,
    #[serde(skip_serializing, skip_deserializing)]
    pub modules: ModuleList,
    #[serde(skip_serializing, skip_deserializing)]
    pub plugins: Plugins,
}

pub struct ModuleList {
    pub modules: Vec<ModuleSpec>,
}

impl Default for ModuleList {
    fn default() -> Self {
        Self {
            modules: get_modules()
        }
    }
}

impl Graph {
    pub fn new() -> Self {
        let nodes = Vec::new();
        let connectors = Vec::new();
        let processor = GraphProcessor::new(&nodes, &connectors, 256, 44100);

        return Graph {
            nodes,
            nodes_updated: None,
            connectors,
            processor,
            updated: Mutex::new(None),
            block_size: 256,
            sample_rate: 44100,
            modules: ModuleList::default(),
            plugins: Plugins::new(),
        };
    }

    pub fn add_module2(&mut self, module: Box<dyn PolyphonicModule>) -> Rc<Node> {
        let node = Rc::new(Node::new(module));
        self.nodes.push(node.clone());
        self.refresh();
        return node;
    }

    pub fn add_module(&mut self, id: &str) -> bool {
        println!("[Rust] Adding module {}", id);

        for module in &self.modules.modules {
            if module.id == id {
                let mut manager = module.create();
                manager.prepare(self.sample_rate, self.block_size);
                self.nodes.push(Rc::new(Node::new(manager)));
                self.refresh();
                return true;
            }
        }

        if let Some(mut module) = self.plugins.create_module(id) {
            module.prepare(self.sample_rate, self.block_size);
            self.nodes.push(Rc::new(Node::new(module)));
            self.refresh();
            return true;
        }

        println!("Couldn't add module {}", id);

        return false;
    }

    pub fn remove_module(&mut self, id: i32) {
        self.nodes.retain(|node| node.id != id);
        self.connectors
            .retain(|c| c.start.module_id != id && c.end.module_id != id);
        self.refresh();
    }

    pub fn add_connector(&mut self, connector: Connector) -> bool {
        self.connectors.push(connector);
        self.refresh();
        return true;
    }

    pub fn remove_connector(&mut self, id: i32, index: i32) {
        self.connectors
            .retain(|c| !(c.start.module_id == id && c.start.pin_index == index));

        self.connectors
            .retain(|c| !(c.end.module_id == id && c.end.pin_index == index));

        self.refresh();
    }

    /*pub fn hot_reload(&mut self) {
        let mut nodes = Vec::new();

        let mut graph_equal = true;

        for node in &self.nodes {
            if node.module.should_rebuild() {
                let info1 = &node.info(); // These get the same value
                let info2 = &node.module.info(); // PROBLEM


                let mut node_equal = false;

                if info1.name == info2.name
                    && info1.color as i32 == info2.color as i32
                    && info1.size == info2.size
                    && info1.multi_voice == info2.multi_voice
                    && info1.inputs.len() == info2.inputs.len()
                    && info1.outputs.len() == info2.outputs.len() {

                    node_equal = true;

                    for (i1, i2) in info1.inputs.iter().zip(info2.inputs.iter()) {
                        let mut equal2 = false;

                        match (i1, i2) {
                            (Pin::Audio(a, b), Pin::Audio(c, d)) => {
                                if a == c && b == d {
                                    equal2 = true;
                                }
                            },
                            (Pin::Notes(a, b), Pin::Notes(c, d)) => {
                                if a == c && b == d {
                                    equal2 = true;
                                }
                            },
                            (Pin::Control(a, b), Pin::Control(c, d)) => {
                                if a == c && b == d {
                                    equal2 = true;
                                }
                            },
                            _ => (),
                        }

                        if !equal2 {
                            node_equal = false;
                        }
                    }
                }

                if node_equal {
                    nodes.push(node.clone());
                } else {
                    println!("Detected change in info, rebuilding graph");
                    graph_equal = false;
                }
            }

            if !graph_equal {
                // Set stuff here
            }
        }
    }*/

    pub fn refresh(&mut self) {
        *self.updated.lock().unwrap() = Some(GraphProcessor::new(
            &self.nodes,
            &self.connectors,
            self.block_size,
            self.sample_rate,
        ));
    }

    pub fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        println!("Preparing graph {} {}", sample_rate, block_size);
        self.sample_rate = sample_rate;
        self.block_size = block_size;

        self.plugins.prepare(sample_rate, block_size);

        self.refresh();
    }

    pub fn preprocess(&mut self) {
        match self.updated.try_lock() {
            Ok(mut processor) => {
                if let Some(p) = &mut *processor {
                    println!("Graph buffer swapping");
                    swap(&mut self.processor, p);
                    *processor = None;

                    /*for n in &mut self.nodes {
                        unsafe {
                            let const_ptr = n.module.as_ref() as *const dyn PolyphonicModule;
                            let mut_ptr = const_ptr as *mut dyn PolyphonicModule;
                            let mut_ref = &mut *mut_ptr;
                            let connected = mut_ref.get_connected();

                            for c in connected {
                                *c = false;
                            }

                        }
                    }

                    for c in &self.connectors {
                        for n in &mut self.nodes {
                            if c.end.module_id == n.id {
                                unsafe {
                                    let const_ptr = n.module.as_ref() as *const dyn PolyphonicModule;
                                    let mut_ptr = const_ptr as *mut dyn PolyphonicModule;
                                    let mut_ref = &mut *mut_ptr;
                                    let connected = mut_ref.get_connected();
                                    connected[c.end.pin_index as usize] = true;
                                }
                            }

                            if c.start.module_id == n.id {
                                unsafe {
                                    let const_ptr = n.module.as_ref() as *const dyn PolyphonicModule;
                                    let mut_ptr = const_ptr as *mut dyn PolyphonicModule;
                                    let mut_ref = &mut *mut_ptr;
                                    let connected = mut_ref.get_connected();
                                    connected[c.start.pin_index as usize] = true;
                                }
                            }
                        }
                    }
                    */
                }
            }
            Err(_) => (),
        }
    }

    pub fn process(
        &mut self,
        time: &TimeMessage,
        audio: &mut [AudioBuffer],
        midi: &mut NoteBuffer,
    ) {
        self.preprocess();

        // self.plugins.update();

        self.processor.process(time, audio, midi);
    }
}
