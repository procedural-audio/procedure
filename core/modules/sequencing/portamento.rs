use crate::*;

pub struct Portamento {
    rate: f32,
}

pub struct PortamentoVoice {
    curr_pitch: f32,
    dest_pitch: f32,
    note_on: Option<NoteMessage>
}

impl Module for Portamento {
    type Voice = PortamentoVoice;

    const INFO: Info = Info {
        title: "Port",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Input", 25),
            Pin::Control("Slew (0-1)", 55)
        ],
        outputs: &[
            Pin::Notes("Output", 25)
        ],
        path: "Notes/Effects/Portamento",
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            rate: 0.0
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice {
            curr_pitch: 0.0,
            dest_pitch: 0.0,
            note_on: None
        }
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Rate",
                color: Color::GREEN,
                value: &mut self.rate,
                feedback: Box::new(|v| format!("{:.2}", v)),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure: _ } => {
                    if voice.curr_pitch == 0.0 {
                        voice.curr_pitch = pitch;
                    }

                    voice.dest_pitch = pitch;
                    voice.note_on = Some(*msg);
                },
                Event::Pitch(pitch) => {
                    voice.dest_pitch = pitch;
                },
                _ => outputs.events[0].push(*msg)
            }
        }

        let rate = if inputs.control.connected(0) {
            inputs.control[0]
        } else {
            self.rate
        };

        let rate = f32::powf(rate, 2.0) * 48.0;

        if let Some(msg) = voice.note_on {
            outputs.events[0].push(
                NoteMessage {
                    id: msg.id,
                    offset: msg.offset,
                    note: Event::NoteOn {
                        pitch: voice.curr_pitch,
                        pressure: match msg.note {
                            Event::NoteOn { pitch: _, pressure } => pressure,
                            _ => unreachable!()
                        }
                    }
                }
            );

            println!("Note on {}", voice.curr_pitch);
            voice.note_on = None;
        } else {
            if voice.curr_pitch != voice.dest_pitch {
                let input = f32::clamp(voice.dest_pitch - voice.curr_pitch, -rate, rate);
                voice.curr_pitch = voice.curr_pitch + input;

                outputs.events[0].push(
                    NoteMessage {
                        id: Id::new(),
                        offset: 0,
                        note: Event::Pitch(voice.curr_pitch)
                    }
                );

                println!(" > pitch {}", voice.curr_pitch);
            }
        }
    }
}
