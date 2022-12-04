use std::sync::{Arc, RwLock};


use pa_dsp::{Source, Voice};

use crate::*;

/*

Todo
 - Stop/play button
 - Double scrolling view like serato sample
 - Mono/polyphonic button (same as global version)
 - ADSR can be another module. Keep fade in and fade out.
 - Separate audio track module? Uses time input for playback.
 - Rename piano roll to midi track

*/

pub struct AudioTrack {
    sample: Arc<RwLock<Sample<2>>>,
    start: f32,
    end: f32,
    attack: f32,
    release: f32,
    should_loop: bool,
    loop_start: f32,
    loop_end: f32,
    loop_crossfade: f32,
    one_shot: bool,
    reverse: bool,
}

pub struct AudioTrackVoice {
    index: u32,
    player: SamplePlayer,
}

impl Module for AudioTrack {
    type Voice = AudioTrackVoice;

    const INFO: Info = Info {
        title: Title("Audio Track", Color::BLUE),
        size: Size::Static(390, 200),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 15 + 30 * 0),
            Pin::Time("Time Input", 15 + 30 * 2),
        ],
        outputs: &[Pin::Audio("Audio Output", 15)],
    };

    
    fn new() -> Self {
        if cfg!(target_os = "macos") {
            return Self {
                sample: Arc::new(RwLock::new(Sample::load(
                    "/Users/chasekanipe/guitar_samples/Samples/FlamencoDreams_55_C2_G_2.wav",
                ))),
                start: 0.0,
                end: 1.0,
                attack: 0.0,
                release: 0.0,
                should_loop: false,
                loop_start: 0.2,
                loop_end: 0.8,
                loop_crossfade: 0.1,
                one_shot: false,
                reverse: false,
            };
        } else {
            return Self {
                sample: Arc::new(RwLock::new(Sample::load(
                    "/home/chase/guitar_samples/Samples/FlamencoDreams_55_C2_G_2.wav",
                ))),
                start: 0.0,
                end: 1.0,
                attack: 0.0,
                release: 0.0,
                should_loop: false,
                loop_start: 0.2,
                loop_end: 0.8,
                loop_crossfade: 0.1,
                one_shot: false,
                reverse: false,
            };
        }
    }

    fn new_voice(index: u32) -> Self::Voice {
        Self::Voice {
            index,
            player: SamplePlayer::new(),
        }
    }

    fn is_active(voice: &Self::Voice) -> bool {
        voice.player.is_active()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Stack {
            children: (Transform {
                position: (35, 35),
                size: (320, 150),
                child: SamplePicker {
                    sample: self.sample.clone(),
                    color: Color::BLUE,
                    start: &mut self.start,
                    end: &mut self.end,
                    attack: &mut self.attack,
                    release: &mut self.release,
                    should_loop: &mut self.should_loop,
                    loop_start: &mut self.loop_start,
                    loop_end: &mut self.loop_end,
                    loop_crossfade: &mut self.loop_crossfade,
                    one_shot: &mut self.one_shot,
                    reverse: &mut self.reverse,
                },
            }),
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {}
}
