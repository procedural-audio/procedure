use crate::*;

pub struct ControlToNotes;

pub struct ControlToNotesVoice {
    pub note_on: bool,
}

impl Module for ControlToNotes {
    type Voice = ControlToNotesVoice;

    const INFO: Info = Info {
        title: "",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(100, 75),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Control("Note Gate", 15),
            Pin::Control("Note Pitch", 45),
        ],
        outputs: &[Pin::Notes("Notes", 30)],
        path: "Utilities/Conversion/Control To Notes",
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice { note_on: false }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 20),
            size: (40, 40),
            child: Svg {
                path: "comparisons/greater_equal.svg",
                color: Color::GREEN,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        /*if inputs.control[0] > 0.5 {
            if !voice.note_on {
                println!("Sending note with pitch {}", inputs.control[1]);

                outputs.events[0][0] = Event::NoteOn {
                    note: Note::from_pitch(inputs.control[1]),
                    offset: 0,
                };

                voice.note_on = true;
            }
        } else {
            voice.note_on = false;
        }*/
    }
}
