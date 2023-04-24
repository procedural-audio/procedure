use modules::*;

pub struct Generate;

pub struct GenerateVoice {
    index: u32,
    playing: Option<Id>
}

impl Module for Generate {
    type Voice = GenerateVoice;

    const INFO: Info = Info {
        title: "Generate",
        id: "default.sequencing.generate",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(140, 90),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Trigger", 10),
            Pin::Control("Pitch", 35),
            Pin::Control("Pressure", 60),
        ],
        outputs: &[
            Pin::Notes("Notes Output", 10),
        ],
        path: &["Notes", "Generative", "Generate"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        GenerateVoice {
            index,
            playing: None
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 20),
            size: (40, 40),
            child: Icon {
                path: "comparisons/equals.svg",
                color: Color::GREEN,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if voice.index == 0 {
            match voice.playing {
                Some(id) => {
                    if inputs.control[0] < 0.5 {
                        outputs.events[0].push(
                            NoteMessage {
                                id,
                                offset: 0,
                                note: Event::NoteOff,
                            }
                        );

                        voice.playing = None;
                    }
                },
                None => {
                    if inputs.control[0] >= 0.5 {
                        let id = Id::new();

                        outputs.events[0].push(
                            NoteMessage {
                                id,
                                offset: 0,
                                note: Event::NoteOn {
                                    pitch: inputs.control[1],
                                    pressure: inputs.control[2],
                                },
                            }
                        );

                        voice.playing = Some(id);
                    }
                }
            }
        }
    }
}
