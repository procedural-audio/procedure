use std::ffi::CString;

mod button;
mod dropdown;
mod fader;
mod groups;
mod knob;

pub use button::*;
pub use dropdown::*;
pub use fader::*;
pub use groups::*;
pub use knob::*;

pub trait WidgetNew {
    fn get_name(&self) -> &'static str;
    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup;
    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        panic!("Method get_trait() not overriden for {}", self.get_name());
    }
}

pub trait WidgetGroup {
    fn len(&self) -> usize;
    fn get(&self, index: usize) -> Option<&dyn WidgetNew>;
}

impl WidgetGroup for () {
    fn len(&self) -> usize {
        0
    }

    fn get(&self, _index: usize) -> Option<&dyn WidgetNew> {
        None
    }
}

impl<A: WidgetNew> WidgetGroup for A {
    fn len(&self) -> usize {
        1
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(self),
            _ => None,
        }
    }
}

impl<A: WidgetNew, B: WidgetNew> WidgetGroup for (A, B) {
    fn len(&self) -> usize {
        2
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(&self.0),
            1 => Some(&self.1),
            _ => None,
        }
    }
}

impl<A: WidgetNew, B: WidgetNew, C: WidgetNew> WidgetGroup for (A, B, C) {
    fn len(&self) -> usize {
        3
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(&self.0),
            1 => Some(&self.1),
            2 => Some(&self.2),
            _ => None,
        }
    }
}

impl<A: WidgetNew, B: WidgetNew, C: WidgetNew, D: WidgetNew> WidgetGroup for (A, B, C, D) {
    fn len(&self) -> usize {
        4
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(&self.0),
            1 => Some(&self.1),
            2 => Some(&self.2),
            3 => Some(&self.3),
            _ => None,
        }
    }
}

impl<A: WidgetNew, B: WidgetNew, C: WidgetNew, D: WidgetNew, E: WidgetNew> WidgetGroup
    for (A, B, C, D, E)
{
    fn len(&self) -> usize {
        5
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(&self.0),
            1 => Some(&self.1),
            2 => Some(&self.2),
            3 => Some(&self.3),
            4 => Some(&self.4),
            _ => None,
        }
    }
}

impl<A: WidgetNew, B: WidgetNew, C: WidgetNew, D: WidgetNew, E: WidgetNew, F: WidgetNew> WidgetGroup
    for (A, B, C, D, E, F)
{
    fn len(&self) -> usize {
        6
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(&self.0),
            1 => Some(&self.1),
            2 => Some(&self.2),
            3 => Some(&self.3),
            4 => Some(&self.4),
            5 => Some(&self.5),
            _ => None,
        }
    }
}

impl<
        A: WidgetNew,
        B: WidgetNew,
        C: WidgetNew,
        D: WidgetNew,
        E: WidgetNew,
        F: WidgetNew,
        G: WidgetNew,
    > WidgetGroup for (A, B, C, D, E, F, G)
{
    fn len(&self) -> usize {
        7
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(&self.0),
            1 => Some(&self.1),
            2 => Some(&self.2),
            3 => Some(&self.3),
            4 => Some(&self.4),
            5 => Some(&self.5),
            6 => Some(&self.6),
            _ => None,
        }
    }
}

impl<
        A: WidgetNew,
        B: WidgetNew,
        C: WidgetNew,
        D: WidgetNew,
        E: WidgetNew,
        F: WidgetNew,
        G: WidgetNew,
        H: WidgetNew,
    > WidgetGroup for (A, B, C, D, E, F, G, H)
{
    fn len(&self) -> usize {
        8
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(&self.0),
            1 => Some(&self.1),
            2 => Some(&self.2),
            3 => Some(&self.3),
            4 => Some(&self.4),
            5 => Some(&self.5),
            6 => Some(&self.6),
            7 => Some(&self.7),
            _ => None,
        }
    }
}

impl<
        A: WidgetNew,
        B: WidgetNew,
        C: WidgetNew,
        D: WidgetNew,
        E: WidgetNew,
        F: WidgetNew,
        G: WidgetNew,
        H: WidgetNew,
        I: WidgetNew,
    > WidgetGroup for (A, B, C, D, E, F, G, H, I)
{
    fn len(&self) -> usize {
        9
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(&self.0),
            1 => Some(&self.1),
            2 => Some(&self.2),
            3 => Some(&self.3),
            4 => Some(&self.4),
            5 => Some(&self.5),
            6 => Some(&self.6),
            7 => Some(&self.7),
            8 => Some(&self.8),
            _ => None,
        }
    }
}

impl<
        A: WidgetNew,
        B: WidgetNew,
        C: WidgetNew,
        D: WidgetNew,
        E: WidgetNew,
        F: WidgetNew,
        G: WidgetNew,
        H: WidgetNew,
        I: WidgetNew,
        J: WidgetNew,
    > WidgetGroup for (A, B, C, D, E, F, G, H, I, J)
{
    fn len(&self) -> usize {
        10
    }

    fn get(&self, index: usize) -> Option<&dyn WidgetNew> {
        match index {
            0 => Some(&self.0),
            1 => Some(&self.1),
            2 => Some(&self.2),
            3 => Some(&self.3),
            4 => Some(&self.4),
            5 => Some(&self.5),
            6 => Some(&self.6),
            7 => Some(&self.7),
            8 => Some(&self.8),
            9 => Some(&self.9),
            _ => None,
        }
    }
}

//ffi_padding_get_left

/// Left, right, top, bottom
#[repr(C)]
pub struct Padding<W: WidgetNew> {
    pub padding: (u32, u32, u32, u32),
    pub child: W,
}

impl<W: WidgetNew> WidgetNew for Padding<W> {
    fn get_name(&self) -> &'static str {
        "Padding"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup
    where
        Self: Sized,
    {
        &self.child
    }
}

#[repr(C)]
pub struct PaddingFFI {
    pub padding: (u32, u32, u32, u32),
}

#[no_mangle]
pub unsafe extern "C" fn ffi_padding_get_left(w: &mut PaddingFFI) -> u32 {
    w.padding.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_padding_get_top(w: &mut PaddingFFI) -> u32 {
    w.padding.1
}

#[no_mangle]
pub unsafe extern "C" fn ffi_padding_get_right(w: &mut PaddingFFI) -> u32 {
    w.padding.2
}

#[no_mangle]
pub unsafe extern "C" fn ffi_padding_get_bottom(w: &mut PaddingFFI) -> u32 {
    w.padding.3
}

/* ========== Painting ========== */

/*#[derive(Copy, Clone)]
#[repr(u32)]
pub enum Color {
    Blue = 1,
    Green = 2,
    Red = 3,
    Purple = 4,
}*/

#[derive(Copy, Clone, serde::Serialize)]
#[repr(transparent)]
pub struct Color(pub u32);

impl Color {
    pub const BLUE: Color = Color(0xff2196f3);
    pub const GREEN: Color = Color(0xff4caf50);
    pub const RED: Color = Color(0xfff44336);
    pub const PURPLE: Color = Color(0xff7c4dff);

    pub const fn rgb(_r: u32, _b: u32, _g: u32) {
        panic!("From RGB not implemented");
    }
}

pub struct EmptyWidget;

impl WidgetNew for EmptyWidget {
    fn get_name(&self) -> &'static str {
        "EmptyWidget"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* Dynamic Line */

pub struct DynamicLine<'a> {
    pub value: &'a f32,
    pub width: f32,
    pub color: Color,
}

impl<'a> WidgetNew for DynamicLine<'a> {
    fn get_name(&self) -> &'static str {
        "DynamicLine"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_dynamic_line_get_value(w: &mut DynamicLine) -> f32 {
    *w.value
}

#[no_mangle]
pub unsafe extern "C" fn ffi_dynamic_line_get_color(w: &mut DynamicLine) -> u32 {
    w.color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_dynamic_line_get_width(w: &mut DynamicLine) -> f32 {
    w.width
}

#[repr(C)]
pub struct StepSequencer<'a, const X: usize, const Y: usize> {
    pub grid: &'a mut [[bool; Y]; X],
    pub step: &'a usize,
}

impl<'a, const X: usize, const Y: usize> WidgetNew for StepSequencer<'a, X, Y> {
    fn get_name(&self) -> &'static str {
        "StepSequencer"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn StepSequencerTrait) }
    }
}

pub trait StepSequencerTrait {
    fn get_pad(&self, x: usize, y: usize) -> bool;
    fn set_pad(&mut self, x: usize, y: usize, value: bool);
    fn get_step(&self) -> usize;
    fn get_rows(&self) -> usize;
    fn get_cols(&self) -> usize;
}

impl<'a, const X: usize, const Y: usize> StepSequencerTrait for StepSequencer<'a, X, Y> {
    fn get_pad(&self, x: usize, y: usize) -> bool {
        self.grid[x][y]
    }

    fn set_pad(&mut self, x: usize, y: usize, value: bool) {
        self.grid[x][y] = value;
    }

    fn get_step(&self) -> usize {
        *self.step
    }

    fn get_rows(&self) -> usize {
        Y
    }

    fn get_cols(&self) -> usize {
        X
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_step_sequencer_get_step(w: &mut dyn StepSequencerTrait) -> usize {
    w.get_step()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_step_sequencer_get_rows(
    w: &mut dyn StepSequencerTrait,
) -> usize {
    w.get_rows()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_step_sequencer_get_cols(
    w: &mut dyn StepSequencerTrait,
) -> usize {
    w.get_cols()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_step_sequencer_get_pad(
    w: &mut dyn StepSequencerTrait,
    x: usize,
    y: usize,
) -> bool {
    w.get_pad(x, y)
}

#[no_mangle]
pub unsafe extern "C" fn ffi_step_sequencer_set_pad(
    w: &mut dyn StepSequencerTrait,
    x: usize,
    y: usize,
    value: bool,
) {
    w.set_pad(x, y, value)
}
