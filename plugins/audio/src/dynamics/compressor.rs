use std::marker::PhantomData;

use crate::*;

pub struct Compressor {
    input_rms: f32,
    output_rms: f32,
    threshold: f32,
    ratio: f32,
    attack: f32,
    release: f32,
}

pub struct CompressorVoice {
    index: u32,
    compressor: CompressorDSP<Stereo2<f32>>,
}

impl Module for Compressor {
    type Voice = CompressorVoice;

    const INFO: Info = Info {
        title: "Compressor",
        id: "default.effects.dynamics.compressor",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(345, 200),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 25),
            Pin::Control("Threshold", 55),
            Pin::Control("Ratio", 85),
            Pin::Control("Attack", 85 + 30),
            Pin::Control("Release", 85 + 60),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 25)
        ],
        path: &["Audio", "Dynamics", "Compressor"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            input_rms: 0.5,
            output_rms: 0.3,
            threshold: 0.0,
            ratio: 1.0,
            attack: 0.0,
            release: 0.0,
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice {
            index,
            compressor: CompressorDSP::new()
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Padding {
            padding: (10, 10, 10, 10),
            child: Stack {
                children: (
                    Transform {
                        position: (30, 25),
                        size: (50, 70),
                        child: Knob {
                            text: "Threshold",
                            color: Color::BLUE,
                            value: &mut self.threshold,
                            feedback: Box::new(|_v| String::new())
                        }
                    },
                    Transform {
                        position: (30, 100),
                        size: (50, 70),
                        child: Knob {
                            text: "Ratio",
                            color: Color::BLUE,
                            value: &mut self.attack,
                            feedback: Box::new(|_v| String::new())
                        }
                    },
                    Transform {
                        position: (30 + 60, 25),
                        size: (50, 70),
                        child: Knob {
                            text: "Attack",
                            color: Color::BLUE,
                            value: &mut self.ratio,
                            feedback: Box::new(|_v| String::new())
                        }
                    },
                    Transform {
                        position: (30 + 60, 100),
                        size: (50, 70),
                        child: Knob {
                            text: "Release",
                            color: Color::BLUE,
                            value: &mut self.release,
                            feedback: Box::new(|_v| String::new())
                        }
                    },
                    Transform {
                        position: (100 + 60, 25),
                        size: (140, 140),
                        child: Background {
                            color: Color(0xff141414),
                            border: Border::radius(5),
                            child: Stack {
                                children: (
                                    Plotter {
                                        value: &self.output_rms,
                                        color: Color::RED,
                                        thickness: 2.0
                                    },
                                    Plotter {
                                        value: &self.input_rms,
                                        color: Color::BLUE,
                                        thickness: 2.0
                                    }
                                )
                            }
                        }
                    }
                )
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if voice.index == 0 {
            self.input_rms = 0.0;
        }

        let mut threshold = self.threshold;
        let mut ratio = self.ratio;
        let mut attack = self.attack;
        let mut release = self.release;

        if inputs.control.connected(0) {
            threshold = inputs.control[0];
        }

        if inputs.control.connected(1) {
            ratio = inputs.control[0];
        }

        if inputs.control.connected(2) {
            attack = inputs.control[0];
        }

        if inputs.control.connected(3) {
            release = inputs.control[0];
        }

        voice.compressor.process_block(&inputs.audio[0], &mut outputs.audio[0]);

        self.input_rms = f32::max(inputs.audio[0].rms().mono() * 2.0, self.input_rms);
        self.output_rms = voice.compressor.ballistics_filter.prev;
    }
}

pub struct CompressorDSP<F: Frame> {
    ballistics_filter: BallisticsFilter,
    threshold: f32,
    threshold_inverse: f32,
    ratio: f32,
    ratio_inverse: f32,
    attack: f32,
    release: f32,
    sample_rate: f32,
    data: PhantomData<F>
}

impl<F: Frame> CompressorDSP<F> {
    pub fn new() -> Self {
        Self {
            ballistics_filter: BallisticsFilter::new(),
            threshold: 0.0,
            threshold_inverse: 0.0,
            ratio: 0.0,
            ratio_inverse: 0.0,
            attack: 0.0,
            release: 0.0,
            sample_rate: 44100.0,
            data: PhantomData
        }
    }

    pub fn set_threshold(&mut self, db: f32) {
        self.threshold = db;
        self.update();
    }

    pub fn set_ratio(&mut self, ratio: f32) {
        self.ratio = ratio;
        self.update();
    }

    pub fn set_attack(&mut self, ms: f32) {
        self.attack = ms;
        self.update();
    }

    pub fn set_release(&mut self, ms: f32) {
        self.release = ms;
        self.update();
    }

    fn reset(&mut self) {
        self.ballistics_filter.reset();
    }

    fn update(&mut self) {
        self.threshold = db_to_gain_floor(self.threshold, -200.0);
        self.threshold_inverse = 1.0 / self.threshold;
        self.ratio_inverse = 1.0 / self.ratio;

        self.ballistics_filter.set_attack(self.attack);
        self.ballistics_filter.set_release(self.release);
    }
}

impl<F: Frame> Processor2 for CompressorDSP<F> {
    type Input = F;
    type Output = F;

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        self.sample_rate = sample_rate as f32;
        self.ballistics_filter.prepare(sample_rate, block_size);
        self.update();
        self.reset();
    }

    fn process(&mut self, input: Self::Input) -> Self::Output {
        let env = self.ballistics_filter.process(input.mono());

        let gain = if env < self.threshold {
            1.0
        } else {
            f32::powf(env * self.threshold_inverse, self.ratio_inverse - 1.0)
        };

        F::from(gain) * input
    }
}

#[derive(Clone, Copy, PartialEq)]
pub enum LevelType {
    Peak,
    Rms
}

pub struct BallisticsFilter {
    prev: f32,
    sample_rate: f32,
    exp_factor: f32,
    attack: f32,
    release: f32,
    cte_attack: f32,
    cte_release: f32,
    level: LevelType
}

impl BallisticsFilter {
    pub fn new() -> Self {
        Self {
            prev: 0.0,
            sample_rate: 44100.0,
            exp_factor: 0.0,
            attack: 0.0,
            release: 0.0,
            cte_attack: 0.0,
            cte_release: 0.0,
            level: LevelType::Peak
        }
    }

    pub fn set_attack(&mut self, ms: f32) {
        self.attack = ms;
        self.cte_attack = self.calculate_limited_cte(ms);
    }

    pub fn set_release(&mut self, ms: f32) {
        self.release = ms;
        self.cte_release = self.calculate_limited_cte(ms);
    }

    pub fn set_level_type(&mut self, level: LevelType) {
        self.level = level;
    }

    fn calculate_limited_cte(&self, ms: f32) -> f32 {
        if ms < 1.0e-3 {
            0.0
        } else {
            f32::exp(self.exp_factor * ms)
        }
    }

    pub fn reset(&mut self) {
        self.prev = 0.0;
    }
}

impl Processor2 for BallisticsFilter {
    type Input = f32;
    type Output = f32;

    fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
        self.sample_rate = sample_rate as f32;
        self.exp_factor = -2.0 * std::f32::consts::PI * 1000.0 / self.sample_rate;

        self.set_attack(self.attack);
        self.set_release(self.release);
    }

    fn process(&mut self, mut input: Self::Input) -> Self::Output {
        match self.level {
            LevelType::Peak => input *= input,
            LevelType::Rms => input = f32::abs(input)
        }

        let cte = if input > self.prev {
            self.cte_attack
        } else {
            self.cte_release
        };

        let result = input + cte * (self.prev - input);

        if self.level == LevelType::Rms {
            f32::sqrt(result)
        } else {
            result
        }
    }
}
