use std::vec;

use crate::*;

pub struct StepSequencer {
    grid: Vec<Vec<bool>>,
    notes: Vec<Vec<Note>>,
    used_voice: u32,
    playing: Vec<(u32, Note)>,
    queue: Vec<(u32, Event)>,
    step: usize,
}

pub struct StepSequencerVoice {
    index: u32,
}

impl Module for StepSequencer {
    type Voice = StepSequencerVoice;

    const INFO: Info = Info {
        name: "",
                color: Color::GREEN,
        size: Size::Static(20 + 80 + 42 * 16, 20 + 20 + 42 * 8),
        voicing: Voicing::Polyphonic,
        inputs: &[Pin::Time("Time", 10)],
        outputs: &[Pin::Notes("Midi Output", 10)],
    };

    
    fn new() -> Self {
        Self {
            grid: vec![vec![]],
            notes: vec![
                vec![Note::from_name("C3").unwrap()],
                vec![Note::from_name("C#3").unwrap()],
                vec![Note::from_name("D3").unwrap()],
                vec![Note::from_name("D#3").unwrap()],
                vec![Note::from_name("E3").unwrap()],
                vec![Note::from_name("F3").unwrap()],
                vec![Note::from_name("F#3").unwrap()],
                vec![Note::from_name("G3").unwrap()],
                vec![Note::from_name("G#3").unwrap()],
                vec![Note::from_name("A3").unwrap()],
                vec![Note::from_name("A#3").unwrap()],
                vec![Note::from_name("B3").unwrap()],
            ],
            used_voice: 0,
            playing: Vec::with_capacity(32),
            queue: Vec::with_capacity(32),
            step: 0,
        }
    }

    fn new_voice(index: u32) -> Self::Voice {
        Self::Voice { index }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Padding {
            padding: (10, 10, 10, 10),
            child: widget::StepSequencer {
                grid: &mut self.grid,
                row_notes: &mut self.notes,
                pad_size: (40.0, 40.0),
                pad_radius: 10.0,
                step: &self.step,
            },
        });
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let _t = inputs.time[0].cycle(self.grid.len() as f64);

        if voice.index == 0 && self.grid.len() > 0 {
            inputs.time[0]
                .cycle(self.grid.len() as f64)
                .on_each(1.0, |step| {
                    self.step = step;

                    for (v, note) in &self.playing {
                        self.queue.push((*v, Event::NoteOff { id: note.id }));
                    }

                    self.playing.clear();

                    // For each row at step
                    for row in 0..self.grid[step].len() {
                        // If row active
                        if self.grid[self.step][row] {
                            // Add each (step,row) note
                            for note in &self.notes[row] {
                                self.queue.push((
                                    self.used_voice,
                                    Event::NoteOn {
                                        note: *note,
                                        offset: 0,
                                    },
                                ));

                                self.used_voice += 1;
                            }
                        }
                    }
                });
        }

        for (index, event) in &self.queue {
            if voice.index == *index {
                match event {
                    Event::NoteOn { note, offset: _ } => self.playing.push((voice.index, *note)),
                    _ => (),
                }

                outputs.events[0].push(*event);
            }
        }

        self.queue.retain(|(i, _e)| *i != voice.index);
    }
}
