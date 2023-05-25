use crate::dsp::*;

/* ========== Clipper ========== */

#[inline]
pub fn clip(f: f32, clip: f32) -> f32 {
    f32::min(f, clip)
}

pub struct Clipper<T> {
    pub src: T,
    pub db: f32,
}

impl<T> Clipper<T> {
    pub fn set_clip(&mut self, db: f32) {
        self.db = db;
    }

    pub fn get_clip(&self) -> f32 {
        self.db
    }
}

impl<T: Default> Default for Clipper<T> {
    fn default() -> Self {
        Self {
            src: T::default(),
            db: 0.0,
        }
    }
}

impl<T: Generator<Output = f32>> Generator for Clipper<T> {
    type Output = f32;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn gen(&mut self) -> f32 {
        f32::max(self.src.gen(), self.db) // CONFUSES LINEAR AND DB
    }
}

impl<T: Processor<Item = f32>> Processor for Clipper<T> {
    type Item = f32;

    fn process(&mut self, v: f32) -> f32 {
        f32::max(self.src.process(v), self.db) // CONFUSES LINEAR AND DB
    }
}

impl<T> Deref for Clipper<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.src
    }
}

impl<T> DerefMut for Clipper<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.src
    }
}

/* ========== Amplifier ========== */

#[inline]
pub fn amp(f: f32, db: f32) -> f32 {
    f * db
}

pub struct Amplifier<T> {
    pub src: T,
    pub db: f32,
}

impl<T: Generator> Amplifier<T> {
    pub fn set_gain(&mut self, db: f32) {
        self.db = db;
    }

    pub fn get_gain(&self) -> f32 {
        self.db
    }
}

impl<T: Default> Default for Amplifier<T> {
    fn default() -> Self {
        Self {
            src: T::default(),
            db: 0.0,
        }
    }
}

impl<T: Generator<Output = f32>> Generator for Amplifier<T> {
    type Output = f32;

    fn reset(&mut self) {}
    fn prepare(&mut self, _sample_rate: u32, _block_size: usize) {}

    fn gen(&mut self) -> f32 {
        amp(self.src.gen(), self.db)
    }
}

impl<T: Processor<Item = f32>> Processor for Amplifier<T> {
    type Item = f32;

    fn process(&mut self, v: f32) -> f32 {
        amp(self.src.process(v), self.db)
    }
}

impl<T> Deref for Amplifier<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.src
    }
}

impl<T> DerefMut for Amplifier<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.src
    }
}

/* ========== Source ========== */

#[derive(Default)]
pub struct Source;

impl Processor for Source {
    type Item = f32;

    #[inline]
    fn process(&mut self, v: f32) -> f32 {
        v
    }
}
