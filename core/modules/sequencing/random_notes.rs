use crate::*;

use rand::Rng;

pub struct RandomNotes {
    rng: rand::rngs::ThreadRng,
    control: f32,
    keys: [Key; 12],
    min: f32,
    max: f32,
    last_id: Option<Id>
}

impl Module for RandomNotes {
    type Voice = u32;

    const INFO: Info = Info {
        title: "Random Notes",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(245, 140),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Trigger", 10),
            Pin::Control("Min Note Num (0-127)", 10+25),
            Pin::Control("Max Note Num (0-127)", 10+50),
        ],
        outputs: &[
            Pin::Notes("Notes", 10)
        ],
        path: "Category 1/Category 2/Module Name"
    };
    
    fn new() -> Self {
        Self {
            rng: rand::thread_rng(),
            control: 0.0,
            keys: [
                Key { down: false }; 12
            ],
            min: 0.0,
            max: 1.0,
            last_id: None
        }
    }

    fn new_voice(index: u32) -> Self::Voice { index }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Stack {
            children: (
                Transform {
                    position: (35, 35),
                    size: (180, 120-35),
                    child: widget::Keyboard {
                        keys: &mut self.keys,
                        on_event: | event, keys | {
                            match event {
                                KeyEvent::Press(i) => {
                                    keys[i].down = !keys[i].down;
                                },
                                KeyEvent::Release(_) => {},
                            }
                        }
                    }
                },
                Transform {
                    position: (15, 100),
                    size: (210, 50),
                    child: RangeSlider {
                        min: &mut self.min,
                        max: &mut self.max,
                        divisions: 10,
                        color: Color::GREEN
                    }
                }
            )
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if *voice == 0 {
            if inputs.control[0] > 0.5 && self.control < 0.5 {
                let min = (self.min * 10.0) as u32;
                let max = (f32::max(self.max, self.min + 1.0/10.0) * 10.0) as u32;
                let octave = self.rng.gen_range(min..max);

                let rand_step = self.rng.gen_range(0..12);
                let mut min_dist = u32::MAX;
                let mut quantized_step = u32::MAX;

                for (i, key) in self.keys.iter().enumerate() {
                    let dist = u32::abs_diff(i as u32, rand_step);
                    if key.down {
                        if dist < min_dist {
                            min_dist = dist;
                            quantized_step = i as u32;
                        }
                    }
                }

                if let Some(last_id) = self.last_id {
                    outputs.events[0].push(
                        NoteMessage {
                            id: last_id,
                            offset: 0,
                            note: Event::NoteOff
                        }
                    );
                }

                if quantized_step != u32::MAX {
                    let id = Id::new();
                    self.last_id = Some(id);
                    outputs.events[0].push(
                        NoteMessage {
                            id,
                            offset: 0,
                            note: Event::NoteOn {
                                pitch: num_to_pitch(octave * 12 + quantized_step),
                                pressure: 0.5
                            }
                        }
                    );
                }
            }

            self.control = inputs.control[0];
        }
    }
}