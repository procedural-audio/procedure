use crate::widget::*;

#[repr(C)]
pub struct Button<F, T: WidgetNew>
where
    F: FnMut(bool),
{
    pub pressed: bool,
    pub toggle: bool,
    pub on_changed: F,
    pub child: T,
}

pub trait ButtonTrait {
    fn get_pressed(&self) -> bool;
    fn set_pressed(&mut self, pressed: bool);
    fn get_toggle(&self) -> bool;
    fn on_changed(&mut self, pressed: bool);
    fn get_children<'w>(&'w self) -> &'w dyn WidgetNew;
}

impl<F, T: WidgetNew> ButtonTrait for Button<F, T>
where
    F: FnMut(bool),
{
    fn get_pressed(&self) -> bool {
        self.pressed
    }

    fn set_pressed(&mut self, pressed: bool) {
        self.pressed = pressed;
    }

    fn get_toggle(&self) -> bool {
        self.toggle
    }

    fn on_changed(&mut self, pressed: bool) {
        (self.on_changed)(pressed)
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetNew {
        &self.child
    }
}

impl<F, T: WidgetNew> WidgetNew for Button<F, T>
where
    F: FnMut(bool),
{
    fn get_name(&self) -> &'static str {
        "Button"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &(self.child)
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn ButtonTrait) }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_button_get_pressed(button: &dyn ButtonTrait) -> bool {
    button.get_pressed()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_button_get_toggle(button: &dyn ButtonTrait) -> bool {
    button.get_toggle()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_button_on_changed(button: &mut dyn ButtonTrait, pressed: bool) {
    button.on_changed(pressed);
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
pub struct Svg {
    pub path: &'static str,
    pub color: Color,
}

impl WidgetNew for Svg {
    fn get_name(&self) -> &'static str {
        "Svg"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_svg_get_path(button: &mut Svg) -> *const i8 {
    let s = CString::new(button.path).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_svg_get_color(button: &mut Svg) -> u32 {
    button.color.0
}

/* ========== Container ========== */

pub struct Border {
    pub radius: u32,
    pub thickness: u32,
    pub color: Color,
}

#[repr(C)]
pub struct Container<T: WidgetNew> {
    pub size: (u32, u32),
    pub color: Color,
    pub border: Border,
    pub child: T,
}

impl<T: WidgetNew> WidgetNew for Container<T> {
    fn get_name(&self) -> &'static str {
        "Container"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &(self.child)
    }
}

#[repr(C)]
pub struct ContainerFFI {
    size: (u32, u32),
    color: Color,
    border: Border,
}

#[no_mangle]
pub unsafe extern "C" fn ffi_container_get_width(w: &mut ContainerFFI) -> u32 {
    w.size.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_container_get_height(w: &mut ContainerFFI) -> u32 {
    w.size.1
}

#[no_mangle]
pub unsafe extern "C" fn ffi_container_get_color(w: &mut ContainerFFI) -> u32 {
    w.color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_container_get_border_radius(w: &mut ContainerFFI) -> u32 {
    w.border.radius
}

#[no_mangle]
pub unsafe extern "C" fn ffi_container_get_border_thickness(w: &mut ContainerFFI) -> u32 {
    w.border.thickness
}

#[no_mangle]
pub unsafe extern "C" fn ffi_container_get_border_color(w: &mut ContainerFFI) -> u32 {
    w.border.color.0
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
    KeyPress(usize),
    KeyRelease(usize)
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
        (self.on_event)(KeyEvent::KeyPress(index), &mut self.keys)
    }

    fn key_release(&mut self, index: usize) {
        (self.on_event)(KeyEvent::KeyRelease(index), &mut self.keys)
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