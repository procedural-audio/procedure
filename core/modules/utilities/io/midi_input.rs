use crate::*;

pub struct NoteListener {
    voices: Vec<EventVoice>,
    counter: usize,
    current_voice: usize,
}

impl NoteListener {
    pub fn new() -> Self {
        let mut voices = Vec::new();

        for _ in 0..8 {
            voices.push(EventVoice::new());
        }

        NoteListener {
            voices,
            counter: 0,
            current_voice: 0,
        }
    }

    pub fn set_voice(&mut self, index: usize) {
        self.current_voice = index;
    }

    fn push(&mut self, event: NoteMessage) {
        match event.note {
            Event::NoteOn { pitch, pressure } => {
                let mut next = None;
                let mut min = usize::MAX;

                for voice in &mut self.voices {
                    if !voice.active && voice.counter < min {
                        min = voice.counter;
                        next = Some(voice);
                    }
                }

                match next {
                    Some(voice) => {
                        // println!("Added event");
                        // Found inactive voice
                        voice.id = event.id;
                        voice.active = true;
                        voice.counter = self.counter;
                        voice.queued.push(event);
                    }
                    None => {
                        // Steal voice
                        let mut next = None;
                        let mut min = usize::MAX;

                        for voice in &mut self.voices {
                            if voice.counter < min {
                                min = voice.counter;
                                next = Some(voice);
                            }
                        }

                        match next {
                            Some(voice) => {
                                // println!("Stole voice for event");
                                voice.id = event.id;
                                voice.active = true;
                                voice.counter = self.counter;
                                voice.queued.push(event);
                            }
                            None => {
                                panic!("Failed to steal voice");
                            }
                        }
                    }
                }
            }
            Event::NoteOff => {
                for voice in &mut self.voices {
                    if voice.id == event.id && voice.active {
                        voice.active = false;
                        voice.queued.push(event);
                    }
                }
            }
            Event::Pitch(pitch) => {
                for voice in &mut self.voices {
                    if voice.id == event.id && voice.active {
                        voice.counter = self.counter;
                        voice.queued.push(event);
                    }
                }
            }
            Event::Pressure(pressure) => {
                for voice in &mut self.voices {
                    if voice.id == event.id && voice.active {
                        voice.counter = self.counter;
                        voice.queued.push(event);
                    }
                }
            }
            Event::Other(name, value) => {

            }
        }

        self.counter += 1;
    }

    fn gen(&mut self) -> Option<NoteMessage> {
        self.voices[self.current_voice]
            .queued
            .pop()
    }
}

struct EventVoice {
    active: bool,
    id: Id,
    counter: usize,
    queued: Vec<NoteMessage>,
}

impl EventVoice {
    pub fn new() -> Self {
        Self {
            active: false,
            id: Id::new(),
            counter: 0,
            queued: Vec::with_capacity(16),
        }
    }
}

pub struct MidiInput {
    listener: NoteListener,
}

pub struct MidiInputVoice {
    index: u32,
}

impl Module for MidiInput {
    type Voice = MidiInputVoice;

    const INFO: Info = Info {
        title: "",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(85, 60),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::ExternalNotes(0)
        ],
        outputs: &[
            Pin::Notes("External Midi 1", 22)
        ],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        Self {
            listener: NoteListener::new(),
        }
    }

    fn new_voice(index: u32) -> Self::Voice {
        Self::Voice { index }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (15, 15),
            size: (30, 30),
            child: Svg {
                path: "logos/midi2.svg",
                color: Color::GREEN,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        self.listener.set_voice(voice.index as usize);

        for msg in &inputs.events[0] {
            println!("NoteMessage: id: {}, offset: {}, note: {}", msg.id.num(), msg.offset, msg.note);
            self.listener.push(*msg);
        }

        while let Some(msg) = self.listener.gen() {
            outputs.events[0].push(msg);
        }
    }
}
