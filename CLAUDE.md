# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Procedure** is a procedural audio editor built on Flutter with Rust backend components. The project integrates multiple technologies:
- **Flutter** (Dart) - Cross-platform UI framework
- **Rust** - High-performance audio processing backend
- **Cmajor** - JIT audio engine for procedural audio
- **JUCE** - Audio plugin framework
- **Flutter Rust Bridge** - Seamless Dart-Rust interoperability

## Development Commands

### Flutter Commands (run from `flutter/` directory)
```bash
# Development
flutter pub get                    # Install dependencies
flutter run                       # Run in development mode
flutter run --debug               # Run in debug mode
flutter run --release             # Run in release mode

# Testing
flutter test                      # Run unit tests
flutter test --coverage          # Run tests with coverage
flutter integration_test         # Run integration tests

# Linting
flutter analyze                   # Static analysis
dart format .                     # Format Dart code
dart fix --apply                  # Apply suggested fixes

# Building
flutter build macos --release     # Build for macOS
flutter build windows --release   # Build for Windows
flutter build linux --release     # Build for Linux
flutter build ios --release --no-codesign  # Build for iOS
flutter build apk --release       # Build for Android
```

### Rust Commands (run from respective Rust directories)
```bash
# cmajor-rs/ - Cmajor JIT engine bindings
cargo build                       # Build development
cargo build --release             # Build release
cargo test                        # Run tests
cargo clippy                      # Run linting
cargo build --features static     # Build with static linking (macOS only)

# juce-rs/ - JUCE framework bindings
cargo build                       # Build development
cargo build --release             # Build release
cargo test                        # Run tests
cargo clippy                      # Run linting
cargo build --features asio       # Build with ASIO support

# flutter/rust/ - Flutter-Rust bridge
cargo build                       # Build development
cargo build --release             # Build release
cargo test                        # Run tests
```

### Custom Build Process
```bash
# Complete application build (from flutter/)
python build.py                   # Custom build script that:
                                  # - Downloads Flutter framework artifacts
                                  # - Builds JUCE components using CMake
                                  # - Packages the complete application
```

## Architecture Overview

### Core Components

**Frontend (Flutter)**
- `lib/main.dart` - Application entry point with AudioManager initialization
- `lib/home.dart` - Main home widget and UI coordination
- `lib/patch/` - Node-based patch editor interface
- `lib/project/` - Project management and browser
- `lib/settings/` - Application settings and configuration
- `lib/style/` - UI styling and theme components
- `lib/bindings/` - Generated Rust-Dart bindings via Flutter Rust Bridge

**Backend (Rust)**
- `flutter/rust/src/api/` - Core API layer for Flutter integration
- `cmajor-rs/` - Rust bindings for Cmajor JIT engine
- `juce-rs/` - Rust bindings for JUCE framework
- `flutter/host/` - Native host application (CMake-based)

**Key Integrations**
- **Flutter Rust Bridge** - Automatically generates type-safe bindings between Dart and Rust
- **Cargokit** - Handles cross-compilation and platform-specific builds
- **CMake** - Builds native JUCE components and hosts

### Data Flow
1. Flutter UI captures user interactions
2. Dart code calls Rust functions via generated bindings
3. Rust backend processes audio using Cmajor engine
4. Results flow back through bindings to update Flutter UI

## Working with the Codebase

### Common Development Tasks

**Adding New Audio Processing Features:**
1. Implement Rust functions in `flutter/rust/src/api/`
2. Run `flutter_rust_bridge_codegen generate` to regenerate bindings
3. Update Flutter UI to use new functions
4. Test with `flutter test` and `cargo test`

**Modifying UI Components:**
1. Edit Flutter widgets in `lib/patch/` or `lib/project/`
2. Follow existing patterns for state management
3. Use `flutter run --debug` for hot reload during development

**Building for Release:**
1. Test with `flutter test` and `cargo test` in all Rust directories
2. Run `flutter analyze` and `cargo clippy` for linting
3. Use `python build.py` for complete application packaging

### Dependencies and Platform Requirements

**Linux:**
```bash
sudo apt-get update -y
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libasound2-dev libjack-jackd2-dev
```

**macOS:**
- Xcode command line tools
- CMake and build tools (handled by Flutter/Rust toolchain)

**Windows:**
- Visual Studio Build Tools
- CMake and build tools

## Important Notes

- **Working Directory**: Most Flutter commands should be run from the `flutter/` subdirectory
- **Rust Components**: Three separate Rust projects require individual building and testing
- **Generated Code**: `lib/bindings/` contains auto-generated code - do not edit manually
- **Cross-Platform**: The build system supports macOS, Windows, Linux, iOS, and Android
- **Audio Dependencies**: Project requires platform-specific audio libraries (ASIO, JACK, etc.)