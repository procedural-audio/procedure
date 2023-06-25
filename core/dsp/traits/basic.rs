use crate::block::*;

pub type Process<F> = Box<dyn Processor2<Input = F, Output = F>>;
pub type Generate<F> = Box<dyn Generator<Output = F>>;

pub trait Generator {
    type Output;

    fn reset(&mut self);
    // fn set_parameter(&mut self, name: &'static str, value: f32) {}
    fn prepare(&mut self, sample_rate: u32, block_size: usize);
    fn update(&mut self) {} // Update state
    fn gen(&mut self) -> Self::Output;
}

pub trait Processor2 {
    type Input;
    type Output;

    // fn set_parameter(&mut self, name: &'static str, value: f32) {}
    fn update(&mut self) {} // Update state
    fn prepare(&mut self, sample_rate: u32, block_size: usize) {}
    fn process(&mut self, input: Self::Input) -> Self::Output;
}

pub trait BlockGenerator: Generator {
    fn generate_block<OutBuffer: BlockMut<Item = Self::Output>>(&mut self, output: &mut OutBuffer);
}

impl<Out, G: Generator<Output = Out>> BlockGenerator for G {
    fn generate_block<OutBuffer: BlockMut<Item = Self::Output>>(&mut self, output: &mut OutBuffer) {
        self.update();
        for dest in output.as_slice_mut().iter_mut() {
            *dest = self.gen();
        }
    }
}

pub trait BlockProcessor: Processor2 {
    fn process_block<InBuffer, OutBuffer>(&mut self, input: &InBuffer, output: &mut OutBuffer)
        where
            InBuffer: Block<Item = Self::Input>,
            OutBuffer: BlockMut<Item = Self::Output>;
}

impl<In: Copy, Out: Copy, P: Processor2<Input = In, Output = Out>> BlockProcessor for P {
    fn process_block<InBuffer: Block<Item = In>, OutBuffer: BlockMut<Item = Out>>(&mut self, input: &InBuffer, output: &mut OutBuffer) {
        self.update();
        for (dest, src) in output.as_slice_mut().iter_mut().zip(input.as_slice()) {
            *dest = self.process(*src);
        }
    }
}
