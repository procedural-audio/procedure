use modules::*;

pub struct Rene {
    player: NotePlayer,
    knobs: [f32; 8],
    last_id: Option<Id>
}

impl Module for Rene {
    type Voice = u32;

    const INFO: Info = Info {
        title: "Rene",
        id: "default.sequencing.rene",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(400, 200),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Time("Time", 10)
        ],
        outputs: &[
            Pin::Notes("Notes Output", 10)
        ],
        path: &["Notes", "Generative", "Rene"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            player: NotePlayer::new(),
            knobs: [0.5; 8],
            last_id: None
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice { index }
    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(
            Padding {
                padding: (10, 35, 10, 10),
                child: widget::GridBuilder {
                    columns: 8,
                    state: &mut self.knobs,
                    builder: | _i, v | {
                        widget::Fader {
                            value: v,
                            color: Color::GREEN
                        }
                    }
                }
            }
        )
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if *voice == 0 {
            inputs.time[0].on_each(1.0, | beat | {
                if let Some(id) = self.last_id {
                    self.player.note_off(id);
                    self.last_id = None;
                }

                let fade = self.knobs[beat % 8];
                if fade != 0.0 {
                    let id = Id::new();
                    self.player.note_on(id, fade * 440.0 + 120.0, 0.5);
                    self.last_id = Some(id);
                }

            });
        }

        self.player.generate(*voice, &mut outputs.events[0]);
    }
}
