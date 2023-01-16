use pa_dsp::{SampleFile, FileLoad};

use crate::widget::*;

#[repr(C)]
pub struct Knob<'a> {
    pub text: &'a str,
    pub color: Color,
    pub value: &'a mut f32,
    pub feedback: Box<dyn FnMut(f32) -> String + 'a>,
}

impl<'a> WidgetNew for Knob<'a> {
    fn get_name(&self) -> &'static str {
        "Knob"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_knob_get_value(knob: &mut Knob) -> f32 {
    *knob.value
}

#[no_mangle]
pub unsafe extern "C" fn ffi_knob_set_value(knob: &mut Knob, mut value: f32) {
    if value < 0.0 {
        value = 0.0;
    }

    if value > 1.0 {
        value = 1.0;
    }

    *knob.value = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_knob_get_feedback(knob: &mut Knob) -> *const i8 {
    let value = *knob.value;
    let s = match CString::new((knob.feedback)(value)) {
        Ok(s) => s,
        Err(e) => {
            println!("Error with knob feedback {}: {}", knob.text, e);
            CString::new("").unwrap()
        }
    };

    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_knob_get_color(knob: &mut Knob) -> u32 {
    knob.color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_knob_get_label(knob: &mut Knob) -> *const i8 {
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

/* ========== UI Knob ========== */

/*
#[repr(C)]
pub struct UIKnob<'a> {
    pub text: &'a str,
    pub on_changed: Box<dyn FnMut(f32) + 'a>,
}

impl<'a> WidgetNew for UIKnob<'a> {
    fn get_name(&self) -> &'static str {
        "Knob"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_ui_knob_set_value(knob: &mut UIKnob, value: f32) {
    knob.value = value;
    (*knob.on_changed)(value);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_ui_knob_get_color(knob: &mut UIKnob) -> u32 {
    knob.color as u32
}

#[no_mangle]
pub unsafe extern "C" fn ffi_ui_knob_get_label(knob: &mut UIKnob) -> *const i8 {
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
*/

#[derive(Copy, Clone)]
#[repr(C)]
pub struct FFIBuffer {
    pub data: *mut f32,
    pub length: usize,
}

#[repr(C)]
pub struct SampleFilePicker {
    pub sample: std::sync::Arc<std::sync::RwLock<crate::SampleFile<crate::Stereo2>>>,
}

impl WidgetNew for SampleFilePicker {
    fn get_name(&self) -> &'static str {
        "SamplePicker"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_file_picker_get_buffer_length(widget: &mut SampleFilePicker) -> usize {
    widget.sample.read().unwrap().len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_file_picker_get_sample_left(widget: &mut SampleFilePicker, index: usize) -> f32 {
    (*widget.sample.read().unwrap()).as_slice()[index].left
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_file_picker_get_sample_right(widget: &mut SampleFilePicker, index: usize) -> f32 {
    (*widget.sample.read().unwrap()).as_slice()[index].right
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_file_picker_set_sample(widget: &mut SampleFilePicker, path: &i8) {
    let path= str_from_char(path);
    let sample = SampleFile::load(path);
    match widget.sample.write() {
        Ok(mut old) => {
            *old = sample.clone();
        },
        _ => ()
    }
}

#[repr(C)]
pub struct Text {
    pub text: &'static str,
    pub color: Color,
    pub size: u32
}

impl WidgetNew for Text {
    fn get_name(&self) -> &'static str {
        "Text"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_text_get_text(w: &mut Text) -> *const i8 {
    let s = match CString::new(w.text) {
        Ok(s) => s,
        Err(_) => {
            CString::new("Error").unwrap()
        }
    };

    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_text_get_color(w: &mut Text) -> u32 {
    w.color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_text_get_size(w: &mut Text) -> u32 {
    w.size
}

/* Icon Select */

#[repr(C)]
pub struct ButtonGrid<'a> {
    pub index: &'a mut usize,
    pub color: Color,
    pub rows: usize,
    pub icons: &'static [&'static str]
}

impl<'a> WidgetNew for ButtonGrid<'a> {
    fn get_name(&self) -> &'static str {
        "ButtonGrid"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_button_grid_get_index(widget: &mut ButtonGrid) -> usize {
    *widget.index
}

#[no_mangle]
pub unsafe extern "C" fn ffi_button_grid_set_index(widget: &mut ButtonGrid, index: usize) {
    *widget.index = index;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_button_grid_get_color(widget: &mut ButtonGrid) -> u32 {
    widget.color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_button_grid_get_row_count(widget: &mut ButtonGrid) -> usize {
    widget.rows
}

#[no_mangle]
pub unsafe extern "C" fn ffi_button_grid_get_icon_count(widget: &mut ButtonGrid) -> usize {
    widget.icons.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_button_grid_icon_get_path(widget: &mut ButtonGrid, index: usize) -> *const i8 {
    let s = CString::new(widget.icons[index]).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

pub struct Category<T> {
    pub name: T,
    pub elements: Vec<T>
}


pub struct SearchableDropdown<F: FnMut(&str)> {
    pub categories: Vec<Category<String>>,
    pub on_select: F
}

impl<F: FnMut(&str)> WidgetNew for SearchableDropdown<F> {
    fn get_name(&self) -> &'static str {
        "SearchableDropdown"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }

    fn get_trait<'w>(&'w self) -> &'w dyn WidgetNew {
        unsafe { std::mem::transmute(self as &dyn SearchableDropdownTrait) }
    }
}

pub fn str_from_char(buffer: &i8) -> &str {
    unsafe {
        let c_str: &std::ffi::CStr = std::ffi::CStr::from_ptr(buffer);
        c_str.to_str().unwrap()
    }
}

pub trait SearchableDropdownTrait {
    fn on_select(&mut self, element: &str);
}

impl<F: FnMut(&str)> SearchableDropdownTrait for SearchableDropdown<F> {
    fn on_select(&mut self, element: &str) {
        (self.on_select)(element);
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_searchable_dropdown_on_select(widget: &mut dyn SearchableDropdownTrait, element: &i8) {
    widget.on_select(str_from_char(element));
}

pub struct Scripter<T: WidgetNew, F: FnMut(&str)> {
    pub dir: &'static str,
    pub on_update: F,
    pub child: T
}

impl<T: WidgetNew, F: FnMut(&str)> WidgetNew for Scripter<T, F> {
    fn get_name(&self) -> &'static str {
        "LuaEditor"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &(self.child)
    }
}