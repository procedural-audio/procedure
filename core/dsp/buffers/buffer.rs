use std::marker::PhantomData;
use std::ops::{Deref, DerefMut};
use std::slice;
use std::ops::{Add, Sub, Mul, Div, AddAssign, SubAssign, MulAssign, DivAssign};

use crate::{time::*, Pitched};
use crate::event::NoteMessage;
use crate::block::*;

use crate::float::frame::*;
use crate::traits::*;

use std::ops::{Index, IndexMut};

use crate::routing::node::*;

// Distinguish between static buffers and dynamic buffers?

pub struct IO {
    pub audio: Bus<StereoBuffer>,
    pub events: Bus<NoteBuffer>,
    pub control: Bus<Box<f32>>,
    pub time: Bus<Box<TimeMessage>>,
}

/* Individual Buffer Types */

// TODO: Implement deref for all Processor2's to return AudioNode<T>
// TODO: Create functions for each node that take all arguments
// TODO: Make it so AudioNodes can be used as references also

/*

Faust Syntax
 - Parallel composition: dsp,dsp,dsp,dsp
 - Sequential composition: dsp:dsp:dsp:dsp
 - Split composition: dsp <: dsp
 - Combine composition: dsp :> dsp

FunDSP Syntax
 - -A (negate any number of outputs)
 - !A (passes through extra inputs)
 - A * B (multiply each signal)
 - A * constant (multiply by constant)
 - A + B (mix the buffers)
 - A + constant (add to constant)
 - A - B (subtract)
 - A - constant (subtract constant)
 - A >> B (pipe A to B)
 - A & B (sum A and B)
 - A ^ B (branch input to A and B in parallel)
 - A | B (stack A and B in parallel)

Final syntax
 - >> series
 - <= split
 - => merge
 - | parallel
 - Ops: +, -, *, /

Examples
 - delay(100) >> delay(100) >> delay(100) <= (delay(100), delay(100)) => delay(100);

*/

impl<T: Copy> Block for Buffer<T> {
    type Item = T;

    fn as_slice<'a>(&'a self) -> &'a [T] {
        self.items.as_slice()
    }
}

impl<T: Copy> BlockMut for Buffer<T> {
    fn as_slice_mut<'a>(&'a mut self) -> &'a mut [T] {
        self.items.as_mut_slice()
    }
}

impl<F: Copy> Block for &[F] {
    type Item = F;

    fn as_slice<'a>(&'a self) -> &'a [Self::Item] {
        self
    }
}

pub fn input2<F: Frame>() -> AudioNode<Passthrough<F>> {
    AudioNode(Passthrough { data: PhantomData::<F> })
}

pub fn output2<F: Frame>() -> AudioNode<Passthrough<F>> {
    AudioNode(Passthrough { data: PhantomData::<F> })
}

pub struct Passthrough<F: Frame> {
    data: PhantomData<F>
}

impl<F: Frame> Processor2 for Passthrough<F> {
    type Input = F;
    type Output = F;

    fn process(&mut self, input: Self::Input) -> Self::Output {
        input
    }
}

pub fn testdsp() -> AudioNode<TestDsp> {
    AudioNode(TestDsp)
}

pub fn pitcheddsp() -> AudioNode<PitchedDsp> {
    AudioNode(PitchedDsp)
}

pub fn gain<F: Frame, DB: Generator<Output = f32>>(db: DB) -> AudioNode<Gain2<F, DB>> {
    AudioNode(Gain2 { db , data: PhantomData })
}

pub fn osc<F: Frame, Pitch: Generator<Output = f32>>(f: fn(f32) -> F, hz: Pitch) -> AudioNode<Osc<F, Pitch>> {
    AudioNode(Osc { f, pitch: hz, x: 0.0, rate: 44100.0 })
}

#[derive(Copy, Clone)]
pub struct Osc<F: Frame, Pitch: Generator<Output = f32>> {
    f: fn(f32) -> F,
    pitch: Pitch,
    x: f32,
    rate: f32
}

impl<F: Frame, Pitch: Generator<Output = f32>> Generator for Osc<F, Pitch> {
    type Output = F;

    fn reset(&mut self) {}

    fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
        self.rate = sample_rate as f32;
    }

    fn gen(&mut self) -> Self::Output {
        let out = (self.f)(self.x);
        let pitch = self.pitch.gen();
        self.x += 2.0 * std::f32::consts::PI / self.rate * pitch;
        return out;
    }
}

#[derive(Copy, Clone)]
pub struct Gain2<F: Frame, DB: Generator<Output = f32>> {
    db: DB,
    data: PhantomData<F>
}

impl<F: Frame, DB: Generator<Output = f32>> Processor2 for Gain2<F, DB> {
    type Input = F;
    type Output = F;

    fn process(&mut self, input: Self::Input) -> Self::Output {
        input
    }
}

pub trait Drive {
    fn get_drive(&self) -> f32;
    fn set_drive(&mut self, amount: f32);
}

#[derive(Copy, Clone)]
pub struct TestDsp;

impl Processor2 for TestDsp {
    type Input = f32;
    type Output = f32;

    fn process(&mut self, input: Self::Input) -> Self::Output {
        input + 1.0
    }
}

#[derive(Copy, Clone)]
pub struct PitchedDsp;

impl PitchedDsp {
    pub fn set_pitch(&mut self, pitch: f32) {
        println!("Set pitch");
    }
}

impl Processor2 for PitchedDsp {
    type Input = f32;
    type Output = f32;

    fn process(&mut self, input: Self::Input) -> Self::Output {
        input + 1.0
    }
}

// Replace letters with useful names
pub fn chain<F: Frame, G: Frame, H: Frame, A: Processor2<Input = F, Output = G>, B: Processor2<Input = G, Output = H>>(first: A, second: B) -> AudioNode<Chain<A, B>> {
    AudioNode(Chain(first, second))
}

pub fn parallel<F: Frame, G: Frame, H: Frame, J: Frame, A: Processor2<Input = F, Output = G>, B: Processor2<Input = H, Output = J>>(first: A, second: B) -> AudioNode<Parallel<A, B>> {
    AudioNode(Parallel(first, second))
}

pub fn split<In, Out, P>(processor: P) -> AudioNode<Split<In, Out, P>>
    where
        In: Frame,
        Out: Frame,
        P: Processor2<Input = In, Output = Out>
{
    AudioNode(Split(processor))
}

pub fn merge<In, Out: TupleMerge<Output = Merged>, Merged, P>(processor: P) -> AudioNode<Merge<In, Out, Merged, P>>
    where
        P: Processor2<Input = In, Output = Out>
{
    AudioNode(Merge(processor))
}

pub struct Buffer<T> {
    items: Vec<T>,
}

impl<T> Buffer<T> {
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

    pub fn fill<G: Generator<Output = T>>(&mut self, src: &mut G) {
        for d in &mut self.items {
            *d = src.gen();
        }
    }
}

impl<T: Copy> Buffer<T> {
    pub fn init(value: T, size: usize) -> Self {
        let mut items = Vec::with_capacity(size);

        for _ in 0..size {
            items.push(value);
        }

        Self { items }
    }

    pub fn copy_from<B: Block<Item = T>>(&mut self, src: &B) {
        self.as_slice_mut().copy_from_slice(src.as_slice());
    }
}

impl<T: Frame> Buffer<T> {
    pub fn add_from<B: Block<Item = T>>(&mut self, src: &B) {
        for (dest, src) in self.as_slice_mut().iter_mut().zip(src.as_slice()) {
            *dest += *src;
        }
    }
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
    pub channels: Vec<Channel<T>>,
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