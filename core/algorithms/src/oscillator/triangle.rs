use std::marker::PhantomData;

use pa_dsp::{Sample, Generator, Pitched};

fn triangle_faustpower2_f(value: f32) -> f32 {
    return value * value;
}

pub struct Triangle<S: Sample> {
    fSampleRate: i32,
    fConst1: f32,
    fConst2: f32,
    fHslider0: f32,
    fConst3: f32,
    iVec0: [i32; 2],
    fRec0: [f32; 2],
    fConst4: f32,
    fConst5: f32,
    fRec2: [f32; 2],
    fVec1: [f32; 2],
    IOTA0: i32,
    fVec2: Box<[f32; 4096]>,
    fConst6: f32,
    fRec1: [f32; 2],
    data: PhantomData<S>
}

impl<S: Sample> Triangle<S> {
    pub fn new() -> Self {
        Triangle {
            fSampleRate: 0,
            fConst1: 0.0,
            fConst2: 0.0,
            fHslider0: 0.0,
            fConst3: 0.0,
            iVec0: [0; 2],
            fRec0: [0.0; 2],
            fConst4: 0.0,
            fConst5: 0.0,
            fRec2: [0.0; 2],
            fVec1: [0.0; 2],
            IOTA0: 0,
            fVec2: Box::new([0.0; 4096]),
            fConst6: 0.0,
            fRec1: [0.0; 2],
            data: PhantomData
        }
    }

    fn instance_reset_params(&mut self) {
        self.fHslider0 = 500.0;
    }

    fn instance_clear(&mut self) {
        for l0 in 0..2 {
            self.iVec0[(l0) as usize] = 0;
        }
        for l1 in 0..2 {
            self.fRec0[(l1) as usize] = 0.0;
        }
        for l2 in 0..2 {
            self.fRec2[(l2) as usize] = 0.0;
        }
        for l3 in 0..2 {
            self.fVec1[(l3) as usize] = 0.0;
        }
        self.IOTA0 = 0;
        for l4 in 0..4096 {
            self.fVec2[(l4) as usize] = 0.0;
        }
        for l5 in 0..2 {
            self.fRec1[(l5) as usize] = 0.0;
        }
    }

    fn instance_constants(&mut self, sample_rate: i32) {
        self.fSampleRate = sample_rate;
        let fConst0: f32 = f32::min(192000.0, f32::max(1.0, (self.fSampleRate) as f32));
        self.fConst1 = 4.0 / fConst0;
        self.fConst2 = 44.0999985 / fConst0;
        self.fConst3 = 1.0 - self.fConst2;
        self.fConst4 = 0.25 * fConst0;
        self.fConst5 = 1.0 / fConst0;
        self.fConst6 = 0.5 * fConst0;
    }

    fn instance_init(&mut self, sample_rate: i32) {
        self.instance_constants(sample_rate);
        self.instance_reset_params();
        self.instance_clear();
    }

    fn init(&mut self, sample_rate: i32) {
        self.instance_init(sample_rate);
    }
}

impl<S: Sample> Pitched for Triangle<S> {
    fn get_pitch(&self) -> f32 {
        self.fHslider0
    }

    fn set_pitch(&mut self, hz: f32) {
        self.fHslider0 = hz;
    }
}

impl<S: Sample> Generator for Triangle<S> {
    type Output = S;

    fn reset(&mut self) {
        self.instance_reset_params();
        self.instance_clear();
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        self.init(sample_rate as i32);
    }

    fn generate(&mut self) -> Self::Output {
        let fSlow0: f32 = self.fConst2 * ((self.fHslider0) as f32);
        self.iVec0[0] = 1;
        self.fRec0[0] = fSlow0 + self.fConst3 * self.fRec0[1];
        let fTemp0: f32 = f32::max(self.fRec0[0], 23.4489498);
        let fTemp1: f32 = f32::max(20.0, f32::abs(fTemp0));
        let fTemp2: f32 = self.fRec2[1] + self.fConst5 * fTemp1;
        self.fRec2[0] = fTemp2 - f32::floor(fTemp2);
        let fTemp3: f32 = triangle_faustpower2_f(2.0 * self.fRec2[0] + -1.0);
        self.fVec1[0] = fTemp3;
        let fTemp4: f32 = (((self.iVec0[1]) as f32) * (fTemp3 - self.fVec1[1])) / fTemp1;
        self.fVec2[(self.IOTA0 & 4095) as usize] = fTemp4;
        let fTemp5: f32 = f32::max(0.0, f32::min(2047.0, self.fConst6 / fTemp0));
        let iTemp6: i32 = (fTemp5) as i32;
        let fTemp7: f32 = f32::floor(fTemp5);
        self.fRec1[0] = 0.999000013 * self.fRec1[1]
            + self.fConst4
                * (fTemp4
                    - self.fVec2[((self.IOTA0 - iTemp6) & 4095) as usize]
                        * (fTemp7 + 1.0 - fTemp5)
                    - (fTemp5 - fTemp7)
                        * self.fVec2[((self.IOTA0 - (iTemp6 + 1)) & 4095) as usize]);
        let output = (self.fConst1 * self.fRec0[0] * self.fRec1[0]) as f32;
        self.iVec0[1] = self.iVec0[0];
        self.fRec0[1] = self.fRec0[0];
        self.fRec2[1] = self.fRec2[0];
        self.fVec1[1] = self.fVec1[0];
        self.IOTA0 = self.IOTA0 + 1;
        self.fRec1[1] = self.fRec1[0];
        return S::from_f32(output);
    }
}
