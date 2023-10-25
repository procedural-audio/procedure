use modules::*;
use pa_dsp::*;

pub struct XYSequencer {
    pitches: [f32; 16],
    player: NotePlayer
}

impl Module for XYSequencer {
    type Voice = u32;

    const INFO: Info = Info {
        title: "XY Sequencer",
        id: "default.sequencing.xy_sequencer",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(55 * 4 + 35 + 35, 80 * 4 + 10),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Time("Time X", 10),
            Pin::Time("Time Y", 35),
        ],
        outputs: &[
            Pin::Notes("Notes Output", 10)
        ],
        path: &["Notes", "Sequencing", "XY Sequencer"]
    };
    
    fn new() -> Self {
        Self {
            pitches: [0.5; 16],
            player: NotePlayer::new(),
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice { index }
    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Padding {
            padding: (35, 35, 35, 0),
            child: GridBuilder {
                columns: 4,
                state: &mut self.pitches,
                builder: | index: usize, pitch: &mut f32 | {
                    Knob {
                        text: "",
                        color: Color::GREEN,
                        value: pitch,
                        feedback: Box::new(| v | format!("{:.2}", pitch_to_num(v * 10000.0))),
                    }
                }
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
       self.player.generate(*voice, &mut outputs.events[0]);
    }
}