use std::ops::Add;

pub use crate::traits::*;
use crate::{float::frame::Frame, Pitched};

#[derive(Copy, Clone)]
pub struct AudioNode<P>(pub P);

impl<P> std::ops::Deref for AudioNode<P> {
    type Target = P;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<P> std::ops::DerefMut for AudioNode<P> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl<P: Pitched2> Pitched2 for AudioNode<P> {
    fn get_pitch(&self) -> f32 {
        self.0.get_pitch()
    }

    fn set_pitch(&mut self, hz: f32) {
        self.0.set_pitch(hz);
    }
}

impl<Out, G> Generator for AudioNode<G>
    where
        G: Generator<Output = Out> {

    type Output = Out;

    fn reset(&mut self) {}
    fn prepare(&mut self, sample_rate: u32, block_size: usize) {}

    fn generate(&mut self) -> Self::Output {
        self.0.generate()
    }
}

impl<In, Out, P> Processor2 for AudioNode<P>
    where
        P: Processor2<Input = In, Output = Out> {

    type Input = In;
    type Output = Out;

    fn process(&mut self, input: Self::Input) -> Self::Output {
        self.0.process(input)
    }
}

impl<A, B> std::ops::Shr<AudioNode<B>> for AudioNode<A> {
    type Output = AudioNode<Chain<A, B>>;

    fn shr(self, rhs: AudioNode<B>) -> Self::Output {
        AudioNode(Chain(self.0, rhs.0))
    }
}

impl<A, B> std::ops::BitOr<AudioNode<B>> for AudioNode<A> {
    type Output = AudioNode<Parallel<A, B>>;

    fn bitor(self, rhs: AudioNode<B>) -> Self::Output {
        AudioNode(Parallel(self.0, rhs.0))
    }
}

impl<In1, Out1, Merged, Out2, P1, P2> std::ops::BitAnd<AudioNode<P2>> for AudioNode<P1> 
    where
        Out1: TupleMerge<Output = Merged>,
        P1: Processor2<Input = In1, Output = Out1>,
        P2: Processor2<Input = Merged, Output = Out2> {

    type Output = AudioNode<Chain<Merge<In1, Out1, Merged, P1>, P2>>;

    fn bitand(self, rhs: AudioNode<P2>) -> Self::Output {
        AudioNode(Chain(Merge(self.0), rhs.0))
    }
}

pub struct Series<F: Frame, A: Processor2<Input = F, Output = F>, const C: usize>(pub [A; C]);

impl<F: Frame, A: Processor2<Input = F, Output = F>, const C: usize> Processor2 for Series<F, A, C> {
    type Input = F;
    type Output = F;

    fn process(&mut self, input: F) -> F {
        let mut v = input;
        for p in &mut self.0 {
           v = p.process(v);
        }

        return v;
    }
}

impl<G1, P2> Pitched2 for Chain<G1, P2>
    where
        G1: Generator + Pitched2,
        P2: Processor2 {

    fn get_pitch(&self) -> f32 {
        self.0.get_pitch()
    }

    fn set_pitch(&mut self, hz: f32) {
        self.0.set_pitch(hz);
    }
}

#[derive(Copy, Clone)]
pub struct Chain<P1, P2>(pub P1, pub P2);

impl<In, Between, Out, P1, P2> Processor2 for Chain<P1, P2> 
    where
        P1: Processor2<Input = In, Output = Between>,
        P2: Processor2<Input = Between, Output = Out> {

    type Input = In;
    type Output = Out;

    fn process(&mut self, input: Self::Input) -> Self::Output {
        self.1.process(self.0.process(input))
    }
}

impl<Between, Out, P1, P2> Generator for Chain<P1, P2> 
    where
        P1: Generator<Output = Between>,
        P2: Processor2<Input = Between, Output = Out> {

    type Output = Out;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn generate(&mut self) -> Self::Output {
        self.1.process(self.0.generate())
    }
}

pub struct Parallel<A, B>(pub A, pub B);

impl<F, G, H, J, A, B> Processor2 for Parallel<A, B>
    where
        A: Processor2<Input = F, Output = G>,
        B: Processor2<Input = H, Output = J> {

    type Input = (F, H);
    type Output = (G, J);

    fn process(&mut self, input: Self::Input) -> Self::Output {
        (self.0.process(input.0), self.1.process(input.1))
    }
}

pub struct Split<In, Out, P>(pub P)
    where
        P: Processor2<Input = In, Output = Out>;

impl<In, Out, P> Processor2 for Split<In, Out, P> 
    where
        Out: Copy,
        P: Processor2<Input = In, Output = Out> {

    type Input = In;
    type Output = (Out, Out);

    fn process(&mut self, input: Self::Input) -> Self::Output {
        let output = self.0.process(input);
        (output, output)
    }
}

pub trait TupleMerge {
    type Output;

    fn merge(self) -> Self::Output;
}

impl<F: Add<Output = F>> TupleMerge for (F, F) {
    type Output = F;

    fn merge(self) -> Self::Output {
        self.0 + self.1
    }
}

impl<F: Add<Output = F>> TupleMerge for (F, F, F) {
    type Output = F;

    fn merge(self) -> Self::Output {
        self.0 + self.1 + self.2
    }
}

impl<F: Add<Output = F>> TupleMerge for (F, F, F, F) {
    type Output = F;

    fn merge(self) -> Self::Output {
        self.0 + self.1 + self.2 + self.3
    }
}

pub struct Merge<In, Out, Merged, P>(pub P)
    where
        Out: TupleMerge<Output = Merged>,
        P: Processor2<Input = In, Output = Out>;

impl<In, Out, Merged, P> Processor2 for Merge<In, Out, Merged, P> 
    where
        Out: TupleMerge<Output = Merged>,
        P: Processor2<Input = In, Output = Out> {

    type Input = In;
    type Output = Merged;

    fn process(&mut self, input: Self::Input) -> Self::Output {
        self.0.process(input).merge()
    }
}