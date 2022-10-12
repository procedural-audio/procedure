use crate::widget::*;

/* Fader */

#[repr(C)]
pub struct Fader<'a> {
    pub value: &'a mut f32,
    pub color: Color,
}

impl<'a> WidgetNew for Fader<'a> {
    fn get_name(&self) -> &'static str {
        "Fader"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_fader_get_value(widget: &mut Fader) -> f32 {
    *widget.value
}

#[no_mangle]
pub unsafe extern "C" fn ffi_fader_set_value(widget: &mut Fader, value: f32) {
    *widget.value = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_fader_get_color(widget: &mut Fader) -> Color {
    widget.color
}

#[no_mangle]
pub unsafe extern "C" fn ffi_fader_get_label(_widget: &mut Fader) -> *const i8 {
    let s = CString::new("Hi").unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

/* Slider */

#[repr(C)]
pub struct Slider<'a> {
    pub value: &'a mut f32,
    pub divisions: u32,
    pub color: Color,
}

impl<'a> WidgetNew for Slider<'a> {
    fn get_name(&self) -> &'static str {
        "Slider"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_slider_get_value(widget: &mut Slider) -> f32 {
    *widget.value
}

#[no_mangle]
pub unsafe extern "C" fn ffi_slider_get_divisions(widget: &mut Slider) -> u32 {
    widget.divisions
}

#[no_mangle]
pub unsafe extern "C" fn ffi_slider_set_value(widget: &mut Slider, value: f32) {
    *widget.value = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_slider_get_color(widget: &mut Slider) -> Color {
    widget.color
}

/* Range Slider */

#[repr(C)]
pub struct RangeSlider<'a> {
    pub min: &'a mut f32,
    pub max: &'a mut f32,
    pub divisions: u32,
    pub color: Color,
}

impl<'a> WidgetNew for RangeSlider<'a> {
    fn get_name(&self) -> &'static str {
        "RangeSlider"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_range_slider_get_min_value(widget: &mut RangeSlider) -> f32 {
    *widget.min
}

#[no_mangle]
pub unsafe extern "C" fn ffi_range_slider_get_max_value(widget: &mut RangeSlider) -> f32 {
    *widget.max
}

#[no_mangle]
pub unsafe extern "C" fn ffi_range_slider_set_min_value(widget: &mut RangeSlider, value: f32) {
    *widget.min = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_range_slider_set_max_value(widget: &mut RangeSlider, value: f32) {
    *widget.max = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_range_slider_get_divisions(widget: &mut RangeSlider) -> u32 {
    widget.divisions
}

#[no_mangle]
pub unsafe extern "C" fn ffi_range_slider_get_color(widget: &mut RangeSlider) -> Color {
    widget.color
}

/* ========== GridBuilder ========== */

pub struct GridBuilder<'a, V, F, R: WidgetNew>
where
    F: FnOnce(usize, &'a mut V) -> R + 'a,
{
    pub columns: usize,
    pub state: &'a mut [V],
    pub builder: F,
}

impl<'a, V, F, R: WidgetNew> WidgetNew for GridBuilder<'a, V, F, R>
where
    F: FnOnce(usize, &'a mut V) -> R,
{
    fn get_name(&self) -> &'static str {
        "GridBuilder"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn GridBuilderTrait) }
    }
}

pub trait GridBuilderTrait {
    fn get_count(&self) -> usize;
    fn get_columns(&self) -> usize;
    fn create_child(&mut self, index: usize) -> Box<dyn WidgetNew>;
}

impl<'a, V, F, R: WidgetNew> GridBuilderTrait for GridBuilder<'a, V, F, R>
where
    F: FnOnce(usize, &'a mut V) -> R,
{
    fn get_count(&self) -> usize {
        self.state.len()
    }

    fn get_columns(&self) -> usize {
        self.columns
    }

    fn create_child(&mut self, index: usize) -> Box<dyn WidgetNew> {
        // BREAKING RUST OWNERSHIP RULES HERE
        unsafe {
            let temp0: Self = std::mem::transmute_copy(self);
            let temp1: Box<dyn WidgetNew> = Box::new((temp0.builder)(
                index,
                std::mem::transmute(&mut self.state[index]),
            ));
            let temp2: Box<dyn WidgetNew> = std::mem::transmute_copy(&temp1);
            std::mem::forget(temp1);

            return temp2;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_grid_builder_trait_get_count(
    grid_builder: &mut dyn GridBuilderTrait,
) -> usize {
    grid_builder.get_count()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_grid_builder_trait_get_columns(
    grid_builder: &mut dyn GridBuilderTrait,
) -> usize {
    grid_builder.get_columns()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_grid_builder_trait_create_child(
    grid_builder: &mut dyn GridBuilderTrait,
    index: usize,
) -> Box<dyn WidgetNew> {
    grid_builder.create_child(index)
}

#[no_mangle]
pub unsafe extern "C" fn ffi_grid_builder_trait_destroy_child(child: Box<dyn WidgetNew>) {
    let _ = child;
}

/* ========== Number ========== */

#[repr(C)]
pub struct Number<'a> {
    pub value: &'a mut i32,
    pub color: Color,
}

impl<'a> WidgetNew for Number<'a> {
    fn get_name(&self) -> &'static str {
        "Number"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_number_get_value(widget: &mut Number) -> i32 {
    *widget.value
}

#[no_mangle]
pub unsafe extern "C" fn ffi_number_set_value(widget: &mut Number, value: i32) {
    *widget.value = value;
}

/* ========== Input ========== */

pub use std::str::FromStr;
use std::string::ToString;

#[repr(C)]
pub struct Input<T: ToString, F>
where
    F: FnMut(&str) -> Result<T, String>,
{
    pub value: T,
    pub on_changed: F,
}

impl<T: ToString, F> WidgetNew for Input<T, F>
where
    F: FnMut(&str) -> Result<T, String>,
{
    fn get_name(&self) -> &'static str {
        "Input"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn InputTrait) }
    }
}

pub trait InputTrait {
    fn get_value(&self) -> String;
    fn set_value(&mut self, value: &str) -> Result<(), String>;
}

impl<T: ToString, F> InputTrait for Input<T, F>
where
    F: FnMut(&str) -> Result<T, String>,
{
    fn get_value(&self) -> String {
        self.value.to_string()
    }

    fn set_value(&mut self, value: &str) -> Result<(), String> {
        match (self.on_changed)(value) {
            Ok(v) => {
                self.value = v;
                Ok(())
            }
            Err(e) => Err(e),
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_input_get_value(widget: &mut dyn InputTrait) -> *const i8 {
    let s = CString::new(widget.get_value()).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_input_set_value(
    widget: &mut dyn InputTrait,
    value: *const i8,
) -> *const i8 {
    let c_str = std::ffi::CStr::from_ptr(value);
    let str_slice = c_str.to_str().unwrap();
    match widget.set_value(str_slice) {
        Ok(()) => std::ptr::null(),
        Err(s) => {
            let s = CString::new(s).unwrap();
            let p = s.as_ptr();
            std::mem::forget(s);
            p
        }
    }
}

/* Refresh Callback */

pub struct Callback {
    should_refresh: bool,
}

impl Callback {
    pub fn new() -> Self {
        Self {
            should_refresh: false,
        }
    }

    pub fn trigger(&mut self) {
        self.should_refresh = true;
    }

    pub fn is_triggered(&self) -> bool {
        self.should_refresh
    }

    pub fn set_triggered(&mut self, triggered: bool) {
        self.should_refresh = triggered;
    }
}

/* Refresh */

#[repr(C)]
pub struct Refresh<'a, T: WidgetNew> {
    pub callback: &'a mut Callback,
    pub child: T,
}

impl<'a, T: WidgetNew> WidgetNew for Refresh<'a, T> {
    fn get_name(&self) -> &'static str {
        "Refresh"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &(self.child)
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn RefreshTrait) }
    }
}

pub trait RefreshTrait {
    fn get_should_refresh(&self) -> bool;
    fn set_should_refresh(&mut self, should_refresh: bool);
}

impl<'a, T: WidgetNew> RefreshTrait for Refresh<'a, T> {
    fn get_should_refresh(&self) -> bool {
        (*self.callback).is_triggered()
    }

    fn set_should_refresh(&mut self, should_refresh: bool) {
        (*self.callback).set_triggered(should_refresh);
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_refresh_get_should_refresh(widget: &mut dyn RefreshTrait) -> bool {
    widget.get_should_refresh()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_refresh_set_should_refresh(
    widget: &mut dyn RefreshTrait,
    should_refresh: bool,
) {
    widget.set_should_refresh(should_refresh);
}

/* Rebuild */

#[repr(C)]
pub struct Rebuild<'a, T: WidgetNew> {
    pub callback: &'a mut Callback,
    pub child: T,
}

impl<'a, T: WidgetNew> WidgetNew for Rebuild<'a, T> {
    fn get_name(&self) -> &'static str {
        "Rebuild"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &(self.child)
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn RebuildTrait) }
    }
}

pub trait RebuildTrait {
    fn get_should_rebuild(&self) -> bool;
    fn set_should_rebuild(&mut self, should_refresh: bool);
}

impl<'a, T: WidgetNew> RebuildTrait for Rebuild<'a, T> {
    fn get_should_rebuild(&self) -> bool {
        (*self.callback).is_triggered()
    }

    fn set_should_rebuild(&mut self, should_refresh: bool) {
        (*self.callback).set_triggered(should_refresh);
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_rebuild_get_should_refresh(widget: &mut dyn RebuildTrait) -> bool {
    widget.get_should_rebuild()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_rebuild_set_should_refresh(
    widget: &mut dyn RebuildTrait,
    should_refresh: bool,
) {
    widget.set_should_rebuild(should_refresh);
}

/* Fader */

#[repr(C)]
pub struct Indicator<'a> {
    pub color: &'a Color,
}

impl<'a> WidgetNew for Indicator<'a> {
    fn get_name(&self) -> &'static str {
        "Indicator"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_indicator_get_color(widget: &mut Indicator) -> u32 {
    widget.color.0
}
