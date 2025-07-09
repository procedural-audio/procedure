use cxx_juce::juce_audio_devices::{AudioCallbackHandle, AudioDeviceManager, AudioIODevice, AudioIODeviceCallback, InputAudioSampleBuffer, OutputAudioSampleBuffer};

use flutter_rust_bridge::frb;

use crate::api::graph::Graph;


pub fn initialize_playback() {
    let juce = cxx_juce::JUCE::initialise();
    let manager = AudioDeviceManager::new(&juce);
    println!("Initialized playback");
}

struct PlaybackHandle(AudioCallbackHandle);

struct Playback {
    manager: AudioDeviceManager,
}

unsafe impl Send for Playback {}

impl Playback {
    fn init() -> Self {
        let juce = cxx_juce::JUCE::initialise();
        let manager = AudioDeviceManager::new(&juce);

        Self { manager }
    }

    fn reset(&mut self, input_channels: usize, output_channels: usize) {
        self.manager.initialise(input_channels, output_channels).unwrap();
    }

    fn add_audio_callback(&mut self, graph: Graph) -> PlaybackHandle {
        let handle = self.manager.add_audio_callback(graph);
        PlaybackHandle(handle)
    }

    fn remove_audio_callback(&mut self, handle: PlaybackHandle) {
        self.manager.remove_audio_callback(handle.0);
    }
}

impl AudioIODeviceCallback for Graph {
    #[frb(ignore)]
    fn about_to_start(&mut self, device: &mut dyn AudioIODevice) {
        println!("preparing to start");

        let sizes = device.available_buffer_sizes();
        let rates = device.available_sample_rates();
        let size = device.buffer_size();
        let rate = device.sample_rate();
    }

    #[frb(ignore)]
    fn process_block(
        &mut self,
        _input: &InputAudioSampleBuffer<'_>,
        output: &mut OutputAudioSampleBuffer<'_>,
    ) {
        for channel in 0..output.channels() {
            ()
        }
    }

    fn stopped(&mut self) {
        println!("stopped");
    }
}
