// Trait definitions

pub trait Block {
    type Item;
    fn as_slice<'a>(&'a self) -> &'a [Self::Item];
}

pub trait BlockMut: Block {
    fn as_slice_mut<'a>(&'a mut self) -> &'a mut [Self::Item];
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