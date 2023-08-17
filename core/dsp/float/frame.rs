use std::ops::{Add, Sub, Mul, Div, AddAssign, SubAssign, MulAssign, DivAssign};

use crate::event::*;
use crate::buffers::*;

pub trait Float: Copy + Clone
    + PartialEq + PartialOrd
    + Add<Output = Self> + Sub<Output = Self> + Mul<Output = Self> + Div<Output = Self>
    + AddAssign + SubAssign + MulAssign + DivAssign {

    const EQUILIBRIUM: Self;
}

impl Float for f32 {
    const EQUILIBRIUM: Self = 0.0;
}

impl Float for f64 {
    const EQUILIBRIUM: Self = 0.0;
}

impl Sample<f32> for f32 {
    const CHANNELS: usize = 1;

    fn apply<Function: FnMut(Self) -> Self>(self, mut f: Function) -> Self where Self: Sized {
        f(self)
    }
}

impl Sample<f64> for f64 {
    const CHANNELS: usize = 1;

    fn apply<Function: FnMut(Self) -> Self>(self, mut f: Function) -> Self where Self: Sized {
        f(self)
    }
}

impl<F: Float> Sample<F> for Stereo<F> {
    const CHANNELS: usize = 2;

    fn apply<Function: FnMut(F) -> F>(self, mut f: Function) -> Self where Self: Sized {
        Stereo {
            left: f(self.left),
            right: f(self.right)
        }
    }
}

pub trait Sample<F: Float> {
    const CHANNELS: usize;

    fn apply<Function: FnMut(F) -> F>(self, f: Function) -> Self where Self: Sized;
    // fn apply_if<Function: FnMut(Self) -> Self>(self, f: Function, condition: [bool; Self::CHANNELS]) -> Self where Self: Sized;
}

pub trait Frame: Copy + Clone + PartialEq + Add<Output = Self> + Sub<Output = Self> + Mul<Output = Self> + Div<Output = Self> + AddAssign + SubAssign + MulAssign + DivAssign {
    type Output;
    const CHANNELS: usize;
    const EQUILIBRIUM: Self;

    fn from(value: f32) -> Self;
    fn channel(&self, index: usize) -> &f32;
    fn channel_mut(&mut self, index: usize) -> &mut f32;

    fn zero(&mut self);
    // fn fill(&mut self, value: Self);
    fn gain(&mut self, db: f32);
    fn sqrt(self) -> Self;
    fn mono(&self) -> f32;

    fn apply<F: Fn(f32) -> f32>(v: Self, f: F) -> Self;
    fn apply_2(a: Self, b: Self, f: fn(f32, f32) -> f32) -> Self;

    fn min(a: Self, b: Self) -> Self {
        Self::apply_2(a, b, f32::min)
    }

    fn max(a: Self, b: Self) -> Self {
        Self::apply_2(a, b, f32::max)
    }

    fn sin(v: Self) -> Self {
        Self::apply(v, f32::sin)
    }

    fn cos(v: Self) -> Self {
        Self::apply(v, f32::cos)
    }

    fn tan(v: Self) -> Self {
        Self::apply(v, f32::tan)
    }

    fn exp(v: Self) -> Self {
        Self::apply(v, f32::exp)
    }

    fn abs(v: Self) -> Self {
        Self::apply(v, f32::abs)
    }

    fn powf(a: Self, b: Self) -> Self {
        Self::apply_2(a, b, f32::powf)
    }
}

impl Frame for f32 {
    type Output = f32;
    const CHANNELS: usize = 1;
    const EQUILIBRIUM: Self = 0.0;

    fn from(value: f32) -> Self {
        value
    }

    fn channel(&self, index: usize) -> &f32 {
        if index == 0 {
            self
        } else {
            panic!("Invalid frame channel");
        }
    }

    fn channel_mut(&mut self, index: usize) -> &mut f32 {
        if index == 0 {
            self
        } else {
            panic!("Invalid frame channel");
        }
    }

    fn zero(&mut self) {
        *self = 0.0;
    }

    fn gain(&mut self, db: f32) {
        *self = *self * db;
    }

    fn sqrt(self) -> Self {
        self.sqrt()
    }

    fn mono(&self) -> f32 {
        *self
    }

    fn apply<F: Fn(f32) -> f32>(v: Self, f: F) -> Self {
        f(v)
    }

    fn apply_2(a: Self, b: Self, f: fn(f32, f32) -> f32) -> Self {
        f(a, b)
    }
}

#[derive(Copy, Clone, PartialEq)]
pub struct Stereo<T> {
    pub left: T,
    pub right: T,
}

impl Frame for Stereo<f32> {
    type Output = Stereo<f32>;
    const CHANNELS: usize = 2;
    const EQUILIBRIUM: Self = Stereo { left: 0.0, right: 0.0 };

    fn from(value: f32) -> Self {
        Stereo {
            left: value,
            right: value
        }
    }

    fn channel(&self, index: usize) -> &f32 {
        if index == 0 {
            &self.left
        } else if index == 1 {
            &self.right
        } else {
            panic!("Invalid frame channel");
        }
    }

    fn channel_mut(&mut self, index: usize) -> &mut f32 {
        if index == 0 {
            &mut self.left
        } else if index == 1 {
            &mut self.right
        } else {
            panic!("Invalid frame channel");
        }
    }

    fn zero(&mut self) {
        self.left = 0.0;
        self.right = 0.0;
    }

    fn gain(&mut self, db: f32) {
        self.left = self.left * db;
        self.right = self.right * db;
    }

    fn sqrt(self) -> Self {
        Self {
            left: self.left.sqrt(),
            right: self.right.sqrt(),
        }
    }

    fn mono(&self) -> f32 {
        (self.left + self.right) / 2.0
    }

    fn apply<F: Fn(f32) -> f32>(v: Self, f: F) -> Self {
        Self {
            left: f(v.left),
            right: f(v.right),
        }
    }

    fn apply_2(a: Self, b: Self, f: fn(f32, f32) -> f32) -> Self {
        Self {
            left: f(a.left, b.left),
            right: f(a.right, b.right),
        }
    }
}

impl Add for Stereo<f32> {
    type Output = Stereo<f32>;

    fn add(self, rhs: Self) -> Self::Output {
        Stereo {
            left: self.left + rhs.left,
            right: self.right + rhs.right
        }
    }
}

impl Sub for Stereo<f32> {
    type Output = Stereo<f32>;

    fn sub(self, rhs: Self) -> Self::Output {
        Stereo {
            left: self.left - rhs.left,
            right: self.right - rhs.right
        }
    }
}

impl Mul for Stereo<f32> {
    type Output = Stereo<f32>;

    fn mul(self, rhs: Self) -> Self::Output {
        Stereo {
            left: self.left * rhs.left,
            right: self.right * rhs.right
        }
    }
}

impl Div for Stereo<f32> {
    type Output = Stereo<f32>;

    fn div(self, rhs: Self) -> Self::Output {
        Stereo {
            left: self.left / rhs.left,
            right: self.right / rhs.right
        }
    }
}

impl AddAssign for Stereo<f32> {
    fn add_assign(&mut self, rhs: Self) {
        self.left = self.left + rhs.left;
        self.right = self.right + rhs.right;
    }
}

impl SubAssign for Stereo<f32> {
    fn sub_assign(&mut self, rhs: Self) {
        self.left = self.left - rhs.left;
        self.right = self.right - rhs.right;
    }
}

impl MulAssign for Stereo<f32> {
    fn mul_assign(&mut self, rhs: Self) {
        self.left = self.left * rhs.left;
        self.right = self.right * rhs.right;
    }
}

impl DivAssign for Stereo<f32> {
    fn div_assign(&mut self, rhs: Self) {
        self.left = self.left / rhs.left;
        self.right = self.right / rhs.right;
    }
}

pub type AudioBuffer = Buffer<f32>;
pub type StereoBuffer = Buffer<Stereo<f32>>;
pub type NoteBuffer = Buffer<NoteMessage>;

pub struct Channels<T: Copy + Clone, const C: usize> {
    buffers: [Buffer<T>; C]
}

impl<T: Copy + Clone, const C: usize> Channels<T, C> {
    pub fn as_array(&self) -> &[Buffer<T>; C] {
        &self.buffers
    }

    pub fn as_array_mut(&mut self) -> &mut [Buffer<T>; C] {
        &mut self.buffers
    }
}