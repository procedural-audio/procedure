use std::ops::{Add, Sub, Mul, Div, AddAssign, SubAssign, MulAssign, DivAssign};

pub trait Float: Copy + Clone
    + PartialEq + PartialOrd
    + Add<Output = Self> + Sub<Output = Self> + Mul<Output = Self> + Div<Output = Self>
    + AddAssign + SubAssign + MulAssign + DivAssign {

    const ZERO: Self;
    const MIN: Self;
    const MAX: Self;

    fn from(v: f32) -> Self;

    fn sin(self) -> Self;
    fn cos(self) -> Self;
    fn tan(self) -> Self;

    fn avg(self, v: Self) -> Self;
}

impl Float for f32 {
    const ZERO: Self = 0.0;
    const MIN: Self = -1.0;
    const MAX: Self = 1.0;

    fn from(v: f32) -> Self {
        v
    }

    fn sin(self) -> Self {
        f32::sin(self)
    }

    fn cos(self) -> Self {
        f32::cos(self)
    }

    fn tan(self) -> Self {
        f32::tan(self)
    }

    fn avg(self, v: Self) -> Self {
        (self + v) / 2.0
    }
}

impl Float for f64 {
    const ZERO: Self = 0.0;
    const MIN: Self = -1.0;
    const MAX: Self = 1.0;

    fn from(v: f32) -> Self {
        v as f64
    }

    fn sin(self) -> Self {
        f64::sin(self)
    }

    fn cos(self) -> Self {
        f64::cos(self)
    }

    fn tan(self) -> Self {
        f64::tan(self)
    }

    fn avg(self, v: Self) -> Self {
        (self + v) / 2.0
    }
}
