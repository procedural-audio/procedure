use modules::*;
use modules::widget::Key;

pub struct Keyboard {
    player: NotePlayer,
    keys: [Key; 88]
}

impl Module for Keyboard {
    type Voice = u32;

    const INFO: Info = Info {
        title: "Keyboard",
        id: "default.sequencing.keyboard",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Reisizable {
            default: (600, 120),
            min: (200, 110),
            max: (1200, 110)
        },
        voicing: Voicing::Polyphonic,
        inputs: &[],
        outputs: &[
            Pin::Notes("Notes Output", 10)
        ],
        path: &["Notes", "Sequencing", "Keyboard"]
    };
    
    fn new() -> Self {
        Self {
            player: NotePlayer::new(),
            keys: [
                Key { down: false }; 88
            ]
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice { index }
    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(
            Padding {
                padding: (10, 35, 10, 10),
                child: widget::Keyboard {
                    keys: &mut self.keys,
                    on_event: | event, keys | {
                        match event {
                            KeyEvent::Press(i) => {
                                keys[i].down = true;
                                self.player.note_num_on(i as u32 + 24, 0.5);
                            },
                            KeyEvent::Release(i) => {
                                keys[i].down = false;
                                self.player.note_num_off(i as u32 + 24);
                            }
                        }
                    }
                }
            }
        )
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
       self.player.generate(*voice, &mut outputs.events[0]);
    }
}