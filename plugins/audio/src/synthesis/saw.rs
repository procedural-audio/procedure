use crate::*;

use pa_algorithms::*;

pub struct SawModule;

pub struct SawModuleVoice {
    saw: Saw<Stereo<f32>>,
    active: bool,
}

impl Module for SawModule {
    type Voice = SawModuleVoice;

    const INFO: Info = Info {
        title: "Saw",
        id: "default.synthesis.saw",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[Pin::Notes("Notes", 15)],
        outputs: &[Pin::Audio("Audio Output", 15)],
        path: &["Audio", "Synthesis", "Saw"],
        presets: Presets::NONE
    };

    fn new() -> Self { Self }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            saw: Saw::new(),
            active: false,
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 25),
            size: (40, 40),
            child: Icon {
                path: "waveforms/saw.svg",
                color: Color::BLUE,
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.active = false;
		voice.saw.prepare(sample_rate, block_size);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        osc(Stereo::sin, 440.0f32) >> &mut outputs.audio[0];

        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure: _ } => {
                    voice.active = true;
                    voice.saw.set_pitch(pitch);
                },
                Event::NoteOff => {
                    voice.active = false;
                },
                Event::Pitch(freq) => {
                    voice.saw.set_pitch(freq);
                },
                _ => (),
            }
        }

        if voice.active {
			voice.saw.generate_block(&mut outputs.audio[0]);

            for sample in (&mut outputs.audio[0]).into_iter() {
                sample.left *= 0.1;
                sample.right *= 0.1;
            }
        }
    }
}

pub struct Info2 {
    title: &'static str,
    color: Color,
    path: &'static [&'static str],
    graph: fn() -> Box<dyn Generator<Output = f32>>
}

pub trait Module2 {
    const INFO: Info2;
}

impl Module2 for SawModule {
    const INFO: Info2 = Info2 {
        title: "Saw",
        color: Color::BLUE,
        path: &["path", "to", "module"],
        // graph: graph!(saw(440.0) >> gain(20.0) >> gain(-10.0) >> gain(-20.0)),
        graph: || {
            Box::new(
                osc(f32::sin, 550.0f32) >> gain(20.0) >> gain(-10.0) >> gain(-20.0)
            )
        }
    };
}

// module!("Saw", saw(440.0) >> gain(20.0) >> gain(-10.0) >> gain(-20.0));
