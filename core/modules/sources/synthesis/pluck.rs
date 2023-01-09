use crate::*;

use pa_dsp::AudioBuffer;

// https://github.com/electro-smith/DaisySP/blob/master/Source/PhysicalModeling/stringvoice.h

pub struct Pluck {
    wave_index: u32,
    unison: f32,
    detune: f32,
    spread: f32,
    glide: f32,
    dropdown: u32,
}

pub struct PluckVoice {
    string: KarplusString,
}

impl Module for Pluck {
    type Voice = PluckVoice;

    const INFO: Info = Info {
        title: "Pluck",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(310, 200),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Midi Input", 20),
            Pin::Audio("Input 1", 50),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 20),
            Pin::Audio("Audio Output", 50)
        ],
        path: "Category 1/Category 2/Module Name"
    };

    fn new() -> Self {
        Self {
            wave_index: 0,
            unison: 1.0,
            detune: 0.0,
            spread: 0.0,
            glide: 0.0,
            dropdown: 0,
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        println!("Created voice {}", index);

        Self::Voice {
            string: KarplusString::new()
        }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        let size = 50;

        return Box::new(Stack {
            children: (
                Positioned {
                    position: (40 + size * 0, 40 + size * 0),
                    child: SizedBox {
                        size: (50, 50),
                        child: SvgButton {
                            path: "waveforms/saw.svg",
                            pressed: self.wave_index == 1,
                            color: Color::BLUE,
                            on_changed: Box::new(|pressed| {
                                println!("Saw is {}", pressed);
                                if pressed {
                                    unsafe {
                                        *((&self.wave_index as *const u32) as *mut u32) = 0;
                                    }

                                    //ui.refresh();
                                }
                            }),
                        },
                    },
                },
                Positioned {
                    position: (40 + size * 1, 40 + size * 0),
                    child: SizedBox {
                        size: (50, 50),
                        child: SvgButton {
                            path: "waveforms/square.svg",
                            pressed: self.wave_index == 2,
                            color: Color::BLUE,
                            on_changed: Box::new(|pressed| {
                                if pressed {
                                    unsafe {
                                        *((&self.wave_index as *const u32) as *mut u32) = 1;
                                    }

                                    //ui.refresh();
                                }
                            }),
                        },
                    },
                },
                Positioned {
                    position: (40 + size * 0, 40 + size * 1),
                    child: SizedBox {
                        size: (50, 50),
                        child: SvgButton {
                            path: "waveforms/sine.svg",
                            pressed: self.wave_index == 3,
                            color: Color::BLUE,
                            on_changed: Box::new(|pressed| {
                                if pressed {
                                    unsafe {
                                        *((&self.wave_index as *const u32) as *mut u32) = 2;
                                    }

                                    //ui.refresh();
                                }
                            }),
                        },
                    },
                },
                Positioned {
                    position: (40 + size * 1, 40 + size * 1),
                    child: SizedBox {
                        size: (50, 50),
                        child: SvgButton {
                            path: "waveforms/triangle.svg",
                            pressed: self.wave_index == 4,
                            color: Color::BLUE,
                            on_changed: Box::new(|pressed| {
                                if pressed {
                                    unsafe {
                                        *((&self.wave_index as *const u32) as *mut u32) = 3;
                                    }

                                    //ui.refresh();
                                }
                            }),
                        },
                    },
                },
                Transform {
                    position: (45, 40 + 100),
                    size: (90, 40),
                    child: Dropdown {
                        index: &mut self.dropdown,
                        color: Color::BLUE,
                        elements: &["Pluck 1", "Pluck 2", "Pluck 3", "Pluck 4"],
                    },
                },
                Transform {
                    position: (60 + size * 2, 40 + size * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Unison",
                        color: Color::BLUE,
                        value: &mut self.unison,
                        feedback: Box::new(|value| {
                            let mut unison = value * 6.0 + 2.0;

                            if unison < 1.0 {
                                unison = 1.0;
                            }

                            if unison > 8.0 {
                                unison = 8.0;
                            }

                            format!("{:.2}", unison)
                        }),
                    },
                },
                Transform {
                    position: (60 + size * 3 + 10, 40 + size * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Detune",
                        color: Color::BLUE,
                        value: &mut self.detune,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (60 + size * 2, 40 + 70 * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "Spread",
                        color: Color::BLUE,
                        value: &mut self.spread,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (60 + size * 3 + 10, 40 + 70 * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "Glide",
                        color: Color::BLUE,
                        value: &mut self.glide,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
            ),
        });
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.string.init(sample_rate as f32);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let mut done = false;

        for (out, inp) in outputs.audio[0].as_slice_mut().iter_mut().zip(inputs.audio[0].as_slice()) {
            let sample = voice.string.process(inp.left);
            out.left = sample;
            out.right = sample;

            if !done {
                println!("{}", sample);
                done = true;
            }
        }
    }
}

const NON_LINEARITY_CURVED_BRIDGE: usize = 0;
const NON_LINEARITY_DISPERSION: usize = 1;
const DELAY_LINE_SIZE: usize = 1024;
const RAND_FRAC: f32 = 1.0 / f32::MAX;

pub fn rand() -> f32 {
    rand::random()
}

pub fn fonepole(out: &mut f32, inp: f32, coeff: f32) {
	*out += coeff * (inp - *out);
}

struct KarplusString {
	non_linearity: usize, // Set to one of NON_LINEARITY constants
	
	string: DelayLine<DELAY_LINE_SIZE>,
	stretch: DelayLine<{DELAY_LINE_SIZE / 4}>,

	frequency: f32,
	non_linearity_amount: f32,
	brightness: f32,
	damping: f32,

    sample_rate: f32,

	iir_damping_filter: Tone,
	dc_blocker: DcBlock,
	crossfade: Crossfade,
	
	dispersion_noise: f32,
	curved_bridge: f32,
	
	src_phase: f32,
	out_sample: [f32; 2]
}

impl KarplusString {
    pub fn new() -> Self {
        Self {
            non_linearity: NON_LINEARITY_CURVED_BRIDGE,
            string: DelayLine::new(),
            stretch: DelayLine::new(),
            frequency: 440.0,
            non_linearity_amount: 0.5,
            brightness: 0.5,
            damping: 0.5,
            sample_rate: 44100.0,
            iir_damping_filter: Tone::new(),
            dc_blocker: DcBlock::new(),
            crossfade: Crossfade::new(),
            dispersion_noise: 0.5,
            curved_bridge: 0.5,
            src_phase: 0.5,
            out_sample: [0.0, 0.0]
        }
    }

	/// Initialize the processor
	fn init(&mut self, sample_rate: f32) {
		self.sample_rate = sample_rate;
		self.set_freq(440.0);
		self.non_linearity_amount = 0.5;
		self.brightness = 0.5;
		self.damping = 0.5;
		
		self.string.init();
		self.stretch.init();
		self.reset();
		
		self.set_freq(440.0);
		self.set_damping(0.8);
		self.set_nonlinearity(0.1);
		self.set_brightness(0.5);
		
		self.crossfade.init();
	}
	
	/// Clear the delay line
	fn reset(&mut self) {
		self.string.reset();
		self.stretch.reset();
		self.iir_damping_filter.init(self.sample_rate);
		
		self.dc_blocker.init(self.sample_rate);
		
		self.dispersion_noise = 0.0;
		self.curved_bridge = 0.0;
		self.out_sample = [0.0, 0.0];
		self.src_phase = 0.0;
	}

	/// Set the string frequency
	fn set_freq(&mut self, freq: f32) {
		let freq = freq / self.sample_rate;
		self.frequency = f32::clamp(freq, 0.0, 0.25);
	}
	
	/// Set the string behavior. Param -1 to 0 is curved bridge, 0 to 1 is dispersion
	fn set_nonlinearity(&mut self, amount: f32) {
		self.non_linearity_amount = f32::clamp(amount, 0.0, 1.0);
	}
	/// Set string brightness. Param 0 to 1
	fn set_brightness(&mut self, brightness: f32) {
		self.brightness = f32::clamp(brightness, 0.0, 1.0);
	}
	
	/// Set damping. Param 0 to 1
	fn set_damping(&mut self, damping: f32) {
		self.damping = f32::clamp(damping, 0.0, 1.0);
	}
	
	///Get the next floating point sample
	fn process(&mut self, inp: f32) -> f32 {
		if self.non_linearity_amount <= 0.0 {
			self.non_linearity_amount *= -1.0;
			let ret = self.process_internal::<NON_LINEARITY_CURVED_BRIDGE>(inp);
			self.non_linearity_amount *= -1.0;
			return ret;
		} else {
			return self.process_internal::<NON_LINEARITY_DISPERSION>(inp);
		}
	}
	
	fn process_internal<const T: usize>(&mut self, inp: f32) -> f32 {
		let mut brightness = self.brightness;
		let mut delay = 1.0 / self.frequency;
		delay = f32::clamp(delay, 4.0, DELAY_LINE_SIZE as f32 - 4.0);
		
		// If there is not enough delay time in the delay line, we play at the
		// lowest possible note and we upsample on the fly with a shitty linear
		// interpolator. We don't care because it's a corner case (frequency_ < 11.7Hz)
		let mut src_ratio = delay * self.frequency;
		if src_ratio >= 0.9999 {
			// When above 11.7 Hz, we make sure linear interpolator
			// does not get inp the way
			
			self.src_phase = 1.0;
			src_ratio = 1.0;
		}
		
		let mut damping_cutoff = f32::min(12.0 + self.damping * self.damping * 60.0 + brightness * 24.0, 84.0);
		let mut damping_f = f32::min(self.frequency * f32::powf(2.0, damping_cutoff * (1.0 / 12.0)), 0.499);
		
		// Crossfade to infinite decay
		if self.damping >= 0.95 {
			let to_infinite = 20.0 * (self.damping - 0.95);
			brightness += to_infinite * (1.0 - brightness);
			damping_f += to_infinite * (0.4999 - damping_f);
			damping_cutoff += to_infinite * (128.0 - damping_cutoff);
		}
		
		let temp_f = damping_f * self.sample_rate;
		self.iir_damping_filter.set_freq(temp_f);
		
		let ratio = f32::powf(2.0, damping_cutoff * (1.0 / 12.0));
		let damping_compensation = 1.0 - 2.0 * f32::atan(1.0 / ratio) / (std::f32::consts::PI * 2.0);
		let stretch_point = self.non_linearity_amount * (2.0 - self.non_linearity_amount) * 0.225;
		let stretch_correction = f32::clamp((160.0 / self.sample_rate) * delay, 1.0, 2.1);
		let noise_amount_sqrt = if self.non_linearity_amount > 0.75 {
			4.0 * (self.non_linearity_amount - 0.75)
		} else {
			0.0
		};
		
		let noise_amount = noise_amount_sqrt * noise_amount_sqrt * 0.1;
		let noise_filter = 0.06 + 0.94 * brightness * brightness;
		
		let bridge_curving_sqrt = self.non_linearity_amount;
		let bridge_curving = bridge_curving_sqrt * bridge_curving_sqrt * 0.01;
		
		let ap_gain = -0.618 * self.non_linearity_amount / (0.15 + f32::abs(self.non_linearity_amount));
		self.src_phase += src_ratio;
		
		if self.src_phase > 1.0 {
			self.src_phase -= 1.0;
			
			delay = delay * damping_compensation;
			let mut s = 0.0;
			
			if T == NON_LINEARITY_DISPERSION {
				let noise = rand() * RAND_FRAC - 0.5;
				fonepole(&mut self.dispersion_noise, noise, noise_filter);
				delay *= 1.0 + self.dispersion_noise * noise_amount;
			} else {
				delay *= 1.0 - self.curved_bridge * bridge_curving;
			}
			
			if self.non_linearity == NON_LINEARITY_DISPERSION {
				let ap_delay = delay * stretch_point;
				let main_delay = delay - ap_delay * (0.408 - stretch_point * 0.308) * stretch_correction;
				
				if ap_delay >= 4.0 && main_delay >= 4.0 {
					s = self.string.read(main_delay);
					s = self.stretch.allpass(s, f32::floor(ap_delay) as usize, ap_gain);
				} else {
					s = self.string.read_hermite(delay);
				}
			} else {
				s = self.string.read_hermite(delay);
			}
			
			if (self.non_linearity == NON_LINEARITY_CURVED_BRIDGE) {
				let value = f32::abs(s) - 0.025;
				let sign = if s > 0.0 { 1.0 } else { -1.5 };
				self.curved_bridge = (f32::abs(value) + value) * sign;
			}
			
			s += inp;
			s = f32::clamp(s, -20.0, 20.0);
			s = self.dc_blocker.process(s);
			
			s = self.iir_damping_filter.process(s);
			self.string.write(s);
			
			self.out_sample[1] = self.out_sample[0];
			self.out_sample[0] = s;
		}
		
		self.crossfade.set_pos(self.src_phase);
		return self.crossfade.process(self.out_sample[1], self.out_sample[0]);
	}
}

#[derive(Copy, Clone)]
enum CrossfadeType {
	Linear,
	ConstantPower,
	Logarithmic,
	Exponential
}

struct Crossfade {
	pos: f32,
	curve: CrossfadeType
}

impl Crossfade {
    pub fn new() -> Self {
        Self {
            pos: 0.0,
            curve: CrossfadeType::Linear
        }
    }

	fn init(&mut self) {
		self.init_curve(CrossfadeType::Linear);
	}
	
	fn init_curve(&mut self, curve: CrossfadeType) {
		self.pos = 0.5;
		self.curve = curve;
	}
	
	fn set_pos(&mut self, pos: f32) {
		self.pos = pos;
	}
	
	fn set_curve(&mut self, curve: CrossfadeType) {
		self.curve = curve;
	}
	
	fn get_curve(&self) -> CrossfadeType {
		self.curve
	}
	
	fn process(&mut self, in1: f32, in2: f32) -> f32 {
        let CROSS_LOG_MIN: f32 = f32::log10(0.000001);
        let CROSS_LOG_MAX: f32 = f32::log10(1.0);

		let mut scalar_1 = 0.0;
		let mut scalar_2 = 0.0;
		
		match self.curve {
			CrossfadeType::Linear => {
				scalar_1 = self.pos;
				return (in1 * (1.0 - scalar_1)) + (in2 * scalar_1);
			},
			CrossfadeType::ConstantPower => {
				scalar_1 = f32::sin(self.pos * std::f32::consts::PI / 2.0);
				scalar_2 = f32::sin((1.0 - self.pos) * std::f32::consts::PI / 2.0);
				return (in1 * scalar_2) + (in2 * scalar_1);
			},
			CrossfadeType::Logarithmic => {
				scalar_1 = f32::exp(self.pos * (CROSS_LOG_MAX - CROSS_LOG_MIN) + CROSS_LOG_MIN);
				return (in1 * (1.0 - scalar_1)) + (in2 * scalar_1);
			},
			CrossfadeType::Exponential => {
				scalar_1 = self.pos * self.pos;
				return (in1 * (1.0 - scalar_1)) + (in2 * scalar_1);
			}
		}
	}
}

struct DcBlock {
	input: f32,
	output: f32,
	gain: f32
}

impl DcBlock {
    pub fn new() -> Self {
        Self {
            input: 0.0,
            output: 0.0,
            gain: 0.0
        }
    }

	pub fn init(&mut self, sample_rate: f32) {
		self.input = 0.0;
		self.output = 0.0;
		self.gain = 0.99;
	}
	
	pub fn process(&mut self, inp: f32) -> f32 {
		let out = inp - self.input + (self.gain * self.output);
		self.output = out;
		self.input = inp;
		return out;
	}
}

struct DelayLine<const C: usize> {
    frac: f32,
	write_ptr: usize,
	delay: usize,
	line: [f32; C]
}

impl<const C: usize> DelayLine<C> {
    pub fn new() -> Self {
        Self {
            frac: 0.0,
            write_ptr: 0,
            delay: 0,
            line: [0.0; C]
        }
    }

	pub fn init(&mut self) {
		self.reset();
	}
	
	pub fn reset(&mut self) {
		for s in &mut self.line {
			*s = 0.0;
		}
		
		self.write_ptr = 0;
		self.delay = 1;
	}
	
	pub fn set_delay_usize(&mut self, delay: usize) {
		self.frac = 0.0;
		self.delay = if delay < C { delay } else { C - 1 };
	}
	
	pub fn set_delay_f32(&mut self, delay: f32) {
		let int_delay = f32::floor(delay) as u32;
		self.frac = delay - int_delay as f32;
		self.delay = if (int_delay as usize) < C { int_delay as usize } else { C - 1 };
	}
	
	pub fn write(&mut self, sample: f32) {
		self.line[self.write_ptr] = sample;
		self.write_ptr = (self.write_ptr - 1 + C) % C;
	}
	
	pub fn read(&self, delay: f32) -> f32 {
		let a = self.line[(self.write_ptr + f32::floor(delay) as usize) % C];
		let b = self.line[(self.write_ptr + f32::floor(delay) as usize + 1) % C];
		return a + (b - a) * self.frac;
	}
	
	pub fn read_delay(&self, delay: f32) -> f32 {
		let delay_integral = f32::floor(delay) as u32;
		let delay_fractional = delay - delay_integral as f32;
		let a = self.line[(self.write_ptr + delay_integral as usize) % C];
		let b = self.line[(self.write_ptr + delay_integral as usize + 1) % C];
		return a + (b - a) * delay_fractional;
	}
	
	pub fn read_hermite(&self, delay: f32) -> f32 {
		let delay_integral = f32::floor(delay) as u32;
		let delay_fractional = delay - delay_integral as f32;
		
		let t = self.write_ptr + delay_integral as usize + C;
		let xm1 = self.line[(t - 1) % C];
		let x0 = self.line[t % C];
		let x1 = self.line[(t + 1) % C];
		let x2 = self.line[(t + 2) % C];
		let c = (x1 - xm1) * 0.5;
		let v = x0 - x1;
		let w = c + v;
		let a = w + v + (x2 - x0) * 0.5;
		let b_neg = w + a;
		let f = delay_fractional;
		return (((a * f) - b_neg) * f + c) * f + x0;
	}
	
	pub fn allpass(&mut self, sample: f32, delay: usize, coefficient: f32) -> f32 {
		let read = self.line[(self.write_ptr + delay) % C];
		let write = sample + coefficient * read;
		self.write(write);
		return -write * coefficient + read;
	}
}

struct Tone {
	out: f32,
	prevout: f32,
	inp: f32,
	freq: f32,
	c1: f32,
	c2: f32,
	sample_rate: f32
}

impl Tone {
    pub fn new() -> Self {
        Self {
            out: 0.0,
            prevout: 0.0,
            inp: 0.0,
            freq: 440.0,
            c1: 0.0,
            c2: 0.0,
            sample_rate: 44100.0
        }
    }

	pub fn init(&mut self, sample_rate: f32) {
		self.prevout = 0.0;
		self.freq = 100.0;
		self.c1 = 0.5;
		self.c2 = 0.5;
		self.sample_rate = sample_rate;
	}
	
	pub fn process(&mut self, sample: f32) -> f32 {
		let out = self.c1 * self.inp + self.c2 * self.prevout;
		self.prevout = out;
		return out;
	}
	
	pub fn set_freq(&mut self, freq: f32) {
		self.freq = freq;
		self.calculate_coefficients();
	}
	
	pub fn get_freq(&self) -> f32 {
		self.freq
	}
	
	fn calculate_coefficients(&mut self) {
		let b = 2.0 - f32::cos(std::f32::consts::PI * 2.0 * self.freq / self.sample_rate);
		let c2 = b - f32::sqrt(b * b - 1.0);
		let c1 = 1.0 - c2;
		self.c1 = c1;
		self.c2 = c2;
	}
}