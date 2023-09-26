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

pub const fn input<'a, I: Copy, B: Block<Item = I>>(block: &'a B) -> AudioNode<Input<'a, I, B>> {
    AudioNode(Input(block))
}

pub struct Input<'a, I: Copy, B: Block<Item = I>>(&'a B);

impl<'a, I: Copy, B: Block<Item = I>> BlockGenerator for Input<'a, I, B> {
    type Output = I;

    fn generate_block<OutBuffer: BlockMut<Item = I>>(&mut self, output: &mut OutBuffer) {
        output.copy_from(self.0);
    }
}

pub struct Output<'a, B: BlockMut>(&'a B);
