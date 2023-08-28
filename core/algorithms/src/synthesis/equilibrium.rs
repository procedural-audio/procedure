use std::marker::PhantomData;

use pa_dsp::*;

#[derive(Copy, Clone)]
pub struct Equilibrium<S: Sample>(PhantomData<S>);

impl<S: Sample> Generator for Equilibrium<S> {
    type Output = S;

    fn reset(&mut self) {}

    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn generate(&mut self) -> Self::Output {
        S::EQUILIBRIUM
    }
}

pub const fn equilibrium<S: Sample>() -> AudioNode<Equilibrium<S>> {
    AudioNode(Equilibrium(PhantomData))
}
