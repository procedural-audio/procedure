use heck::CamelCase;
use std::io::Write;
use std::fs::OpenOptions;
use std::io;
use std::fs;
use std::path::Path;
use std::process::Command;
use std::{env, path::PathBuf};
use tempfile::NamedTempFile;

pub fn build_library(path: &str) {
    let out_dir = env::var_os("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("dsp.rs");

    fs::remove_file(dest_path.clone());
    fs::write(dest_path.clone(), "");

    mods_recurse(path, dest_path.clone());
    build_recurse(path, dest_path.clone());
}

pub fn build_recurse(path: &str, dest_path: PathBuf) {
    match fs::read_dir(path) {
        Ok(_dir) => {},
        Err(_e) => {
            build_dsp(path);
            append_use(path);
            return;
        },
    }

    let category = Path::new(path).file_name().unwrap().to_str().unwrap();

    start_use(category);

    let entries = fs::read_dir(path).unwrap()
        .map(|res| res.map(|e| e.path()))
        .collect::<Result<Vec<_>, io::Error>>().unwrap();

    for entry in entries.iter() {
        match entry.to_str() {
            Some(dir) => {
                build_recurse(dir, dest_path.clone());
            },
            None => {},
        }

    }

    end_use();
}

pub fn mods_recurse(path: &str, dest_path: PathBuf) {
    match fs::read_dir(path) {
        Ok(_dir) => {},
        Err(_e) => {
            append_mod(path);
            return;
        },
    }

    let _category = Path::new(path).file_name().unwrap().to_str().unwrap();

    let entries = fs::read_dir(path).unwrap()
        .map(|res| res.map(|e| e.path()))
        .collect::<Result<Vec<_>, io::Error>>().unwrap();

    for entry in entries.iter() {
        match entry.to_str() {
            Some(dir) => {
                mods_recurse(dir, dest_path.clone());
            },
            None => {},
        }

    }
}

pub fn append_mod(dsp_file: &str) {
    let dsp_path = PathBuf::from(dsp_file);
    let dsp_name = dsp_path.file_stem().unwrap();
    let out_dir = env::var_os("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("dsp.rs");

    let mut import = String::from("mod ");
    import.push_str(dsp_name.to_str().unwrap());
    import.push_str(";\n");

    let mut file1 = OpenOptions::new()
        .write(true)
        .create(true)
        .append(true)
        .open(dest_path)
        .unwrap();

    write!(file1, "{}", import);
}

pub fn end_use() {
    let out_dir = env::var_os("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("dsp.rs");

    let import = String::from("}\n");

    let mut file1 = OpenOptions::new()
        .write(true)
        .create(true)
        .append(true)
        .open(dest_path)
        .unwrap();

    write!(file1, "{}", import);
}

pub fn start_use(name: &str) {
    let out_dir = env::var_os("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("dsp.rs");

    let mut import = String::from("\npub mod ");
    import.push_str(name);
    import.push_str(" {\n");

    let mut file1 = OpenOptions::new()
        .write(true)
        .create(true)
        .append(true)
        .open(dest_path)
        .unwrap();

    write!(file1, "{}", import);
}

pub fn append_use(dsp_file: &str) {
    let dsp_path = PathBuf::from(dsp_file);
    let dsp_name = dsp_path.file_stem().unwrap();
    let out_dir = env::var_os("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("dsp.rs");

    let mut import = String::from("\tpub use crate::");
    import.push_str(dsp_name.to_str().unwrap());
    import.push_str("::*;\n");

    let mut file1 = OpenOptions::new()
        .write(true)
        .create(true)
        .append(true)
        .open(dest_path)
        .unwrap();

    write!(file1, "{}", import);
}

pub fn build_dsp(dsp_file: &str) {
    eprintln!("cargo:rerun-if-changed={}", dsp_file);
    let dsp_path = PathBuf::from(dsp_file);
    let dsp_name = dsp_path.file_stem().unwrap();
    let out_dir = env::var_os("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("dsp.rs");

    let template_code = include_str!("../faust-template.rs");
    let template_file = NamedTempFile::new().expect("failed creating temporary file");
    let target_file = NamedTempFile::new().expect("failed creating temporary file");

    fs::write(template_file.path(), template_code).expect("failed writing temporary file");

    // faust -a $ARCHFILE -lang rust "$SRCDIR/$f" -o "$SRCDIR/$dspName/src/main.rs"
    let output = Command::new("faust")
        .arg("-a")
        .arg(template_file.path())
        .arg("-lang")
        .arg("rust")
        .arg(&dsp_file)
        .arg("-o")
        .arg(target_file.path())
        .output()
        .expect("Failed to execute command");
    // eprintln!(
    //     "Wrote temp module:\n{}",
    //     target_file.path().to_str().unwrap()
    // );
    if !output.status.success() {
        panic!(
            "faust compilation failed: {}",
            String::from_utf8(output.stderr).unwrap()
        );
    }

    let dsp_code = fs::read(target_file).unwrap();
    let dsp_code = String::from_utf8(dsp_code).unwrap();

    let dsp_code = dsp_code.replace(
        "pub struct mydsp",
        "#[derive(Debug,Clone)]\npub struct mydsp",
    );

    let _struct_path = dsp_path.clone();

    let struct_name = dsp_name.to_str().unwrap().to_camel_case();

    let module_code = format!(
        r#"mod dsp {{
    {}
}}
pub use self::dsp::mydsp as {};
"#,
        dsp_code, struct_name
    );

    let mut dest_path2 = str::replace(dest_path.to_str().unwrap(), "dsp.rs", "");
    dest_path2.push_str(dsp_name.to_str().unwrap());
    dest_path2.push_str(".rs");

    /*Command::new("echo")
        .arg(module_code.clone())
        .spawn()
        .expect("failed to spawn process");*/

    fs::write(&dest_path2, module_code).expect("failed to write to destination path");

    // TODO: rustfmt hangs on the created file.
    // Command::new("rustfmt")
    //     .arg(&dest_path)
    //     .output()
    //     .expect("failed to run rustfmt");
    //eprintln!("Wrote module:\n{}", dest_path2);
}

