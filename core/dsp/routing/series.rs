use crate::traits::*;
use crate::float::frame::Frame;

#[derive(Copy, Clone)]
pub struct Series<F: Frame, A: Processor2<Input = F, Output = F>, const C: usize>(pub [A; C]);

impl<F: Frame, A: Processor2<Input = F, Output = F>, const C: usize> Processor2 for Series<F, A, C> {
    type Input = F;
    type Output = F;

    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, input: F) -> F {
        let mut v = input;
        for p in &mut self.0 {
           v = p.process(v);
        }

        return v;
    }
}
