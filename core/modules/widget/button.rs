use crate::widget::*;
use crate::widget::traits::*;

#[repr(C)]
pub struct Button<F>
where
    F: FnMut(bool),
{
    pub color: Color,
    pub on_pressed: F,
}

pub trait ButtonTrait {
    fn get_color(&self) -> Color;
    fn on_pressed(&mut self, down: bool);
}

impl<F> ButtonTrait for Button<F>
where
    F: FnMut(bool),
{
    fn get_color(&self) -> Color {
        self.color
    }

    fn on_pressed(&mut self, down: bool) {
        (self.on_pressed)(down)
    }
}

impl<F> WidgetNew for Button<F>
where
    F: FnMut(bool),
{
    fn get_name(&self) -> &'static str {
        "Button"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn ButtonTrait) }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_button_get_color(button: &mut dyn ButtonTrait) -> Color {
    button.get_color()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_button_on_pressed(button: &mut dyn ButtonTrait, down: bool) {
    button.on_pressed(down);
}

/* ========== Positioned ========== */

#[repr(C)]
pub struct Positioned<T: WidgetNew> {
    pub position: (i32, i32),
    pub child: T,
}

impl<T: WidgetNew> WidgetNew for Positioned<T> {
    fn get_name(&self) -> &'static str {
        "Positioned"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &(self.child)
    }
}

#[repr(C)]
pub struct PositionedFFI {
    pub position: (i32, i32),
}

#[no_mangle]
pub unsafe extern "C" fn ffi_positioned_get_x(widget: &mut PositionedFFI) -> i32 {
    widget.position.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_positioned_get_y(widget: &mut PositionedFFI) -> i32 {
    widget.position.1
}

/* ========== SizedBox ========== */

#[repr(C)]
pub struct SizedBox<T: WidgetNew> {
    pub size: (u32, u32),
    pub child: T,
}

impl<T: WidgetNew> WidgetNew for SizedBox<T> {
    fn get_name(&self) -> &'static str {
        "SizedBox"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &(self.child)
    }
}

#[repr(C)]
pub struct SizedBoxFFI {
    pub size: (u32, u32),
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sized_box_get_width(widget: &mut SizedBoxFFI) -> u32 {
    widget.size.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sized_box_get_height(widget: &mut SizedBoxFFI) -> u32 {
    widget.size.1
}

/* ========== SvgButton ========== */

#[repr(C)]
pub struct SvgButton<'a> {
    pub path: &'static str,
    pub pressed: bool,
    pub color: Color,
    pub on_changed: Box<dyn FnMut(bool) + 'a>,
}

impl<'a> WidgetNew for SvgButton<'a> {
    fn get_name(&self) -> &'static str {
        "SvgButton"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_svg_button_get_path(button: &mut SvgButton) -> *const i8 {
    let s = CString::new(button.path).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_svg_button_get_pressed(button: &mut SvgButton) -> bool {
    button.pressed
}

#[no_mangle]
pub unsafe extern "C" fn ffi_svg_button_set_pressed(button: &mut SvgButton, pressed: bool) {
    button.pressed = pressed;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_svg_button_get_color(button: &mut SvgButton) -> u32 {
    button.color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_svg_button_on_changed(button: &mut SvgButton, pressed: bool) {
    button.pressed = pressed;
    (button.on_changed)(pressed);
}

/* ========== Transform ========== */

#[repr(C)]
pub struct Transform<T: WidgetNew> {
    pub position: (i32, i32),
    pub size: (u32, u32),
    pub child: T,
}

impl<T: WidgetNew> WidgetNew for Transform<T> {
    fn get_name(&self) -> &'static str {
        "Transform"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &(self.child)
    }
}

#[repr(C)]
pub struct TransformFFI {
    pub position: (i32, i32),
    pub size: (u32, u32),
}

#[no_mangle]
pub unsafe extern "C" fn ffi_transform_get_x(widget: &mut TransformFFI) -> i32 {
    widget.position.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_transform_get_y(widget: &mut TransformFFI) -> i32 {
    widget.position.1
}

#[no_mangle]
pub unsafe extern "C" fn ffi_transform_get_width(widget: &mut TransformFFI) -> u32 {
    widget.size.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_transform_get_height(widget: &mut TransformFFI) -> u32 {
    widget.size.1
}

/* ========== Svg ========== */

#[repr(C)]
pub struct Icon<T: IntoColor> {
    pub path: &'static str,
    pub color: T,
}

impl<T: IntoColor> WidgetNew for Icon<T> {
    fn get_name(&self) -> &'static str {
        "Svg"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn IconTrait) }
    }
}

pub trait IconTrait {
    fn get_path(&self) -> &'static str;
    fn get_color(&self) -> Color;
}

impl<T: IntoColor> IconTrait for Icon<T> {
    fn get_path(&self) -> &'static str {
        self.path
    }

    fn get_color(&self) -> Color {
        self.color.into_color()
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_svg_get_path(button: &mut dyn IconTrait) -> *const i8 {
    let s = CString::new(button.get_path()).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_svg_get_color(button: &mut dyn IconTrait) -> u32 {
    button.get_color().0
}

/* ========== Container ========== */

pub struct Border {
    pub radius: u32,
    pub width: u32,
    pub color: Color,
}

impl Border {
    pub const NONE: Self = Self {
        radius: 0,
        width: 0,
        color: Color(0),
    };

    pub fn radius(radius: u32) -> Self {
        Self {
            radius,
            width: 0,
            color: Color(0),
        }
    }
}

#[repr(C)]
pub struct Background<T: WidgetNew> {
    pub color: Color,
    pub border: Border,
    pub child: T,
}

impl<T: WidgetNew> WidgetNew for Background<T> {
    fn get_name(&self) -> &'static str {
        "Background"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &(self.child)
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn BackgroundTrait) }
    }
}

pub trait BackgroundTrait {
    fn get_color(&self) -> Color;
    fn get_border_radius(&self) -> u32;
    fn get_border_width(&self) -> u32;
    fn get_border_color(&self) -> Color;
}

impl<T: WidgetNew> BackgroundTrait for Background<T> {
    fn get_color(&self) -> Color {
        self.color
    }

    fn get_border_radius(&self) -> u32 {
        self.border.radius
    }

    fn get_border_width(&self) -> u32 {
        self.border.width
    }

    fn get_border_color(&self) -> Color {
        self.border.color
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_background_get_color(w: &dyn BackgroundTrait) -> u32 {
    w.get_color().0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_background_get_border_radius(w: &dyn BackgroundTrait) -> u32 {
    w.get_border_radius()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_background_get_border_width(w: &dyn BackgroundTrait) -> u32 {
    w.get_border_width()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_background_get_border_color(w: &dyn BackgroundTrait) -> u32 {
    w.get_border_color().0
}

/* Simple Button */

use std::ffi::CString;

#[repr(C)]
pub struct SimpleButton<'a> {
    pub text: &'a str,
    pub toggle: bool,
    pub color: Color,
    pub pressed: &'a mut bool,
}

impl<'a> WidgetNew for SimpleButton<'a> {
    fn get_name(&self) -> &'static str {
        "SimpleButton"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_button_set_value(knob: &mut SimpleButton, value: bool) {
    *knob.pressed = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_button_get_color(knob: &mut SimpleButton) -> u32 {
    knob.color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_button_get_toggle(knob: &mut SimpleButton) -> bool {
    knob.toggle // ARE BOOLS THE SAME SIZE IN RUST AND DART ???
}

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_button_get_label(knob: &mut SimpleButton) -> *const i8 {
    let s = match CString::new(knob.text) {
        Ok(s) => s,
        Err(e) => {
            println!("Error with knob label {}: {}", knob.text, e);
            CString::new("").unwrap()
        }
    };

    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

/* Simple Fader */

#[repr(C)]
pub struct SimpleFader<'a> {
    pub text: &'a str,
    pub color: Color,
    pub value: f32,
    pub control: &'a f32,
    pub on_changed: Box<dyn FnMut(f32) + 'a>,
}

impl<'a> WidgetNew for SimpleFader<'a> {
    fn get_name(&self) -> &'static str {
        "SimpleFader"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_fader_set_value(knob: &mut SimpleFader, value: f32) {
    knob.value = value;
    (*knob.on_changed)(value);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_fader_get_color(knob: &mut SimpleFader) -> u32 {
    knob.color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_fader_get_label(knob: &mut SimpleFader) -> *const i8 {
    let s = match CString::new(knob.text) {
        Ok(s) => s,
        Err(e) => {
            println!("Error with knob label {}: {}", knob.text, e);
            CString::new("").unwrap()
        }
    };

    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

/* Float Box */

#[repr(C)]
pub struct FloatBox<'a> {
    pub value: &'a mut f32,
}

impl<'a> WidgetNew for FloatBox<'a> {
    fn get_name(&self) -> &'static str {
        "FloatBox"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_float_box_get_value(widget: &mut FloatBox) -> f32 {
    *widget.value
}

#[no_mangle]
pub unsafe extern "C" fn ffi_float_box_set_value(widget: &mut FloatBox, value: f32) {
    *widget.value = value;
}

/*pub struct Callback {

}

impl Callback {
    pub fn new() -> Self {
        Self {}
    }

    pub fn trigger(&self) {
        println!("Triggering callback");
    }
}

#[repr(C)]
pub struct Refresh<'a, T: WidgetNew> {
    pub callback: &'a Callback,
    pub child: T,
}

impl<'a, T: WidgetNew> WidgetNew for Refresh<'a, T> {
    fn get_name(&self) -> &'static str {
        "Refresh"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &(self.child)
    }
}
*/

/* Display */

#[repr(C)]
pub struct Display<F: FnMut() -> Option<String>> {
    pub text: F,
}

impl<F: FnMut() -> Option<String>> WidgetNew for Display<F> {
    fn get_name(&self) -> &'static str {
        "Display"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn DisplayTrait) }
    }
}

pub trait DisplayTrait {
    fn get_text(&mut self) -> Option<String>;
}

impl<F: FnMut() -> Option<String>> DisplayTrait for Display<F> {
    fn get_text(&mut self) -> Option<String> {
        (self.text)()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_display_get_text(widget: &mut dyn DisplayTrait) -> *const i8 {
    match widget.get_text() {
        Some(text) => {
            let s = CString::new(text).unwrap();
            let p = s.as_ptr();
            std::mem::forget(s);
            p
        }
        None => std::ptr::null(),
    }
}

/* Keyboard */

#[derive(Copy, Clone)]
pub struct Key {
    pub down: bool
}

pub enum KeyEvent {
    Press(usize),
    Release(usize)
}

#[repr(C)]
pub struct Keyboard<'a, const X: usize, F: FnMut(KeyEvent, &mut [Key; X])> {
    pub keys: &'a mut [Key; X],
    pub on_event: F,
}

impl<'a, const X: usize, F: FnMut(KeyEvent, &mut [Key; X])> WidgetNew for Keyboard<'a, X, F> {
    fn get_name(&self) -> &'static str {
        "Keyboard"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn KeyboardTrait) }
    }
}

pub trait KeyboardTrait {
    fn get_key_count(&self) -> usize;
    fn key_get_down(&self, index: usize) -> bool;
    fn key_press(&mut self, index: usize);
    fn key_release(&mut self, index: usize);
}

impl<'a, const X: usize, F: FnMut(KeyEvent, &mut [Key; X])> KeyboardTrait for Keyboard<'a, X, F> {
    fn get_key_count(&self) -> usize {
        X
    }

    fn key_get_down(&self, index: usize) -> bool {
        self.keys[index].down
    }

    fn key_press(&mut self, index: usize) {
        (self.on_event)(KeyEvent::Press(index), &mut self.keys)
    }

    fn key_release(&mut self, index: usize) {
        (self.on_event)(KeyEvent::Release(index), &mut self.keys)
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_keyboard_get_key_count(widget: &mut dyn KeyboardTrait) -> usize {
    widget.get_key_count()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_keyboard_key_get_down(widget: &mut dyn KeyboardTrait, index: usize) -> bool {
    widget.key_get_down(index)
}

#[no_mangle]
pub unsafe extern "C" fn ffi_keyboard_key_press(widget: &mut dyn KeyboardTrait, index: usize) {
    widget.key_press(index)
}

#[no_mangle]
pub unsafe extern "C" fn ffi_keyboard_key_release(widget: &mut dyn KeyboardTrait, index: usize) {
    widget.key_release(index)
}