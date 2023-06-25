use crate::buffers::*;

pub trait Block {
    type Item;
    fn as_slice<'a>(&'a self) -> &'a [Self::Item];
}

pub trait BlockMut: Block {
    fn as_slice_mut<'a>(&'a mut self) -> &'a mut [Self::Item];
}

impl<F: Copy> Block for &mut [F] {
    type Item = F;

    fn as_slice<'a>(&'a self) -> &'a [Self::Item] {
        self
    }
}

impl<F: Copy> BlockMut for &mut [F] {
    fn as_slice_mut<'a>(&'a mut self) -> &'a mut [Self::Item] {
        self
    }
}
