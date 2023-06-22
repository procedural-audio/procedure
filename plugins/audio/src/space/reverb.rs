use crate::*;

use pa_dsp::buffers::*;

pub struct Reverb {
    algorithm: usize,
    param_1: f32,
    param_2: f32,
    param_3: f32,
    param_4: f32,
    param_5: f32,
    param_6: f32,
}

pub struct ReverbVoice {
    delay: Delay<Stereo2<f32>>,
}

impl Module for Reverb {
    type Voice = ReverbVoice;

    const INFO: Info = Info {
        title: "Reverb",
        id: "default.space.reverb",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(300, 195),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Input", 15),
            Pin::Control("Mix", 45),
            Pin::Control("Decay", 75),
            Pin::Control("Control 3", 105),
            Pin::Control("Control 4", 135),
            Pin::Control("Control 4", 165),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 15),
        ],
        path: &["Audio", "Space", "Reverb"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            algorithm: 0,
            param_1: 0.0,
            param_2: 0.0,
            param_3: 0.0,
            param_4: 0.0,
            param_5: 0.0,
            param_6: 0.0,
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice {
            delay: Delay::new(512*100),
        }
    }

    fn load(&mut self, _version: &str, state: &State) {
        /*self.wave_index = state.load("wave_index");
        self.unison = state.load("unison");
        self.detune = state.load("detune");
        self.spread = state.load("spread");
        self.glide = state.load("glide");
        self.dropdown = state.load("dropdown");*/
    }

    fn save(&self, state: &mut State) {
        /*state.save("wave_index", self.wave_index);
        state.save("unison", self.unison);
        state.save("detune", self.detune);
        state.save("spread", self.spread);
        state.save("glide", self.glide);
        state.save("dropdown", self.dropdown);*/
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        let size_x = 60;
        let size_y = 75;
        let offset_x = 35;
        let offset_y = 35;

        return Box::new(Stack {
            children: (
                Transform {
                    position: (35, 125),
                    size: (110, 40),
                    child: Dropdown {
                        index: &mut self.algorithm,
                        color: Color::BLUE,
                        elements: &["Algo 1", "Algo 2", "Algo 3", "Algo 4"],
                    },
                },
                Transform {
                    position: (offset_x + size_x * 0, offset_y + size_y * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Mix",
                        color: Color::BLUE,
                        value: &mut self.param_1,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (offset_x + size_x * 1, offset_y + size_y * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Decay",
                        color: Color::BLUE,
                        value: &mut self.param_2,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (offset_x + size_x * 2, offset_y + size_y * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "PreDelay",
                        color: Color::BLUE,
                        value: &mut self.param_3,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (offset_x + size_x * 3, offset_y + size_y * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Size",
                        color: Color::BLUE,
                        value: &mut self.param_4,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (offset_x + size_x * 2, offset_y + size_y * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "Damp",
                        color: Color::BLUE,
                        value: &mut self.param_5,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (offset_x + size_x * 3, offset_y + size_y * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "ModRate",
                        color: Color::BLUE,
                        value: &mut self.param_6,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
            ),
        });
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.delay.prepare(sample_rate, block_size);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        voice.delay.set_delay_ms(100.0 * self.param_1);
        for (input, output) in inputs.audio[0].as_slice().iter().zip(outputs.audio[0].as_slice_mut()) {
            *output = voice.delay.process(*input);
        }
    }
}

fn temp() {
    let input = Buffer::init(0.0, 512);
    let mut output = Buffer::init(0.0, 512);

    let mut dsp1 = split(Delay::new(100));
    let out = dsp1.process(0.0);
    let mut dsp2 = merge(dsp1);
    let out = dsp2.process(0.0);

    let mut dsp1 = testdsp() >> testdsp();
    let out = dsp1.process(0.0);

    let mut dsp2 = (testdsp() | testdsp()) & testdsp() >> testdsp();
    let out = dsp2.process((0.0, 0.0));

    let mut dsp = testdsp() | testdsp() | pitcheddsp();
    let out = dsp.process(((0.0, 0.0), 0.0));

    let mut dsp = input2() >> gain(5.0) >> testdsp() >> pitcheddsp();

    let temp = AudioNode(
        Chain(
            Chain(
                TestDsp,
                TestDsp
            ),
            TestDsp
        )
    );
}

struct MultiChannel<P: Processor, const C: usize> {
    channels: [P; C],
}

impl<P: Processor, const C: usize> MultiChannel<P, C> {
}

struct Diffuser<const C: usize> {

}

impl<const C: usize> Processor2 for Diffuser<C> {
    type Input = Stereo2<f32>;
    type Output = Stereo2<f32>;

    fn process(&mut self, input: Self::Input) -> Self::Output {
        input
    }
}

struct Delay<F: Frame> {
    buffer: RingBuffer<F>,
    delay_ms: f32,
    sample_rate: u32
}

impl<F: Frame> Delay<F> {
    pub fn new(max_delay_samples: usize) -> Self {
        Self {
            buffer: RingBuffer::init(F::from(0.0), max_delay_samples),
            delay_ms: 0.0,
            sample_rate: 0,
        }
    }

    pub fn set_delay_samples(&mut self, delay: usize) {
        if delay <= self.buffer.capacity() {
            self.delay_ms = (delay as f32) / (self.sample_rate as f32) * 1000.0;
            self.buffer.resize(usize::max(delay, 1));
        } else {
            panic!("Delay resize to {} is larger than capacity {}", delay, self.buffer.capacity());
        }
    }

    pub fn set_delay_ms(&mut self, ms: f32) {
        let delay_samples = (ms / 1000.0) * (self.sample_rate as f32);
        self.set_delay_samples(delay_samples as usize);
    }

    pub fn delay_ms(&self) -> f32 {
        self.delay_ms
    }

    pub fn delay_samples(&self) -> usize {
        self.buffer.len()
    }
}

impl<F: Frame> Processor2 for Delay<F> {
    type Input = F;
    type Output = F;

    fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
        self.sample_rate = sample_rate;
        self.set_delay_ms(self.delay_ms);
    }

    fn process(&mut self, input: Self::Input) -> Self::Output {
        self.buffer.next(input)
    }
}

struct Verb1<F: Frame> {
    delay: Delay<F>,
}

impl<F: Frame> Processor for Verb1<F> {
    type Item = F;

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        
    }

    fn process(&mut self, input: Self::Item) -> Self::Item {
        self.delay.process(input)
    }
}
