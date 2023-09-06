use std::marker::PhantomData;

use pa_dsp::*;

pub struct Sine<S: Sample> {
    fSampleRate: i32,
    fConst1: f32,
    fConst2: f32,
    fHslider0: f32,
    fConst3: f32,
    fRec2: [f32; 2],
    fRec1: [f32; 2],
    sig: SineSIG0,
    data: PhantomData<S>
}

impl<S: Sample> Sine<S> {
    pub fn new() -> Self {
        Sine {
            fSampleRate: 0,
            fConst1: 0.0,
            fConst2: 0.0,
            fHslider0: 0.0,
            fConst3: 0.0,
            fRec2: [0.0; 2],
            fRec1: [0.0; 2],
            sig: newSineSIG0(),
            data: PhantomData
        }
    }

    fn get_sample_rate(&self) -> i32 {
        return self.fSampleRate;
    }
    fn get_num_inputs(&self) -> i32 {
        return 0;
    }
    fn get_num_outputs(&self) -> i32 {
        return 1;
    }

    fn class_init(sample_rate: i32) {
        let mut sig0: SineSIG0 = newSineSIG0();
        sig0.instance_initSineSIG0(sample_rate);
        sig0.fillSineSIG0(65536, unsafe { &mut ftbl0SineSIG0 });
    }

    fn instance_reset_params(&mut self) {
        self.fHslider0 = 0.100000001;
    }

    fn instance_clear(&mut self) {
        for l2 in 0..2 {
            self.fRec2[(l2) as usize] = 0.0;
        }
        for l3 in 0..2 {
            self.fRec1[(l3) as usize] = 0.0;
        }
    }

    fn instance_constants(&mut self, sample_rate: i32) {
        self.fSampleRate = sample_rate;
        let fConst0: f32 = f32::min(192000.0, f32::max(1.0, (self.fSampleRate) as f32));
        self.fConst1 = 1.0 / fConst0;
        self.fConst2 = 44.0999985 / fConst0;
        self.fConst3 = 1.0 - self.fConst2;
    }

    fn instance_init(&mut self, sample_rate: i32) {
        self.instance_constants(sample_rate);
        self.instance_reset_params();
        self.instance_clear();
    }

    fn init(&mut self, sample_rate: i32) {
        Sine::<S>::class_init(sample_rate);
        self.instance_init(sample_rate);
    }
}

impl<S: Sample> Pitched for Sine<S> {
    fn get_pitch(&self) -> f32 {
        self.fHslider0
    }

    fn set_pitch(&mut self, hz: f32) {
        self.fHslider0 = hz;
    }
}

impl<S: Sample> Generator for Sine<S> {
    type Output = S;

    fn reset(&mut self) {
        self.instance_clear();
    }

    fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
        self.init(sample_rate as i32);
    }

    fn generate(&mut self) -> Self::Output {
        let fSlow0: f32 = self.fConst2 * ((self.fHslider0) as f32);
        self.fRec2[0] = fSlow0 + self.fConst3 * self.fRec2[1];
        let fTemp0: f32 = self.fRec1[1] + self.fConst1 * self.fRec2[0];
        self.fRec1[0] = fTemp0 - f32::floor(fTemp0);
        let output = unsafe { ftbl0SineSIG0[((65536.0 * self.fRec1[0]) as i32) as usize] };
        self.fRec2[1] = self.fRec2[0];
        self.fRec1[1] = self.fRec1[0];
        return S::from_f32(output);
    }
}

static mut ftbl0SineSIG0: [f32; 65536] = [0.0; 65536];

pub struct SineSIG0 {
    iVec0: [i32; 2],
    iRec0: [i32; 2],
}

impl SineSIG0 {
    fn instance_initSineSIG0(&mut self, _sample_rate: i32) {
        for l0 in 0..2 {
            self.iVec0[(l0) as usize] = 0;
        }
        for l1 in 0..2 {
            self.iRec0[(l1) as usize] = 0;
        }
    }

    fn fillSineSIG0(&mut self, count: i32, table: &mut [f32]) {
        for i1 in 0..count {
            self.iVec0[0] = 1;
            self.iRec0[0] = (self.iVec0[1] + self.iRec0[1]) % 65536;
            table[(i1) as usize] = f32::sin(9.58738019e-05 * ((self.iRec0[0]) as f32));
            self.iVec0[1] = self.iVec0[0];
            self.iRec0[1] = self.iRec0[0];
        }
    }
}

pub fn newSineSIG0() -> SineSIG0 {
    SineSIG0 {
        iVec0: [0; 2],
        iRec0: [0; 2],
    }
}
