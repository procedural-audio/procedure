use std::marker::PhantomData;
use std::ops::{Deref, DerefMut};
use std::slice;
use std::ops::{Add, Sub, Mul, Div, AddAssign, SubAssign, MulAssign, DivAssign};

pub mod event;
pub mod time;

pub use crate::buffers::event::*;
pub use crate::buffers::time::*;

use crate::dsp::{Generator, Processor};

use std::ops::{Index, IndexMut};

pub struct IO {
    pub audio: Bus<StereoBuffer>,
    pub events: Bus<NoteBuffer>,
    pub control: Bus<Box<f32>>,
    pub time: Bus<Box<TimeMessage>>,
}

/* Individual Buffer Types */

pub trait Frame: Copy + Clone + Add<Output = Self> + Sub<Output = Self> + Mul<Output = Self> + Div<Output = Self> + AddAssign + SubAssign + MulAssign + DivAssign {
    type Output;
    const CHANNELS: usize;

    fn from(value: f32) -> Self;
    fn channel(&self, index: usize) -> &f32;
    fn channel_mut(&mut self, index: usize) -> &mut f32;


    fn zero(&mut self);
    // fn fill(&mut self, value: Self);
    fn gain(&mut self, db: f32);
    fn sqrt(self) -> Self;
    fn mono(&self) -> f32;

    fn apply(v: Self, f: fn(f32) -> f32) -> Self;
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

    fn powf(a: Self, b: Self) -> Self {
        Self::apply_2(a, b, f32::powf)
    }
}

impl Frame for f32 {
    type Output = f32;
    const CHANNELS: usize = 1;

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

    fn apply(v: Self, f: fn(f32) -> f32) -> Self {
        f(v)
    }

    fn apply_2(a: Self, b: Self, f: fn(f32, f32) -> f32) -> Self {
        f(a, b)
    }
}

#[derive(Copy, Clone)]
pub struct Stereo2<T> {
    pub left: T,
    pub right: T,
}

impl Frame for Stereo2<f32> {
    type Output = Stereo2<f32>;
    const CHANNELS: usize = 2;

    fn from(value: f32) -> Self {
        Stereo2 {
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

    fn apply(v: Self, f: fn(f32) -> f32) -> Self {
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

impl Add for Stereo2<f32> {
    type Output = Stereo2<f32>;

    fn add(self, rhs: Self) -> Self::Output {
        Stereo2 {
            left: self.left + rhs.left,
            right: self.right + rhs.right
        }
    }
}

impl Sub for Stereo2<f32> {
    type Output = Stereo2<f32>;

    fn sub(self, rhs: Self) -> Self::Output {
        Stereo2 {
            left: self.left - rhs.left,
            right: self.right - rhs.right
        }
    }
}

impl Mul for Stereo2<f32> {
    type Output = Stereo2<f32>;

    fn mul(self, rhs: Self) -> Self::Output {
        Stereo2 {
            left: self.left * rhs.left,
            right: self.right * rhs.right
        }
    }
}

impl Div for Stereo2<f32> {
    type Output = Stereo2<f32>;

    fn div(self, rhs: Self) -> Self::Output {
        Stereo2 {
            left: self.left / rhs.left,
            right: self.right / rhs.right
        }
    }
}

impl AddAssign for Stereo2<f32> {
    fn add_assign(&mut self, rhs: Self) {
        self.left = self.left + rhs.left;
        self.right = self.right + rhs.right;
    }
}

impl SubAssign for Stereo2<f32> {
    fn sub_assign(&mut self, rhs: Self) {
        self.left = self.left - rhs.left;
        self.right = self.right - rhs.right;
    }
}

impl MulAssign for Stereo2<f32> {
    fn mul_assign(&mut self, rhs: Self) {
        self.left = self.left * rhs.left;
        self.right = self.right * rhs.right;
    }
}

impl DivAssign for Stereo2<f32> {
    fn div_assign(&mut self, rhs: Self) {
        self.left = self.left / rhs.left;
        self.right = self.right / rhs.right;
    }
}

pub type AudioBuffer = Buffer<f32>;
pub type StereoBuffer = Buffer<Stereo2<f32>>;
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

pub trait MultiChannel {
    const INPUTS: usize;
    const OUTPUTS: usize;
}

pub trait Processor2 {
    type Input: Copy + Clone;
    type Output: Copy + Clone;

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {}

    fn process(&mut self, input: Self::Input) -> Self::Output;

    fn process_block(&mut self, input: &Buffer<Self::Input>, output: &mut Buffer<Self::Output>) {
        for (dest, src) in output.as_slice_mut().iter_mut().zip(input.as_slice()) {
            *dest = self.process(*src);
        }
    }
}

// TODO: Implement deref for all Processor2's to return AudioNode<T>
// TODO: Create functions for each node that take all arguments
// TODO: Make it so AudioNodes can be used as references also

pub struct AudioNode<P: Processor2>(pub P);

impl<F: Frame, A: Processor2<Input = F, Output = F>, B: Processor2<Input = F, Output = F>> std::ops::Shr<AudioNode<B>> for AudioNode<A> {
    type Output = AudioNode<Chain<F, A, B>>;

    fn shr(self, rhs: AudioNode<B>) -> Self::Output {
        AudioNode(Chain(self.0, rhs.0))
    }
}

impl<F: Frame, A: Processor2<Input = F, Output = F>, B: Processor2<Input = F, Output = F>> std::ops::Shl<AudioNode<B>> for AudioNode<A> {
    type Output = AudioNode<Chain<F, B, A>>;

    fn shl(self, rhs: AudioNode<B>) -> Self::Output {
        AudioNode(Chain(rhs.0, self.0))
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

pub struct Chain<F: Frame, A: Processor2<Input = F, Output = F>, B: Processor2<Input = F, Output = F>>(pub A, pub B);

impl<F: Frame, A: Processor2<Input = F, Output = F>, B: Processor2<Input = F, Output = F>> Processor2 for Chain<F, A, B> {
    type Input = F;
    type Output = F;

    fn process(&mut self, input: F) -> F {
        self.1.process(self.0.process(input))
    }
}

pub struct Split<I, O, X, Y, A: Processor2<Input = I, Output = O>, B: Processor2<Input = X, Output = Y>>(pub A, pub B);

impl<F: Frame, A: Processor2<Input = F, Output = F>, B: Processor2<Input = F, Output = F>> Processor2 for Split<F, F, F, F, A, B> {
    type Input = F;
    type Output = (F, F);

    fn process(&mut self, input: Self::Input) -> Self::Output {
        let v = self.0.process(input);
        (v, v)
    }
}

impl<F: Frame, const C: usize, A: Processor2<Input = F, Output = F>, B: Processor2<Input = [F; C], Output = [F; C]>> Processor2 for Split<F, F, [F; C], [F; C], A, B> {
    type Input = F;
    type Output = [F; C];

    fn process(&mut self, input: Self::Input) -> Self::Output {
        let mut arr = [F::from(0.0); C];
        let v = self.0.process(input);
        for i in 0..C {
            arr[i] = v;
        }
        return arr;
    }
}

pub struct Merge<I, O, A: Processor2<Input = I, Output = O>>(pub A);

impl<F: Frame, A: Processor2<Input = F, Output = (F, F)>> Processor2 for Merge<F, (F, F), A> {
    type Input = F;
    type Output = F;

    fn process(&mut self, input: Self::Input) -> Self::Output {
        let v = self.0.process(input);
        v.0 + v.1
    }
}

impl<F: Frame, const C: usize, A: Processor2<Input = [F; C], Output = [F; C]>> Processor2 for Merge<[F; C], [F; C], A> {
    type Input = [F; C];
    type Output = F;

    fn process(&mut self, input: Self::Input) -> Self::Output {
        self.0.process(input).iter().fold(F::from(0.0), | v, a| v + *a)
    }
}

pub struct Parallel<const C: usize, I, O, P: Processor2<Input = I, Output = O>>(pub [P; C]);

impl<F: Frame, const C: usize, P: Processor2<Input = F, Output = F>> Processor2 for Parallel<C, F, F, P> {
    type Input = [F; C];
    type Output = [F; C];

    fn process(&mut self, input: Self::Input) -> Self::Output {
        let mut output = [F::from(0.0); C];

        for i in 0..C {
            output[i] = self.0[i].process(input[i]);
        }

        output
    }
}

/*pub struct Adder<A: Processor2, B: Processor2>(pub A, pub B);

impl<A: Processor2, B: Processor2<Input = A::Output>> std::ops::Add<B> for B {
    type Output = Adder<A, B>;

    fn add(self, rhs: Self) -> Self::Output {
        Adder(self, rhs)
    }
}*/

/*pub struct Multi<T, const C: usize> {
    channels: [T; C]
}

impl<P: Processor, const C: usize> Multi<P, C> {
    fn process(&mut self, input: &[P::Item; C], output: &mut Multi<P, C>) {
        todo!()
    }

    fn process_block(&mut self, inputs: &Multi<Buffer<P::Item>, C>, outputs: &mut Multi<Buffer<P::Item>, C>) {
        for i in 0..C {
            let input = &inputs.channels[i];
            let output = &mut outputs.channels[i];
            let dsp = &mut self.channels[i];
            dsp.process_block(input, output);
        }
    }
}*/

/* Buffer Type */

pub struct Buffer<T: Clone> {
    items: Vec<T>,
}

impl<T: Frame + Copy> Buffer<T> {
    pub fn init(value: T, size: usize) -> Self {
        let mut items = Vec::with_capacity(size);

        for _ in 0..size {
            items.push(value);
        }

        Self { items }
    }

    pub fn copy_from(&mut self, src: &Buffer<T>) {
        // self.items.as_mut_slice().copy_from_slice(src.as_slice())

        if self.len() == src.len() {
            for (dest, src) in self.into_iter().zip(src.into_iter()) {
                *dest = *src;
            }
        } else {
            panic!("Copying from buffers of different sizes, self: {}, src: {}", self.len(), src.len());
        }

    }
}

impl<T: Clone> Buffer<T> {
    pub fn from(items: Vec<T>) -> Self {
        Self { items }
    }

    pub unsafe fn from_raw_parts(ptr: *mut T, length: usize, capacity: usize) -> Self {
        Self {
            items: Vec::from_raw_parts(ptr, length, capacity),
        }
    }

    pub fn len(&self) -> usize {
        self.items.len()
    }

    pub fn capacity(&self) -> usize {
        self.items.capacity()
    }

    pub fn as_ref(&self) -> &[T] {
        self.items.as_ref()
    }

    pub fn as_mut(&mut self) -> &mut [T] {
        self.items.as_mut()
    }

    pub fn as_slice<'a>(&'a self) -> &'a [T] {
        self.items.as_slice()
    }

    pub fn as_slice_mut<'a>(&'a mut self) -> &'a mut [T] {
        self.items.as_mut_slice()
    }

    pub fn as_ptr(&self) -> *const T {
        self.items.as_ptr()
    }

    pub fn as_mut_ptr(&mut self) -> *mut T {
        self.items.as_mut_ptr()
    }

    /* Operations */

    pub fn push(&mut self, item: T) {
        self.items.push(item);
    }

    pub fn clear(&mut self) {
        self.items.clear();
    }

    pub fn fill<G: Generator<Item = T>>(&mut self, src: &mut G) {
        for d in &mut self.items {
            *d = src.gen();
        }
    }

    /*pub fn process<P: Processor<Item = T>>(&mut self, src: &mut P) {
        for d in &mut self.items {
            *d = src.process(*d);
        }
    }*/

    /*// REMOVE THIS METHOD
    pub fn as_array<'a>(&'a self) -> [&'a [T]; 1] {
        [self.as_slice()]
    }

    // REMOVE THIS METHOD
    pub fn as_array_mut<'a>(&'a mut self) -> [&'a mut [T]; 1] {
        [self.as_slice_mut()]
    }*/
}

impl NoteBuffer {
    pub fn new() -> Self {
        Self {
            items: Vec::new()
        }
    }

    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            items: Vec::with_capacity(capacity)
        }
    }

    pub fn replace(&mut self, src: &Buffer<NoteMessage>) {
        self.items.clear();

        for s in src.as_slice() {
            self.items.push(*s);
        }
    }

    pub fn append(&mut self, src: &Buffer<NoteMessage>) {
        for s in src.as_slice() {
            self.items.push(*s);
        }
    }
}

/*impl<T: Frame> Frame for Buffer<T> {
    type Output = Buffer<T>;

    fn zero(&mut self) {
        for sample in &mut self.items {
            sample.zero();
        }
    }

    fn gain(&mut self, db: f32) {
        for sample in &mut self.items {
            sample.gain(db);
        }
    }
}*/

/*impl<T: Sample> Buffer<T> {
    pub fn zero(&mut self) {
        self.fill(&mut 0.0);
    }

    pub fn gain(&mut self, db: f32) {
        for v in &mut self.items {
            *v = *v * db;
        }
    }
}*/

impl<T: Copy + Clone + std::ops::Add<Output = T>> Buffer<T> {
    pub fn add_from(&mut self, src: &Buffer<T>) {
        for (d, s) in self.items.iter_mut().zip(src.as_slice()) {
            *d = *d + *s;
        }
    }
}

impl<T: Copy + Clone> Index<usize> for Buffer<T> {
    type Output = T;

    fn index(&self, index: usize) -> &Self::Output {
        &self.items[index]
    }
}

impl<T: Copy + Clone> IndexMut<usize> for Buffer<T> {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        &mut self.items[index]
    }
}

impl<'a, T: Copy + Clone> IntoIterator for &'a Buffer<T> {
    type Item = &'a T;
    type IntoIter = slice::Iter<'a, T>;

    fn into_iter(self) -> slice::Iter<'a, T> {
        self.as_slice().into_iter()
    }
}

impl<'a, T: Copy + Clone> IntoIterator for &'a mut Buffer<T> {
    type Item = &'a mut T;
    type IntoIter = slice::IterMut<'a, T>;

    fn into_iter(self) -> slice::IterMut<'a, T> {
        self.as_slice_mut().into_iter()
    }
}

pub struct Bus<T> {
    channels: Vec<Channel<T>>,
}

impl<T> Bus<T> {
    pub fn new() -> Self {
        Self {
            channels: Vec::new(),
        }
    }

    pub fn add_channel(&mut self, channel: Channel<T>) {
        self.channels.push(channel);
    }

    pub fn channel(&self, index: usize) -> &Channel<T> {
        &self.channels[index]
    }

    pub fn channel_mut(&mut self, index: usize) -> &mut Channel<T> {
        &mut self.channels[index]
    }

    pub fn num_channels(&self) -> usize {
        self.channels.len()
    }

    pub fn connected(&self, index: usize) -> bool {
        self.channels[index].connected
    }

    pub fn len(&self) -> usize {
        self.channels.len()
    }
}

/*impl Index<usize> for Bus<StereoBuffer> {
    type Output = StereoBuffer;

    fn index(&self, index: usize) -> &Self::Output {
        self.channel(index).deref()
    }
}

impl IndexMut<usize> for Bus<StereoBuffer> {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        self.channel_mut(index).deref_mut()
    }
}*/

impl<T: Copy + Clone> Index<usize> for Bus<Buffer<T>> {
    type Output = Buffer<T>;

    fn index(&self, index: usize) -> &Self::Output {
        self.channel(index).deref()
    }
}

impl<T: Copy + Clone> IndexMut<usize> for Bus<Buffer<T>> {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        self.channel_mut(index).deref_mut()
    }
}

impl<T: Copy + Clone> Index<usize> for Bus<Box<T>> {
    type Output = T;

    fn index(&self, index: usize) -> &Self::Output {
        self.channel(index).deref()
    }
}

impl<T: Copy + Clone> IndexMut<usize> for Bus<Box<T>> {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        self.channel_mut(index).deref_mut()
    }
}

pub struct Channel<T> {
    buffer: T,
    connected: bool,
}

impl<T> Channel<T> {
    pub fn new(buffer: T, connected: bool) -> Self {
        Self { buffer, connected }
    }

    pub fn connected(&self) -> bool {
        self.connected
    }

    pub fn set_connected(&mut self, connected: bool) {
        self.connected = connected;
    }
}

impl<T> Deref for Channel<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.buffer
    }
}

impl<T> DerefMut for Channel<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.buffer
    }
}

impl<F: Frame> Buffer<F> {
    pub fn rms(&self) -> F {
        let mut sum = F::from(0.0);
        for sample in self {
            sum += *sample * *sample;
        }

        let avg = sum / F::from(self.len() as f32);
        return F::sqrt(avg);
    }

    /*pub fn peak(&self) -> f32 {
        let mut max = 0.0;

        for sample in self {
            if f32::abs(*sample) > max {
                max = f32::abs(*sample);
            }
        }

        max
    }*/
}

pub trait AudioChannel<const C: usize> {
    fn as_array<'a>(&'a self) -> [&'a [f32]; C];

    fn as_ptr(&self) -> *mut f32 {
        self.as_array()[0].as_ptr() as *mut f32
    }

    fn len(&self) -> usize {
        self.as_array()[0].len()
    }

    fn channels(&self) -> usize {
        C
    }

    fn rms(&self) -> f32 {
        let mut sample_count = 0;
        let mut sum = 0.0;

        for slice in self.as_array() {
            sample_count += slice.len();
            for sample in slice {
                sum += *sample * *sample;
            }
        }

        let avg = sum / sample_count as f32;
        return f32::sqrt(avg);
    }

    fn peak(&self) -> f32 {
        let mut max = 0.0;

        for slice in self.as_array() {
            for sample in slice {
                if f32::abs(*sample) > max {
                    max = f32::abs(*sample);
                }
            }
        }

        max
    }
}

pub trait AudioChannelMut<const C: usize>: AudioChannel<C> {
    fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; C];

    fn fill(&mut self, value: f32) {
        for slice in self.as_array_mut() {
            for sample in slice {
                *sample = value;
            }
        }
    }

    fn delay(&mut self, _samples: usize) {
        panic!("Delay not implemented");
    }

    fn zero(&mut self) {
        for slice in self.as_array_mut() {
            for sample in slice {
                *sample = 0.0;
            }
        }
    }

    fn gain(&mut self, decibals: f32) {
        for slice in self.as_array_mut() {
            for sample in slice {
                *sample *= decibals;
            }
        }
    }

    fn clip(&mut self) {
        for slice in self.as_array_mut() {
            for sample in slice {
                if *sample > 1.0 {
                    *sample = 1.0;
                }

                if *sample < -1.0 {
                    *sample = -1.0;
                }
            }
        }
    }

    fn copy_from<T: AudioChannel<C> + ?Sized>(&mut self, buffer: &T) {
        for (dest, src) in self.as_array_mut().iter_mut().zip(buffer.as_array()) {
            if dest.len() == src.len() {
                dest.copy_from_slice(src);
            } else {
                dest[0..src.len()].copy_from_slice(src);
            }
        }
    }

    fn add_from<T: AudioChannel<C> + ?Sized>(&mut self, buffer: &T) {
        for (dest, src) in self.as_array_mut().iter_mut().zip(buffer.as_array()) {
            for (d, s) in dest.iter_mut().zip(src) {
                *d += *s;
            }
        }
    }
}

impl<'s> AudioChannel<1> for Vec<f32> {
    fn as_array<'a>(&'a self) -> [&'a [f32]; 1] {
        [self.as_slice()]
    }
}

impl<'s> AudioChannelMut<1> for Vec<f32> {
    fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; 1] {
        [self.as_mut_slice()]
    }
}

impl<'s> AudioChannel<1> for [f32] {
    fn as_array<'a>(&'a self) -> [&'a [f32]; 1] {
        [self]
    }
}

impl<'s> AudioChannelMut<1> for [f32] {
    fn as_array_mut<'a>(&'a mut self) -> [&'a mut [f32]; 1] {
        [self]
    }
}

/*impl<T: AudioChannel<1>> Buffer for T {
    type Element = f32;

    fn as_slice<'a>(&'a self) -> &'a [Self::Element] {
        self.as_array()[0]
    }
}

impl<T: AudioChannelMut<1>> BufferMut for T {
    type Element = f32;

    fn as_slice_mut<'a>(&'a mut self) -> &'a mut [Self::Element] {
        self.as_array_mut()[0]
    }
}*/

pub struct RingBuffer<F: Frame> {
    buffer: Buffer<F>,
    length: usize,
    index: usize
}

/*impl<F: Frame> Generator for RingBuffer<F> {
    type Item = F;

    fn reset(&mut self) {
        self.index = 0;
        for sample in self.buffer.as_slice_mut() {
            sample.zero();
        }
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        panic!("Prepare not implemented for ");
    }

    fn gen(&mut self) -> Self::Item {
    }
}*/

impl<F: Frame> RingBuffer<F> {
    pub fn init(value: F, size: usize) -> Self {
        Self {
            buffer: Buffer::init(value, size),
            length: 1,
            index: 0
        }
    }

    pub fn len(&self) -> usize {
        self.length
    }

    pub fn capacity(&self) -> usize {
        self.buffer.capacity()
    }

    pub fn resize(&mut self, length: usize) {
        if length > self.buffer.capacity() {
            self.buffer.items.resize(length, F::from(0.0));
        } else {
            self.length = length;
            for sample in self.buffer.as_slice_mut().iter_mut().skip(length) {
                *sample = F::from(0.0);
            }
        }
    }

    pub fn next(&mut self, input: F) -> F {
        let output = self.buffer.items[self.index];
        self.buffer.items[self.index] = input;
        self.index = (self.index + 1) % self.length;
        output
    }
}