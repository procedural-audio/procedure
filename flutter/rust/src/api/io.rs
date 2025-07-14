use flutter_rust_bridge::frb;
use cxx_juce::{
    juce_audio_devices::{
        AudioDeviceManager, AudioDeviceSetup, AudioIODevice, AudioIODeviceCallback,
        AudioIODeviceType, ChannelCount, MidiDeviceManager, 
        InputAudioSampleBuffer, OutputAudioSampleBuffer, AudioCallbackHandle
    }, 
    JUCE
};
use std::sync::{mpsc, Arc, RwLock};
use tokio::sync::oneshot;
use crate::api::patch::Patch;
use crate::api::graph::{set_patch, clear_patch};
use crate::other::action::{Actions, ExecuteAction, IO};

#[derive(Clone, Debug)]
#[frb]
pub struct AudioConfiguration {
    pub input_device: String,
    pub output_device: String,
    pub sample_rate: f64,
    pub buffer_size: usize,
}

impl Default for AudioConfiguration {
    fn default() -> Self {
        Self {
            input_device: "Default".to_string(),
            output_device: "Default".to_string(),
            sample_rate: 44100.0,
            buffer_size: 512,
        }
    }
}

#[derive(Clone, Debug)]
#[frb]
pub struct FlutterMidiConfiguration {
    pub input_device: String,
    pub output_device: String,
    pub enabled: bool,
    pub clock_enabled: bool,
    pub transport_enabled: bool,
    pub program_change_enabled: bool,
}

impl Default for FlutterMidiConfiguration {
    fn default() -> Self {
        Self {
            input_device: "".to_string(),
            output_device: "".to_string(),
            enabled: false,
            clock_enabled: false,
            transport_enabled: false,
            program_change_enabled: false,
        }
    }
}

// Messages that can be sent to the audio thread
#[derive(Debug)]
enum AudioMessage {
    GetDeviceTypes(oneshot::Sender<Vec<String>>),
    GetInputDevices(String, oneshot::Sender<Vec<String>>),
    GetOutputDevices(String, oneshot::Sender<Vec<String>>),
    GetSetup(oneshot::Sender<AudioConfiguration>),
    SetSetup(AudioConfiguration),
    GetDeviceType(oneshot::Sender<Option<String>>),
    SetDeviceType(String, oneshot::Sender<Result<(), String>>),
    
    // MIDI Messages
    GetMidiInputDevices(oneshot::Sender<Vec<String>>),
    GetMidiOutputDevices(oneshot::Sender<Vec<String>>),
    GetMidiSetup(oneshot::Sender<FlutterMidiConfiguration>),
    SetMidiSetup(FlutterMidiConfiguration),
    
    StopPlayback,
    Shutdown,
    SetPatch(Patch),
    ClearPatch,
}

// Patch audio callback that processes the patch graph
struct PatchAudioCallback {
    actions: Option<Actions>,
    midi_output: Vec<u32>,
}

impl PatchAudioCallback {
    fn new() -> Self {
        Self {
            actions: None,
            midi_output: Vec::new(),
        }
    }
}

impl AudioIODeviceCallback for PatchAudioCallback {
    fn about_to_start(&mut self, device: &mut dyn AudioIODevice) {
        println!("Patch audio callback starting - Sample rate: {}, Channels: {}", 
                 device.sample_rate(), device.output_channels());
    }

    fn process_block(
        &mut self,
        input: &InputAudioSampleBuffer<'_>,
        output: &mut OutputAudioSampleBuffer<'_>,
    ) {
        // Clear output buffer first
        for channel in 0..output.channels() {
            output[channel].fill(0.0);
        }
        
        // Process patch if available
        if let Some(actions) = &mut self.actions {
            // Create audio buffers for the IO struct
            let mut audio_buffers: Vec<Vec<f32>> = (0..output.channels())
                .map(|ch| output[ch].to_vec())
                .collect();
            
            let mut audio_refs: Vec<&mut [f32]> = audio_buffers
                .iter_mut()
                .map(|buf| buf.as_mut_slice())
                .collect();
            
            let midi_input = &[]; // TODO: Get MIDI input from JUCE
            self.midi_output.clear();
            
            let mut io = IO {
                audio: &mut audio_refs,
                midi_input,
                midi_output: &mut self.midi_output,
            };
            
            actions.execute(&mut io);
            
            // Copy processed audio back to output
            for (ch, buffer) in audio_buffers.into_iter().enumerate() {
                if ch < output.channels() {
                    output[ch].copy_from_slice(&buffer);
                }
            }
            
            // TODO: Send MIDI output to JUCE
        }
    }

    fn stopped(&mut self) {
        println!("Patch audio callback stopped");
    }
}

fn run_juce_message_loop(rx: mpsc::Receiver<AudioMessage>) {
    let juce = JUCE::initialise();
    let mut manager = AudioDeviceManager::new(&juce);
    let midi_manager = MidiDeviceManager::new(&juce);
    let mut midi_config = FlutterMidiConfiguration::default();
    let patch_callback = Arc::new(std::sync::Mutex::new(PatchAudioCallback::new()));
    let mut callback_handle: Option<AudioCallbackHandle> = None;

    manager.initialise(0, 2).unwrap();
    
    // Add the patch audio callback
    callback_handle = Some(manager.add_audio_callback(patch_callback.clone()));

    manager
        .device_types()
        .iter_mut()
        .for_each(|dt| dt.scan_for_devices());

    loop {
        while let Ok(message) = rx.try_recv() {
            match message {
                AudioMessage::GetDeviceTypes(response) => {
                    let _ = response.send(
                        manager
                            .device_types()
                            .iter()
                            .map(|dt| dt.name())
                            .collect()
                    );
                }
                AudioMessage::GetInputDevices(device_type, response) => {
                    let _ = response.send(
                        manager
                            .device_types()
                            .iter()
                            .find(| dt | dt.name() == device_type)
                            .map(|dt| dt.input_devices())
                            .unwrap_or(Vec::new())
                    );
                }
                AudioMessage::GetOutputDevices(device_type, response) => {
                    let _ = response.send(
                        manager
                            .device_types()
                            .iter()
                            .find(| dt | dt.name() == device_type)
                            .map(|dt| dt.output_devices())
                            .unwrap_or(Vec::new())
                    );
                }
                AudioMessage::GetSetup(response) => {
                    let setup = manager.audio_device_setup();
                    let config = AudioConfiguration {
                        input_device: setup.input_device_name().to_string(),
                        output_device: setup.output_device_name().to_string(),
                        sample_rate: setup.sample_rate(),
                        buffer_size: setup.buffer_size(),
                    };
                    let _ = response.send(config);
                }
                AudioMessage::SetSetup(config) => {
                    let setup = AudioDeviceSetup::default()
                        .with_buffer_size(config.buffer_size)
                        .with_sample_rate(config.sample_rate)
                        .with_input_channels(ChannelCount::Default)
                        .with_output_channels(ChannelCount::Default)
                        .with_input_device_name(config.input_device)
                        .with_output_device_name(config.output_device);

                    manager.set_audio_device_setup(&setup);
                }
                AudioMessage::GetDeviceType(response) => {
                    let _ = response.send(
                        manager
                            .current_device_type()
                            .map(|dt| dt.name())
                    );
                }
                AudioMessage::SetDeviceType(device_type, response) => {
                    manager.set_current_audio_device_type(&device_type);
                    let _ = response.send(Ok(()));
                }
                
                // MIDI Message Handling
                AudioMessage::GetMidiInputDevices(response) => {
                    let _ = response.send(midi_manager.input_devices());
                }
                AudioMessage::GetMidiOutputDevices(response) => {
                    let _ = response.send(midi_manager.output_devices());
                }
                AudioMessage::GetMidiSetup(response) => {
                    let _ = response.send(midi_config.clone());
                }
                AudioMessage::SetMidiSetup(config) => {
                    midi_config = config;
                }
                
                AudioMessage::SetPatch(patch) => {
                    if let Ok(mut callback) = patch_callback.lock() {
                        println!("Setting patch in audio manager with {} nodes, {} cables", 
                                 patch.nodes.len(), patch.cables.len());
                        callback.actions = Some(Actions::from(patch));
                    }
                }
                AudioMessage::ClearPatch => {
                    if let Ok(mut callback) = patch_callback.lock() {
                        println!("Clearing patch in audio manager");
                        callback.actions = None;
                    }
                }
                
                AudioMessage::StopPlayback => {},
                AudioMessage::Shutdown => {
                    println!("Shutting down audio thread");
                    // Remove audio callback before shutting down
                    if let Some(handle) = callback_handle {
                        manager.remove_audio_callback(handle);
                    }
                    return;
                }
            }
        }

        std::thread::sleep(std::time::Duration::from_millis(10));
    }
}

#[frb]
pub struct AudioManager {
    thread: std::thread::JoinHandle<()>,
    tx: mpsc::Sender<AudioMessage>,
}

impl AudioManager {
    #[frb(sync)]
    pub fn new() -> Self {
        let (tx, rx) = mpsc::channel();
        
        let thread = std::thread::spawn(move || {
            run_juce_message_loop(rx);
        });
        
        Self {
            thread,
            tx,
        }
    }
    
    pub async fn get_input_devices(&self, device_type: String) -> Vec<String> {
        let (tx, rx) = oneshot::channel();
        if self.tx.send(AudioMessage::GetInputDevices(device_type, tx)).is_ok() {
            rx.await.unwrap_or_default()
        } else {
            vec![]
        }
    }
    
    pub async fn get_output_devices(&self, device_type: String) -> Vec<String> {
        let (tx, rx) = oneshot::channel();
        if self.tx.send(AudioMessage::GetOutputDevices(device_type, tx)).is_ok() {
            rx.await.unwrap_or_default()
        } else {
            vec![]
        }
    }
    
    #[frb]
    pub async fn get_device_types(&self) -> Vec<String> {
        let (tx, rx) = oneshot::channel();
        if self.tx.send(AudioMessage::GetDeviceTypes(tx)).is_ok() {
            rx.await.unwrap_or_default()
        } else {
            vec![]
        }
    }

    #[frb]
    pub async fn get_setup(&self) -> AudioConfiguration {
        let (tx, rx) = oneshot::channel();
        if self.tx.send(AudioMessage::GetSetup(tx)).is_ok() {
            rx.await.unwrap()
        } else {
            AudioConfiguration::default()
        }
    }

    #[frb]
    pub async fn set_setup(&self, config: AudioConfiguration) -> Result<(), String> {
        if self.tx.send(AudioMessage::SetSetup(config)).is_ok() {
            Ok(())
        } else {
            Err("Failed to send configuration".to_string())
        }
    }

    #[frb]
    pub async fn get_device_type(&self) -> Option<String> {
        let (tx, rx) = oneshot::channel();
        if self.tx.send(AudioMessage::GetDeviceType(tx)).is_ok() {
            rx.await.unwrap()
        } else {
            None
        }
    }

    #[frb]
    pub async fn set_device_type(&self, device_type: String) -> Result<(), String> {
        let (tx, rx) = oneshot::channel();
        if self.tx.send(AudioMessage::SetDeviceType(device_type, tx)).is_ok() {
            rx.await.unwrap_or(Err("Failed to receive response".to_string()))
        } else {
            Err("Failed to send device type".to_string())
        }
    }
    
    // MIDI Methods
    #[frb]
    pub async fn get_midi_input_devices(&self) -> Vec<String> {
        let (tx, rx) = oneshot::channel();
        if self.tx.send(AudioMessage::GetMidiInputDevices(tx)).is_ok() {
            rx.await.unwrap_or_default()
        } else {
            vec![]
        }
    }
    
    #[frb]
    pub async fn get_midi_output_devices(&self) -> Vec<String> {
        let (tx, rx) = oneshot::channel();
        if self.tx.send(AudioMessage::GetMidiOutputDevices(tx)).is_ok() {
            rx.await.unwrap_or_default()
        } else {
            vec![]
        }
    }
    
    #[frb]
    pub async fn get_midi_setup(&self) -> FlutterMidiConfiguration {
        let (tx, rx) = oneshot::channel();
        if self.tx.send(AudioMessage::GetMidiSetup(tx)).is_ok() {
            rx.await.unwrap_or_default()
        } else {
            FlutterMidiConfiguration::default()
        }
    }
    
    #[frb]
    pub async fn set_midi_setup(&self, config: FlutterMidiConfiguration) -> Result<(), String> {
        if self.tx.send(AudioMessage::SetMidiSetup(config)).is_ok() {
            Ok(())
        } else {
            Err("Failed to send MIDI configuration".to_string())
        }
    }
    
    pub fn stop_playback(&self) -> Result<(), String> {
        self.tx.send(AudioMessage::StopPlayback)
            .map_err(|e| format!("Failed to send stop message: {}", e))
    }
    
    pub fn shutdown(self) -> Result<(), String> {
        self.tx.send(AudioMessage::Shutdown)
            .map_err(|e| format!("Failed to send shutdown message: {}", e))?;
        match self.thread.join() {
            Ok(_) => Ok(()),
            Err(_) => Ok(()), // Thread already finished
        }
    }
    
    #[frb]
    pub async fn set_patch(&self, patch: Patch) -> Result<(), String> {
        if self.tx.send(AudioMessage::SetPatch(patch)).is_ok() {
            Ok(())
        } else {
            Err("Failed to send patch".to_string())
        }
    }
    
    #[frb]
    pub async fn clear_patch(&self) -> Result<(), String> {
        if self.tx.send(AudioMessage::ClearPatch).is_ok() {
            Ok(())
        } else {
            Err("Failed to clear patch".to_string())
        }
    }
}
