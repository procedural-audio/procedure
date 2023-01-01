use crate::*;

use std::sync::{Arc, RwLock};

/*

Morphagene notes
 - Reel has a sample of up to 87 seconds
 - Reel can be split into up to 99 splices
 - Pressing splice button (or CV) will splice sample at current location
 - Current splice is selected with organize knob/CV
 - Shift button increments from current splice to the next
 - Varispeed control changes speed/direction/pitch of playback
 - Genes
   - A gene is a small window of the slice
   - The slide control determines the start of the gene
   - The gene size control change the size of the gene
   - The morph control determines the overlap between sucessive genes

*/

/*

Slicer
 - Can load a sample of arbitrary size
 - Can click pointes on the sample to add splice points
 - Knob/CV 1: Select splice
 - Knob/CV 2: Control speed/direction/pitch of playback
 - ~~Button/CV 2: Shift current splice (not functional)~~
 - Window
   - Knob/CV 1: Window start
   - Knob/CV 2: Window size
   - Knob/CV 3: Window crossfade

*/

pub struct Slicer {
    sample: Arc<RwLock<Sample<2>>>,
    slice_points: Vec<f32>,
    selected_slice: usize,
    window_start: f32,
    window_end: f32,
    window_crossfade: f32,
    current_sample: isize,
    three: f32,
    four: f32,
}

impl Module for Slicer {
    type Voice = ();

    const INFO: Info = Info {
        title: "Slicer",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(305, 195),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Control("Splice Select", 15 + 30 * 0),
            Pin::Control("Playback speed", 15 + 30 * 1),
            Pin::Control("Window start", 15 + 30 * 2),
            Pin::Control("Window size", 15 + 30 * 3),
            Pin::Control("Window crossfade", 15 + 30 * 4),
        ],
        outputs: &[Pin::Audio("Audio Output", 15)],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        let sample: Sample<2>;

        if cfg!(target_os = "macos") {
            sample = Sample::load(
                "/Users/chasekanipe/guitar_samples/Samples/FlamencoDreams_55_C2_G_2.wav",
            );
        } else {
            sample =
                Sample::load("/home/chase/guitar_samples/Samples/FlamencoDreams_55_C2_G_2.wav");
        }

        Self {
            slice_points: Vec::new(),
            selected_slice: 0,
            sample: Arc::new(RwLock::new(sample)),
            window_start: 0.0,
            window_end: 0.5,
            window_crossfade: 0.0,
            current_sample: 0,
            three: 0.0,
            four: 0.0,
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }
    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Stack {
            children: (
                /*Transform {
                    position: (35, 35),
                    size: (235, 80),
                    child: SamplePicker {
                        sample: self.sample.clone(),
                        color: Color::BLUE,
                    }
                },*/
                Transform {
                    position: (35 + 60 * 0, 120),
                    size: (50, 70),
                    child: Knob {
                        text: "Start",
                        value: &mut self.window_start,
                        color: Color::BLUE,
                        feedback: Box::new(|_v| String::new()),
                    },
                },
                Transform {
                    position: (35 + 60 * 1, 120),
                    size: (50, 70),
                    child: Knob {
                        text: "End",
                        value: &mut self.window_end,
                        color: Color::BLUE,
                        feedback: Box::new(|_v| String::new()),
                    },
                },
                Transform {
                    position: (35 + 60 * 2, 120),
                    size: (50, 70),
                    child: Knob {
                        text: "Three",
                        value: &mut self.three,
                        color: Color::BLUE,
                        feedback: Box::new(|_v| String::new()),
                    },
                },
                Transform {
                    position: (35 + 60 * 3, 120),
                    size: (50, 70),
                    child: Knob {
                        text: "Four",
                        value: &mut self.four,
                        color: Color::BLUE,
                        feedback: Box::new(|_v| String::new()),
                    },
                },
            ),
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        let mut start_point = 0.0;
        let mut end_point = 1.0;

        if self.selected_slice > 0 {
            start_point = self.slice_points[self.selected_slice];

            if self.selected_slice + 1 < self.slice_points.len() {
                end_point = self.slice_points[self.selected_slice + 1];
            }
        }

        if let Ok(sample) = self.sample.try_read() {
            println!("Getting slices");

            let dest_slice = outputs.audio[0].left.as_slice_mut();

            let slice_start = f32::round(sample.as_array()[0].len() as f32 * start_point) as usize;
            let slice_end = f32::round(sample.as_array()[0].len() as f32 * end_point) as usize;

            let src_slice = &sample.as_array()[0][slice_start..slice_end];

            let window_start = f32::round(src_slice.len() as f32 * self.window_start) as usize;
            let window_end = f32::round(src_slice.len() as f32 * self.window_end) as usize;

            let mut current_sample = self.current_sample;
            println!("Sample is {}", current_sample);

            let mut window_size = 0;

            if window_end > window_start {
                window_size = (window_end - window_start) as isize;
            } else {
                window_size = (window_start - window_end) as isize;
            }

            while current_sample < 0 {
                current_sample = window_size + current_sample;
            }

            if current_sample > 0 && window_size > 0 {
                if current_sample > window_size {
                    current_sample = current_sample % window_size;
                }
            }

            if window_start < window_end {
                /* Cycle forwards */

                let src_window = &src_slice[window_start..window_end];

                for (dest, src) in dest_slice
                    .iter_mut()
                    .zip(src_window.iter().cycle().skip(current_sample as usize))
                {
                    *dest = *src;
                }

                current_sample += dest_slice.len() as isize;
            } else if window_start > window_end {
                /* Cycle backwards */

                let src_window = &src_slice[window_end..window_start];

                for (dest, src) in dest_slice.iter_mut().zip(
                    src_window
                        .iter()
                        .rev()
                        .cycle()
                        .skip((window_start - window_end) - current_sample as usize),
                ) {
                    *dest = *src;
                }

                current_sample -= dest_slice.len() as isize;
            }

            self.current_sample = current_sample;
        }
    }
}
