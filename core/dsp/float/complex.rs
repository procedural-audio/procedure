use std::ops::Mul;

use crate::Float;

pub const fn complex<F: Float>(real: F, imaginary: F) -> Complex<F> {
    Complex { real, imaginary }
}

#[derive(Copy, Clone, PartialEq)]
pub struct Complex<F: Float> {
    pub real: F,
    pub imaginary: F
}

impl<F: Float> Complex<F> {
    pub const ZERO: Complex<F> = Self {
        real: F::ZERO,
        imaginary: F::ZERO
    };

    pub fn new() -> Self {
        Self {
            real: F::ZERO,
            imaginary: F::ZERO
        }
    }

    pub fn from(real: F, imaginary: F) -> Self {
        Self { real, imaginary }
    }
}

impl<F: Float> Mul for Complex<F> {
    type Output = Complex<F>;

    fn mul(self, rhs: Self) -> Self::Output {
        let ac = self.real * rhs.real;
        let adi = self.real * rhs.imaginary;
        let bci = self.imaginary * rhs.real;
        let bd = self.imaginary * rhs.imaginary;

        Self {
            real: ac + bd,
            imaginary: adi + bci
        }
    }
}

/*impl<F: Float> Float for Complex<F> {
    const ZERO: Self = 0.0;
    const MIN: Self = -1.0;
    const MAX: Self = 1.0;
    const PI: Self = std::f32::consts::PI;

    fn sin(self) -> Self {
        f32::sin(self)
    }

    fn cos(self) -> Self {
        f32::cos(self)
    }

    fn tan(self) -> Self {
        f32::tan(self)
    }

    fn atan(self) -> Self {
        f32::atan(self)
    }

    fn avg(self, v: Self) -> Self {
        (self + v) / 2.0
    }

    fn powf(self, e: Self) -> Self {
        f32::powf(self, e)
    }
}*/