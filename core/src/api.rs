extern crate metasampler_macros;
extern crate rand;
extern crate serde;
extern crate serde_json;

extern crate tonevision_types;

mod host;
mod modules;
mod widgets;

use crate::host::*;

use std::ffi::CStr;
use std::ffi::CString;

use tonevision_types::AudioChannelMut;
use widgets::*;

use tonevision_types::*;

/* Begin main */

#[no_mangle]
pub unsafe fn ffi_hack_convert(data: usize) -> usize {
    data
}

#[no_mangle]
pub extern "C" fn api_io_test() {}

#[no_mangle]
pub unsafe extern "C" fn ffi_create_host() -> *mut Host {
    println!("CREATING NEW HOST");
    Box::into_raw(api_create_host())
}

#[no_mangle]
pub unsafe extern "C" fn api_create_host() -> Box<Host> {
    Box::new(Host::new())
}

#[no_mangle]
pub unsafe extern "C" fn ffi_destroy_host(host: *mut Host) {
    let _ = Box::from_raw(host);
}

/*#[no_mangle]
pub extern "C" fn ffi_host_create_gui(host: *mut Host) {
    println!("Creating GUI in rust");

    exec_bundle();
    register_observatory_listener("metasampler".into());

    let context = Context::new(ContextOptions {
        app_namespace: "NativeShellDemo".into(),
        flutter_plugins: flutter_get_plugins(),
        ..Default::default()
    });

    let context = context.unwrap();

    let _file_open_dialog = FileOpenDialog::new(context.weak()).register();
    let _platform_channels = PlatformChannels::new(context.weak()).register();

    context
        .window_manager
        .borrow_mut()
        .create_window(codec::Value::I64(host as i64), None)
        .unwrap();

    context.run_loop.borrow().run();
}*/

fn str_from_char(buffer: &i8) -> &str {
    unsafe {
        let c_str: &CStr = CStr::from_ptr(buffer);
        c_str.to_str().unwrap()
    }
}

/* Host */

#[no_mangle]
pub unsafe extern "C" fn ffi_host_load(host: &mut Host, buffer: &i8) -> bool {
    host.load(str_from_char(buffer));
    true
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_save(host: &mut Host, buffer: &i8) -> bool {
    host.save(str_from_char(buffer));
    true
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_prepare(host: &mut Host, sample_rate: u32, block_size: u32) {
    host.prepare(sample_rate, block_size as usize);
}

#[no_mangle]
pub unsafe extern "C" fn api_host_process(
    host: &mut Host,
    audio: *mut [AudioBuffer],
    events: *mut [NoteBuffer],
) {
    for buffer in &mut *audio {
        buffer.zero();
    }

    host.process(&mut *audio, &mut *events);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_process(
    host: &mut Host,
    buffer: *mut *mut f32,
    num_channels: u32,
    num_samples: u32,
    events: *mut Event,
    events_count: u32,
) {
    let mut events = NoteBuffer::from_raw(events, events_count as usize);
    events.forget();

    if num_channels == 0 {
        println!("No IO channels available");
    } else if num_channels == 1 {
        let buffer_center = AudioBuffer::from_raw(*buffer.offset(0), num_samples as usize);

        let mut audio = [buffer_center];

        api_host_process(host, &mut audio, &mut [events]);

        std::mem::forget(audio);
    } else if num_channels == 2 {
        let buffer_left = AudioBuffer::from_raw(*buffer.offset(0), num_samples as usize);
        let buffer_right = AudioBuffer::from_raw(*buffer.offset(1), num_samples as usize);

        let mut audio = [buffer_left, buffer_right];

        api_host_process(host, &mut audio, &mut [events]);

        std::mem::forget(audio);
    } else {
        println!("Unsupported channel number");
    }
}

/* Host Graph */
#[no_mangle]
pub unsafe extern "C" fn ffi_host_refresh(host: &mut Host) {
    host.graph.refresh();
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_add_module(host: &mut Host, buffer: &i8) -> bool {
    host.graph.add_module(str_from_char(buffer))
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_remove_node(host: &mut Host, id: i32) -> bool {
    host.graph.remove_module(id);
    true
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_get_node_count(host: &mut Host) -> usize {
    host.graph.nodes.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_get_node(host: &mut Host, index: usize) -> &Node {
    host.graph.nodes[index].as_ref()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_get_vars_count(host: &mut Host) -> usize {
    host.vars.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_get_var_name(host: &mut Host, index: usize) -> *const i8 {
    let s = CString::new(host.vars[index].name.clone()).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_get_var_group(host: &mut Host, index: usize) -> *const i8 {
    match &host.vars[index].group {
        Some(group) => {
            let s = CString::new(group.clone()).unwrap();
            let p = s.as_ptr();
            std::mem::forget(s);
            p
        }
        None => std::ptr::null(),
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_add_var(host: &mut Host, kind: u32, group: *const i8) {
    let mut name = String::from("New Variable");
    let mut i = 2;
    let mut found = true;

    while found {
        found = false;

        for var in &host.vars {
            if var.name == name {
                found = true;
                name = format!("New Variable {}", i);
                i += 1;
            }
        }
    }

    host.vars.push(
        Var {
            name,
            group: if group == std::ptr::null() {
                None
            } else {
                let cstr = CStr::from_ptr(group);
                let s = cstr.to_str().unwrap().to_string();
                Some(s)
            },
            value: match kind {
                0 => VarValue::Float(0.0),
                1 => VarValue::Bool(false),
                _ => panic!("Unsupported var type")
            }
        }
    );
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_get_var_value_type(host: &mut Host, index: usize) -> u32 {
    match host.vars[index].value {
        VarValue::Float(_) => 0,
        VarValue::Bool(_) => 1,
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_get_var_value_float(host: &mut Host, index: usize) -> f32 {
    match host.vars[index].value {
        VarValue::Float(v) => v,
        VarValue::Bool(_) => panic!("Got variable wrong type"),
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_set_var_value_float(host: &mut Host, index: usize, value: f32) {
    match &mut host.vars[index].value {
        VarValue::Float(v) => *v = value,
        VarValue::Bool(_) => panic!("Set variable wrong type"),
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_get_var_value_bool(host: &mut Host, index: usize) -> bool {
    match host.vars[index].value {
        VarValue::Float(_) => panic!("Got variable wrong type"),
        VarValue::Bool(v) => v,
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_set_var_value_bool(host: &mut Host, index: usize, value: bool) {
    match &mut host.vars[index].value {
        VarValue::Float(_) => panic!("Set variable wrong type"),
        VarValue::Bool(v) => *v = value,
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_delete_var(host: &mut Host, n: *const i8) {
    let cstr = CStr::from_ptr(n);
    let name = cstr.to_str().unwrap().to_string();

    host.vars.retain(| var | {
        var.name != name
    });
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_var_set_type(host: &mut Host, n: *const i8, kind: u32) {
    let cstr = CStr::from_ptr(n);
    let name = cstr.to_str().unwrap().to_string();

    for var in &mut host.vars {
        if var.name == name {
            println!("Updating type");
            var.value = match kind {
                0 => VarValue::Float(0.0),
                1 => VarValue::Bool(false),
                _ => panic!("Unsupported var type")
            }
        }
    }
}

#[repr(C)]
pub struct m_Connector {
    start_id: i32,
    start_index: i32,
    end_id: i32,
    end_index: i32,
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_add_connector(
    host: &mut Host,
    start_module: i32,
    start_index: i32,
    end_module: i32,
    end_index: i32,
) -> bool {
    host.graph.add_connector(Connector {
        start: Connection {
            module_id: start_module,
            pin_index: start_index,
        },
        end: Connection {
            module_id: end_module,
            pin_index: end_index,
        },
    })
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_remove_connector(host: &mut Host, id: i32, index: i32) {
    host.graph.remove_connector(id, index)
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_get_connector_count(host: &mut Host) -> usize {
    host.graph.connectors.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_get_connector_start_id(host: &mut Host, index: usize) -> i32 {
    host.graph.connectors[index].start.module_id
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_get_connector_end_id(host: &mut Host, index: usize) -> i32 {
    host.graph.connectors[index].end.module_id
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_get_connector_start_index(host: &mut Host, index: usize) -> i32 {
    host.graph.connectors[index].start.pin_index
}

#[no_mangle]
pub unsafe extern "C" fn ffi_host_get_connector_end_index(host: &mut Host, index: usize) -> i32 {
    host.graph.connectors[index].end.pin_index
}

/* Node */

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_id(node: &mut Node) -> i32 {
    node.id
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_x(node: &mut Node) -> i32 {
    node.position
        .lock()
        .expect("Couldn't get lock to get node x")
        .0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_y(node: &mut Node) -> i32 {
    node.position
        .lock()
        .expect("Couldn't get lock to get node y")
        .1
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_set_x(node: &mut Node, x: i32) {
    node.position
        .lock()
        .expect("Couldn't get lock to set node x")
        .0 = x;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_set_y(node: &mut Node, y: i32) {
    node.position
        .lock()
        .expect("Couldn't get lock to set node y")
        .1 = y;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_width(node: &mut Node) -> f32 {
    node.module.get_module_size().0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_height(node: &mut Node) -> f32 {
    node.module.get_module_size().1
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_set_width(node: &mut Node, width: f32) {
    let height = node.module.get_module_size().1;
    node.module.set_module_size((width, height));
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_set_height(node: &mut Node, height: f32) {
    let width = node.module.get_module_size().0;
    node.module.set_module_size((width, height));
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_min_width(node: &mut Node) -> i32 {
    match node.info().size {
        Size::Static(_w, _h) => panic!("Got min width on statically sized module"),
        Size::Reisizable { default: _, min, max: _ } => min.0 as i32,
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_min_height(node: &mut Node) -> i32 {
    match node.info().size {
        Size::Static(_w, _h) => panic!("Got min height on statically sized module"),
        Size::Reisizable { default: _, min, max: _ } => min.1 as i32,
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_max_width(node: &mut Node) -> i32 {
    match node.info().size {
        Size::Static(_w, _h) => panic!("Got max width on statically sized module"),
        Size::Reisizable { default: _, min: _, max } => max.0 as i32,
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_max_height(node: &mut Node) -> i32 {
    match node.info().size {
        Size::Static(_w, _h) => panic!("Got max height on statically sized module"),
        Size::Reisizable { default: _, min: _, max } => max.1 as i32,
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_resizable(node: &mut Node) -> bool {
    match node.info().size {
        Size::Static(_w, _h) => false,
        Size::Reisizable { default: _, min: _, max: _ } => true,
    }
}

/*#[no_mangle]
pub unsafe extern "C" fn ffi_node_change_parameter(node: &mut Node, name: *const c_char, value: f32) {
    let c_str: &CStr =  CStr::from_ptr(name);
    let str_slice: &str = c_str.to_str().unwrap();
    //HOST.graph.nodes[index].change_parameter(str_slice, value);
}*/

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_input_pins_count(node: &mut Node) -> usize {
    node.info().inputs.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_output_pins_count(node: &mut Node) -> usize {
    node.info().outputs.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_input_pin_type(node: &mut Node, pin_index: usize) -> i32 {
    match node.info().inputs[pin_index] {
        Pin::Audio(_x, _y) => 1,
        Pin::Notes(_x, _y) => 2,
        Pin::Control(_x, _y) => 3,
        Pin::Time(_x, _y) => 4,
        Pin::ExternalAudio(_) => 5,
        Pin::ExternalNotes(_) => 5,
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_output_pin_type(node: &mut Node, pin_index: usize) -> i32 {
    match node.info().outputs[pin_index] {
        Pin::Audio(_x, _y) => 1,
        Pin::Notes(_x, _y) => 2,
        Pin::Control(_x, _y) => 3,
        Pin::Time(_x, _y) => 4,
        Pin::ExternalAudio(_) => 5,
        Pin::ExternalNotes(_) => 5,
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_input_pin_name(
    node: &mut Node,
    pin_index: usize,
) -> *const i8 {
    let mut name = "";

    match node.info().inputs[pin_index] {
        Pin::Audio(x, _y) => name = x,
        Pin::Notes(x, _y) => name = x,
        Pin::Control(x, _y) => name = x,
        Pin::Time(x, _y) => name = x,
        Pin::ExternalAudio(_) => name = "External Audio Input",
        Pin::ExternalNotes(_) => name = "External Midi Input",
    };

    let s = CString::new(name).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_output_pin_name(
    node: &mut Node,
    pin_index: usize,
) -> *const i8 {
    let mut name = "";

    match node.info().outputs[pin_index] {
        Pin::Audio(x, _y) => name = x,
        Pin::Notes(x, _y) => name = x,
        Pin::Control(x, _y) => name = x,
        Pin::Time(x, _y) => name = x,
        Pin::ExternalAudio(_) => name = "External Audio Input",
        Pin::ExternalNotes(_) => name = "External Midi Input",
    };

    let s = CString::new(name).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_input_pin_y(node: &mut Node, pin_index: usize) -> i32 {
    match node.info().inputs[pin_index] {
        Pin::Audio(_x, y) => y,
        Pin::Notes(_x, y) => y,
        Pin::Control(_x, y) => y,
        Pin::Time(_x, y) => y,
        Pin::ExternalAudio(_) => panic!("Getting y for IO node"),
        Pin::ExternalNotes(_) => panic!("Getting y for IO node"),
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_output_pin_y(node: &mut Node, pin_index: usize) -> i32 {
    match node.info().outputs[pin_index] {
        Pin::Audio(_x, y) => y,
        Pin::Notes(_x, y) => y,
        Pin::Control(_x, y) => y,
        Pin::Time(_x, y) => y,
        Pin::ExternalAudio(_) => panic!("Getting y for IO node"),
        Pin::ExternalNotes(_) => panic!("Getting y for IO node"),
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_name(node: &mut Node) -> *const i8 {
    println!("Getting node name");
    let name = node.info().name;
    let s = CString::new(name).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_color(node: &mut Node) -> u32 {
    node.info().color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_widget_root(node: &mut Node) -> &dyn WidgetNew {
    node.module.get_module_root()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_ui_root(node: &mut Node) -> &dyn WidgetNew {
    match node.module.get_ui_root() {
        Some(widgets) => widgets,
        None => std::mem::transmute::<(i64, i64), &dyn WidgetNew>((0, 0)),
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_ui_x(node: &mut Node) -> f32 {
    node.module.get_ui_position().0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_ui_y(node: &mut Node) -> f32 {
    node.module.get_ui_position().1
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_set_ui_x(node: &mut Node, x: f32) {
    let y = node.module.get_ui_position().1;
    node.module.set_ui_position((x, y));
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_set_ui_y(node: &mut Node, y: f32) {
    let x = node.module.get_ui_position().0;
    node.module.set_ui_position((x, y));
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_ui_width(node: &mut Node) -> f32 {
    node.module.get_ui_size().0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_ui_height(node: &mut Node) -> f32 {
    node.module.get_ui_size().1
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_set_ui_width(node: &mut Node, x: f32) {
    let y = node.module.get_ui_size().1;
    node.module.set_ui_size((x, y));
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_set_ui_height(node: &mut Node, y: f32) {
    let x = node.module.get_ui_size().0;
    node.module.set_ui_size((x, y));
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_should_refresh(node: &mut Node) -> bool {
    node.module.should_refresh()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_should_rebuild(node: &mut Node) -> bool {
    node.module.should_rebuild()
}

/* Widget */

#[no_mangle]
pub unsafe extern "C" fn ffi_widget_get_trait(widget: &mut dyn WidgetNew) -> &dyn WidgetNew {
    widget.get_trait()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_widget_get_name(widget: &mut dyn WidgetNew) -> *const i8 {
    let name = widget.get_name();
    let s = CString::new(name).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_widget_get_child_count(widget: &mut dyn WidgetNew) -> usize {
    widget.get_children().len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_widget_get_child(
    widget: &mut dyn WidgetNew,
    index: usize,
) -> &dyn WidgetNew {
    widget.get_children().get(index).unwrap()
}
