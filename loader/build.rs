use cmake;

fn main() {
    let dst = cmake::build("juce_io");

    println!("cargo:rustc-link-search=native={}", dst.display());
    println!("cargo:rustc-link-search=native={}/build", dst.display());

    println!("cargo:rustc-link-lib=static=JucePluginLoader");

    println!("cargo:rerun-if-changed=juce_io/lib.cpp");

    if cfg!(target_os = "macos") {
        println!("cargo:rustc-link-lib=dylib=c++");

        println!("cargo:rustc-link-lib=framework=CoreAudio");
        println!("cargo:rustc-link-lib=framework=CoreMIDI");

        println!("cargo:rustc-link-lib=framework=UserNotifications");
        println!("cargo:rustc-link-lib=framework=AVFoundation");

        println!("cargo:rustc-link-lib=framework=AudioToolbox");
        println!("cargo:rustc-link-lib=framework=AudioUnit");

        println!("cargo:rustc-link-lib=framework=Foundation");
        println!("cargo:rustc-link-lib=framework=CoreServices");
        println!("cargo:rustc-link-lib=framework=CoreFoundation");

        println!("cargo:rustc-link-lib=framework=Accelerate");
        println!("cargo:rustc-link-lib=framework=AppKit");
    } else {
        println!("cargo:rustc-link-lib=dylib=stdc++");
        println!("cargo:rustc-link-lib=dylib=asound");
    }
}