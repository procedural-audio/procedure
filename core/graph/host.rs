use pa_dsp::*;

use nodio::{IOManager, AudioPluginManager};
use crate::graph::*;

use std::sync::Arc;

pub struct Host {
    pub graph: Graph,
    pub sample_rate: u32,
    pub block_size: usize,
    pub time: TimeMessage,
    pub bpm: f64,
    pub io_manager: Option<IOManager>,
    pub plugin_manager: Arc<AudioPluginManager>
}

impl Host {
    pub fn new() -> Self {
        Host {
            graph: Graph::new(),
            block_size: 128,
            sample_rate: 44100,
            time: TimeMessage::from(0.0, 0.0),
            bpm: 120.0,
            io_manager: None,
            plugin_manager: Arc::new(AudioPluginManager::new())
        }
    }

    pub fn load(&mut self, path: &str) {
        println!("Loading graph from {}", path);

        let path = path.to_string();
        let data = std::fs::read_to_string(path).unwrap();

        match serde_json::from_str(&data) {
            Ok(graph) => {
                let mut graph: Graph = graph;

                graph.refresh();
                self.graph = graph;
            }
            Err(e) => {
                self.graph.nodes.clear();
                self.graph.nodes.clear();
                self.graph.refresh();
                println!("Failed to decode graph {}", e);
            }
        }
    }

    pub fn save(&self, path: &str) {
        let path = path.to_string();
        let json = serde_json::to_string(&self.graph).unwrap();
        std::fs::write(path.clone(), &json).unwrap();
        println!("Saved graph to {}", path);
        println!("{}", json);
    }

    pub fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        self.sample_rate = sample_rate;
        self.block_size = block_size as usize;
        self.graph.prepare(sample_rate, block_size);

        let delta_beats = self.bpm / 60.0 / self.sample_rate as f64 * self.block_size as f64;
        self.time = TimeMessage::from(0.0, delta_beats);
    }

    pub fn process(&mut self, audio: &mut [AudioBuffer], midi: &mut NoteBuffer) {
        self.graph.process(&self.time, audio, midi);
        let delta_beats = self.bpm / 60.0 / self.sample_rate as f64 * self.block_size as f64;
        self.time = self.time.shift(delta_beats);
    }
}