use std::ops::{Add, Sub, Mul, Div, AddAssign, SubAssign, MulAssign, DivAssign};

trait Float: 
    Copy +
    Clone +
    PartialEq +
    Add<Output = Self> +
    Sub<Output = Self> +
    Mul<Output = Self> +
    Div<Output = Self> +
    AddAssign +
    SubAssign +
    MulAssign +
    DivAssign {
   fn from(value: f64) -> Self;
}

impl Float for f32 {
    fn from(value: f64) -> Self {
        value as f32
    }
}
