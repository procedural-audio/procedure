mod ml;
mod space;
mod dynamics;
mod synthesis;
mod utilities;
mod distortion;
mod oscillator;

pub use ml::*;
pub use space::*;
pub use dynamics::*;
pub use synthesis::*;
pub use utilities::*;
pub use distortion::*;
pub use oscillator::*;

pub const fn input<'a, B: Block>(block: &'a B) -> AudioNode<Input<'a, B>> {
    AudioNode(Input(block))
}

pub struct Input<'a, B: Block>(&'a B);

impl<'a, B: Block> Generator for Input<'a, B> {
    type Output = B::Item;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn generate(&mut self) -> Self::Output {
        todo!()
    }
}

pub struct Output<'a, B: BlockMut>(&'a B);
