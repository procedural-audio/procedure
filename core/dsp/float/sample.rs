use std::ops::{Add, Sub, Mul, Div, AddAssign, SubAssign, MulAssign, DivAssign};

use crate::float::float::*;

pub trait Sample: Copy + Clone
    + PartialEq
    + Add<Output = Self> + Sub<Output = Self> + Mul<Output = Self> + Div<Output = Self>
    + AddAssign + SubAssign + MulAssign + DivAssign {

    type Float: Float;
    const CHANNELS: usize;
    const EQUILIBRIUM: Self;

    fn from(value: Self::Float) -> Self;
    fn apply<Function: Fn(Self::Float) -> Self::Float>(self, f: Function) -> Self where Self: Sized;

    fn sin(self) -> Self {
        self.apply(Float::sin)
    }

    fn cos(self) -> Self {
        Self::apply(self, Float::cos)
    }

    fn tan(self) -> Self {
        Self::apply(self, Float::tan)
    }
}

impl Sample for f32 {
    type Float = f32;

    const CHANNELS: usize = 1;
    const EQUILIBRIUM: Self = Self::ZERO;

    fn from(value: Self::Float) -> Self {
        value
    }

    fn apply<Function: Fn(Self::Float) -> Self::Float>(self, f: Function) -> Self where Self: Sized {
        f(self)
    }
}

impl Sample for f64 {
    type Float = f64;

    const CHANNELS: usize = 1;
    const EQUILIBRIUM: Self = Self::ZERO;

    fn from(value: Self::Float) -> Self {
        value
    }

    fn apply<Function: Fn(Self::Float) -> Self::Float>(self, f: Function) -> Self where Self: Sized {
        f(self)
    }
}
