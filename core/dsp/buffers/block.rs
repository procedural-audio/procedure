// Trait definitions

use std::ops::{Add, Sub, Mul};

use crate::{Generator, Sample};

pub trait Block {
    type Item;

    fn as_slice<'a>(&'a self) -> &'a [Self::Item];

    fn len(&self) -> usize {
        self.as_slice().len()
    }

    fn copy_to<B: BlockMut<Item = Self::Item>>(&self, dest: &mut B) where Self::Item: Copy {
        dest.as_slice_mut().copy_from_slice(self.as_slice());
    }

    fn rms(&self) -> Self::Item where Self::Item: Sample {
        panic!("rms not implemented");

        let mut total = Self::Item::EQUILIBRIUM;
        let mut count = Self::Item::EQUILIBRIUM;

        for s in self.as_slice() {
            total += *s;
        }

        total = total / count;

        return total;
    }
}

pub trait BlockMut: Block {
    fn as_slice_mut<'a>(&'a mut self) -> &'a mut [Self::Item];

    fn equilibrate(&mut self) where Self::Item: Sample {
        for d in self.as_slice_mut() {
            *d = Self::Item::EQUILIBRIUM;
        }
    }

    fn fill<G: Generator<Output = Self::Item>>(&mut self, src: &mut G) {
        for d in self.as_slice_mut() {
            *d = src.generate();
        }
    }

    fn copy_from<B: Block<Item = Self::Item>>(&mut self, src: &B) where Self::Item: Copy {
        self.as_slice_mut().copy_from_slice(src.as_slice());
    }

    fn add_from<B: Block<Item = Self::Item>>(&mut self, src: &B) where Self::Item: Copy + Add<Output = Self::Item> {
        for (dest, src) in self.as_slice_mut().iter_mut().zip(src.as_slice()) {
            *dest = *dest + *src;
        }
    }

    fn sub_from<B: Block<Item = Self::Item>>(&mut self, src: &B) where Self::Item: Copy + Sub<Output = Self::Item> {
        for (dest, src) in self.as_slice_mut().iter_mut().zip(src.as_slice()) {
            *dest = *dest - *src;
        }
    }

    fn mul_from<B: Block<Item = Self::Item>>(&mut self, src: &B) where Self::Item: Copy + Mul<Output = Self::Item> {
        for (dest, src) in self.as_slice_mut().iter_mut().zip(src.as_slice()) {
            *dest = *dest * *src;
        }
    }
}

// Slice implementations

impl<S> Block for &[S] {
    type Item = S;

    fn as_slice<'a>(&'a self) -> &'a [Self::Item] {
        self
    }
}

impl<S> Block for &mut [S] {
    type Item = S;

    fn as_slice<'a>(&'a self) -> &'a [Self::Item] {
        self
    }
}

impl<S> BlockMut for &mut [S] {
    fn as_slice_mut<'a>(&'a mut self) -> &'a mut [Self::Item] {
        self
    }
}

// Raw pointer implementations

impl<S> Block for (*const S, usize) {
    type Item = S;

    fn as_slice<'a>(&'a self) -> &'a [Self::Item] {
        unsafe {
            std::slice::from_raw_parts(self.0, self.1)
        }
    }
}

impl<S> Block for (*mut S, usize) {
    type Item = S;

    fn as_slice<'a>(&'a self) -> &'a [Self::Item] {
        unsafe {
            std::slice::from_raw_parts(self.0, self.1)
        }
    }
}

impl<S> BlockMut for (*mut S, usize) {
    fn as_slice_mut<'a>(&'a mut self) -> &'a mut [Self::Item] {
        unsafe {
            std::slice::from_raw_parts_mut(self.0, self.1)
        }
    }
}