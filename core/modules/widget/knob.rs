use crate::{widget::*, AudioChannel};

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
pub struct SamplePicker<'a> {
    pub sample: std::sync::Arc<std::sync::RwLock<crate::SampleFile<2>>>,
    pub color: Color,
    pub start: &'a mut f32,
    pub end: &'a mut f32,
    pub attack: &'a mut f32,
    pub release: &'a mut f32,
    pub should_loop: &'a mut bool,
    pub loop_start: &'a mut f32,
    pub loop_end: &'a mut f32,
    pub loop_crossfade: &'a mut f32,
    pub one_shot: &'a mut bool,
    pub reverse: &'a mut bool,
}

impl<'a> WidgetNew for SamplePicker<'a> {
    fn get_name(&self) -> &'static str {
        "SamplePicker"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_get_buffer(widget: &mut SamplePicker) -> FFIBuffer {
    // let mut buffer_new = Vec::new();
    let sample = &*widget.sample.read().unwrap();

    todo!()

    // let skip = sample.as_array()[0].len() / 300;

    /*for sample in sample.as_array()[0].iter() { // .step_by(skip) {
        buffer_new.push(*sample);
    }

    let buffer_ret = FFIBuffer {
        data: buffer_new.as_mut_ptr(),
        length: buffer_new.len(),
    };

    std::mem::forget(buffer_new);

    return buffer_ret;*/

    // ^^^ Change this?
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_get_start(widget: &mut SamplePicker) -> f32 {
    *widget.start
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_set_start(widget: &mut SamplePicker, value: f32) {
    *widget.start = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_get_end(widget: &mut SamplePicker) -> f32 {
    *widget.end
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_set_end(widget: &mut SamplePicker, value: f32) {
    *widget.end = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_get_attack(widget: &mut SamplePicker) -> f32 {
    *widget.attack
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_set_attack(widget: &mut SamplePicker, value: f32) {
    *widget.attack = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_get_release(widget: &mut SamplePicker) -> f32 {
    *widget.release
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_set_release(widget: &mut SamplePicker, value: f32) {
    *widget.release = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_get_should_loop(widget: &mut SamplePicker) -> bool {
    *widget.should_loop
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_set_should_loop(widget: &mut SamplePicker, value: bool) {
    *widget.should_loop = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_get_loop_start(widget: &mut SamplePicker) -> f32 {
    *widget.loop_start
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_set_loop_start(widget: &mut SamplePicker, value: f32) {
    *widget.loop_start = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_get_loop_end(widget: &mut SamplePicker) -> f32 {
    *widget.loop_end
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_set_loop_end(widget: &mut SamplePicker, value: f32) {
    *widget.loop_end = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_get_loop_crossfade(widget: &mut SamplePicker) -> f32 {
    *widget.loop_crossfade
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_set_loop_crossfade(
    widget: &mut SamplePicker,
    value: f32,
) {
    *widget.loop_crossfade = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_get_one_shot(widget: &mut SamplePicker) -> bool {
    return *widget.one_shot;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_set_one_shot(widget: &mut SamplePicker, value: bool) {
    *widget.one_shot = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_get_reverse(widget: &mut SamplePicker) -> bool {
    return *widget.reverse;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_sample_picker_set_reverse(widget: &mut SamplePicker, value: bool) {
    *widget.reverse = value;
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
        Err(e) => {
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

fn str_from_char(buffer: &i8) -> &str {
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