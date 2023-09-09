include!(concat!(env!("OUT_DIR"), "/workstation.core.rs"));

pub use prost::Message;

pub fn add(left: usize, right: usize) -> usize {
    left + right
}

