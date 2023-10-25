use std::marker::PhantomData;

use crate::*;

// TODO: Output latency as time, better knob feedback
pub struct PitchShifter {
	dsp: PitchShifterDSP<Stereo<f32>>,
    value: f32
}

impl Module for PitchShifter {
    type Voice = ();

    const INFO: Info = Info {
        title: "Pitch Shifter",
        id: "default.effects.spectral.pitch_shifter",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Input", 25),
            Pin::Control("Shift Semitones (-12 to +12)", 55),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 25),
        ],
        path: &["Audio", "Spectral", "Pitch Shifter"]
    };

    
    fn new() -> Self {
        Self {
			dsp: PitchShifterDSP::new(),
			value: 0.5
		}
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
		()
    }

    fn load(&mut self, _version: &str, state: &State) {
		self.value = state.load("value");
    }

    fn save(&self, state: &mut State) {
		state.save("value", self.value);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Crossover",
                color: Color::BLUE,
                value: &mut self.value,
                feedback: Box::new(| v| {
                    format!("{:.2} hz", v * 10000.0)
                }),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
		unsafe {
			let dsp = &self.dsp as *const PitchShifterDSP<Stereo<f32>> as *mut PitchShifterDSP<Stereo<f32>>;
			(*dsp).prepare(sample_rate, block_size);

		}
    }

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
		let mut value = self.value;
		if inputs.control.connected(0) {
			value = f32::clamp(inputs.control[0], 0.0, 1.0);
		}

		self.dsp.set_shift_factor(value + 0.5);
		self.dsp.process( &inputs.audio[0], &mut outputs.audio[0]);
    }
}

pub struct PitchShifterDSP<F: Sample> {
	shifters: Vec<signalsmith_stretch_sys::PitchShifter>,
	input_buffers: Vec<Vec<f32>>,
	output_buffers: Vec<Vec<f32>>,
	phantom: PhantomData<F>,
	cheap: bool,
}

impl<F: Sample> PitchShifterDSP<F> {
	pub fn new() -> Self {
		Self {
			shifters: Vec::new(),
			input_buffers: Vec::new(),
			output_buffers: Vec::new(),
			cheap: false,
			phantom: PhantomData,
		}
	}

	pub fn set_shift_factor(&mut self, shift: f32) {
		for shifter in &mut self.shifters {
			shifter.set_transpose_factor(shift);
		}
	}

	pub fn prepare(&mut self, sample_rate: u32, block_size: usize) {
		self.input_buffers = vec![vec![0.0; block_size]; F::CHANNELS];
		self.output_buffers = vec![vec![0.0; block_size]; F::CHANNELS];

		self.shifters.clear();
		for _ in 0..F::CHANNELS {
			self.shifters.push(signalsmith_stretch_sys::PitchShifter::new());
		}

		if self.cheap {
			for shifter in &mut self.shifters {
				shifter.prepare_cheaper(sample_rate as f32);
			}
		} else {
			for shifter in &mut self.shifters {
				shifter.prepare_default(sample_rate as f32);
			}
		}
	}

	pub fn reset(&mut self) {
		for shifter in &mut self.shifters {
			shifter.reset();
		}
	}

	pub fn process(&mut self, inputs: &Buffer<F>, outputs: &mut Buffer<F>) {
		todo!()
		/*for i in 0..F::CHANNELS {
			for (j, s) in inputs.as_slice().iter().enumerate() {
				self.input_buffers[i][j] = *s.channel(i);
			}

			self.shifters[i].process(&self.input_buffers[i], &mut self.output_buffers[i]);

			for (j, s) in outputs.as_slice_mut().iter_mut().enumerate() {
				*s.channel_mut(i) = self.output_buffers[i][j];
			}
		}*/
	}
}