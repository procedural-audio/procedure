use std::marker::PhantomData;

use pa_dsp::*;

#[derive(Copy, Clone)]
pub struct Equilibrium<F: Frame>(PhantomData<F>);

impl<F: Frame> Generator for Equilibrium<F> {
    type Output = F;

    fn reset(&mut self) {}

    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn generate(&mut self) -> Self::Output {
        F::EQUILIBRIUM
    }
}

pub const fn equilibrium<F: Frame>() -> AudioNode<Equilibrium<F>> {
    AudioNode(Equilibrium(PhantomData))
}
