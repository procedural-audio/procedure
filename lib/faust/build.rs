extern crate faust_build;

use faust_build::build_library;

fn main() {
    println!("cargo:rerun-if-changed=faust/");
    build_library("faust/");
}

