use crate::modules::*;

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
}

impl Processor for NoteListener {
    type Item = Event;

    #[inline]
    fn process(&mut self, event: Self::Item) -> Self::Item {
        match event {
            Event::NoteOn { note, offset: _ } => {
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
                        voice.id = note.id;
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
                                voice.id = note.id;
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
            Event::NoteOff { id } => {
                for voice in &mut self.voices {
                    if voice.id == id && voice.active {
                        voice.active = false;
                        voice.queued.push(event);
                    }
                }
            }
            Event::Pitch { id, freq: _ } => {
                for voice in &mut self.voices {
                    if voice.id == id && voice.active {
                        voice.counter = self.counter;
                        voice.queued.push(event);
                    }
                }
            }
            Event::Pressure { id, pressure: _ } => {
                for voice in &mut self.voices {
                    if voice.id == id && voice.active {
                        voice.counter = self.counter;
                        voice.queued.push(event);
                    }
                }
            }
            Event::Timbre { id, timbre: _ } => {
                for voice in &mut self.voices {
                    if voice.id == id && voice.active {
                        voice.counter = self.counter;
                        voice.queued.push(event);
                    }
                }
            }
            Event::Controller { id: _, value: _ } => (),
            Event::ProgramChange { id: _, value: _ } => (),
            Event::None => (),
        }

        self.counter += 1;

        self.voices[self.current_voice]
            .queued
            .pop()
            .unwrap_or(Event::None)
    }
}

struct EventVoice {
    active: bool,
    id: u16,
    counter: usize,
    queued: Vec<Event>,
}

impl EventVoice {
    pub fn new() -> Self {
        Self {
            active: false,
            id: 0,
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
        name: "",
        color: Color::GREEN,
        size: Size::Static(85, 60),
        voicing: Voicing::Polyphonic,
        features: &[Feature::MidiInput],
        vars: &[],
        inputs: &[
            Pin::NotesInput(0)
        ],
        outputs: &[
            Pin::Notes("External Midi 1", 22)
        ],
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

    fn process(&mut self, _vars: &Vars, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        self.listener.set_voice(voice.index as usize);

        for (src, dest) in inputs.events[0]
            .as_ref()
            .iter()
            .zip(outputs.events[0].as_mut().iter_mut())
        {
            *dest = self.listener.process(*src);
        }

        for event in &outputs.events[0] {
            match event {
                Event::NoteOn { note: _, offset: _ } => {
                    println!("Voice {}: Note on", voice.index);
                }
                Event::NoteOff { id: _ } => {
                    println!("Voice {}: Note off", voice.index);
                }
                Event::Pitch { id: _, freq: _ } => {
                    println!("Voice {}: Pitch event", voice.index);
                }
                Event::Pressure { id: _, pressure: _ } => {}
                Event::Timbre { id: _, timbre: _ } => {}
                Event::Controller { id: _, value: _ } => {}
                Event::ProgramChange { id: _, value: _ } => {}
                Event::None => {}
            }
        }
    }
}
