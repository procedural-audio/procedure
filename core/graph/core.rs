pub mod host;
pub mod plugin;
pub mod plugins;
pub mod processor;
pub mod graph;

pub use crate::host::*;
pub use crate::plugin::*;
pub use crate::plugins::*;
pub use crate::processor::*;
pub use crate::graph::*;

use modules::*;

use std::ffi::CStr;
use std::ffi::CString;
use std::rc::Rc;

static VERSION: &str = "0.1.0";

pub struct Player {
    // pub graph: Option<Box<Graph>>,
    // pub sample_rate: u32,
    // pub block_size: usize,
    // pub time: TimeMessage,
    // pub bpm: f64,
}

impl Player {
    pub fn new() -> Self {
        Self {}
    }
}

pub struct ModuleInfo {
    program: cmajor_rs::Program
}

impl ModuleInfo {
    pub fn load(path: &str) -> Self {
        let contents = std::fs::read_to_string(path).unwrap();
        todo!();
    }
}

/*
#[repr(C)]
pub struct CoreApi {
    get_version: unsafe extern "C" fn() -> *const i8,
    core_create: unsafe extern "C" fn() -> *mut Core,
    core_destroy: unsafe extern "C" fn(*mut Core),
    module_info_load: unsafe extern "C" fn(*const i8) -> *mut ModuleInfo,
    module_info_get: unsafe extern "C" fn(*mut ModuleInfo) -> *const i8,
    module_info_destroy: unsafe extern "C" fn(*mut ModuleInfo),
}

#[no_mangle]
pub unsafe extern "C" fn get_api() -> CoreApi {
    return CoreApi {
        get_version,
        core_create,
        core_destroy,
        module_info_load,
        module_info_get,
        module_info_destroy,
    };
}

unsafe extern "C" fn get_version() -> *const i8 {
    let s = CString::new(VERSION).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

unsafe extern "C" fn core_create() -> *mut Core {
    Box::into_raw(Box::new(Core::new()))
}

unsafe extern "C" fn core_destroy(core: *mut Core) {
    drop(Box::from_raw(core));
}

unsafe extern "C" fn module_info_load(path: *const i8) -> *mut ModuleInfo {
    let path = str_from_char(&*path);
    let module = ModuleInfo::load(path);
    Box::into_raw(Box::new(module))
}

unsafe extern "C" fn module_info_get(module: *mut ModuleInfo) -> *const i8 {
    todo!()
}

unsafe extern "C" fn module_info_destroy(module: *mut ModuleInfo) {
    drop(Box::from_raw(module));
}

// OLD FUNCTIONS BELOW

#[no_mangle]
pub unsafe fn ffi_hack_convert(data: usize) -> usize {
    data
}

#[no_mangle]
pub extern "C" fn api_io_test() {}

#[no_mangle]
pub unsafe extern "C" fn ffi_create_host() -> *mut Host {
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

fn str_from_char(buffer: &i8) -> &str {
    unsafe {
        let c_str: &CStr = CStr::from_ptr(buffer);
        c_str.to_str().unwrap()
    }
}

/*#[no_mangle]
pub unsafe fn ffi_dispatch(buffer: &[u8]) -> u32 {
    println!("Recieving message");
    match Message::decode(buffer) {
        Ok(msg) => {
            let msg: CoreMsg = msg;

            use core_msg::Kind;

            if let Some(kind) = msg.kind {
                match kind {
                    Kind::Patch(msg) => patch_message(msg),
                    Kind::Module(msg) => module_message(msg),
                    Kind::Widget(msg) => widget_message(msg),
                }
            }
        },
        Err(e) => println!("{}", e)
    }

    return 0;
}

pub fn patch_message(msg: PatchMsg) {
    use patch_msg::Cmd;

    if let Some(cmd) = msg.cmd {
        match cmd {
            Cmd::Add(cmd) => {},
            Cmd::Remove(cmd) => {},
        }
    }
}

pub fn module_message(msg: ModuleMsg) {

}

pub fn widget_message(msg: WidgetMsg) {

}*/

/* Replace everything below here */

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
pub unsafe extern "C" fn ffi_host_process(
    host: &mut Host,
    buffer: *mut *mut f32,
    num_channels: u32,
    num_samples: u32,
    events: *mut NoteMessage,
    events_count: u32,
) {
    let mut events = Buffer::from_raw_parts(events, events_count as usize, events_count as usize);

    if num_channels == 0 {
        println!("No IO channels available");
    } else if num_channels == 1 {
        let buffer_center = Buffer::from_raw_parts(*buffer.offset(0), num_samples as usize, num_samples as usize);

        let mut audio = [buffer_center];

        api_host_process(host, &mut audio, &mut events);

        std::mem::forget(audio);
    } else if num_channels == 2 {
        let buffer_left = Buffer::from_raw_parts(*buffer.offset(0), num_samples as usize, num_samples as usize);
        let buffer_right = Buffer::from_raw_parts(*buffer.offset(1), num_samples as usize, num_samples as usize);

        let mut audio = [buffer_left, buffer_right];

        api_host_process(host, &mut audio, &mut events);

        std::mem::forget(audio);
    } else {
        println!("Unsupported channel number");
    }

    std::mem::forget(events);
}

#[no_mangle]
pub unsafe extern "C" fn api_host_process(
    host: &mut Host,
    audio: &mut [Buffer<f32>],
    events: &mut Buffer<NoteMessage>,
) {
    for buffer in audio.iter_mut() {
        for sample in buffer {
            *sample = 0.0;
        }
    }

    host.process(audio, events);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_core_set_patch(host: &mut Host, patch: *mut Graph) {
    if patch != std::ptr::null_mut() {
        let mut patch = Box::from_raw(patch);
        patch.prepare(host.sample_rate, host.block_size);
        host.graph = Some(patch);
    } else {
        host.graph = None;
    }
}

/* Host Graph */

#[no_mangle]
pub unsafe extern "C" fn ffi_host_refresh(host: &mut Host) {
    if let Some(graph) = &mut host.graph {
        graph.refresh();
    }
}

/* Patch */

#[no_mangle]
pub unsafe extern "C" fn ffi_create_patch() -> *mut Graph {
    Box::into_raw(Box::new(Graph::new()))
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_load(graph: &mut Graph, plugins: &'static Plugins, path: &i8) -> bool {
    let path = str_from_char(path);
    let data = std::fs::read_to_string(path).unwrap();

    println!("Loading patch from {}", path);
    println!("{}", data);

    PLUGINS = Some(plugins);

    match serde_json::from_str(&data) {
        Ok(new_graph) => {
            let mut new_graph: Graph = new_graph;
            new_graph.refresh();
            *graph = new_graph;
            return true;
        },
        Err(e) => {
            graph.nodes.clear();
            graph.refresh();
            println!("Failed to decode graph {}", e);
            return false;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_save(graph: &Graph, path: &i8) -> bool {
    let path = str_from_char(path);
    let path = path.to_string();
    let json = serde_json::to_string(&graph).unwrap();
    println!("Saving graph");
    // println!("{}", json);
    std::fs::write(path.clone(), &json).unwrap();
    return true;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_get_state(graph: &Graph) -> *mut String {
    return Box::into_raw(Box::new(serde_json::to_string(&graph).unwrap()))
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_set_state(graph: &mut Graph, plugins: &'static Plugins, state: *mut String) {
    let state = Box::from_raw(state);

    println!("Setting state");
    println!("{}", &*state);

    PLUGINS = Some(plugins);

    match serde_json::from_str(&*state) {
        Ok(new_graph) => {
            let mut new_graph: Graph = new_graph;
            new_graph.refresh();
            *graph = new_graph;
        },
        Err(e) => {
            graph.nodes.clear();
            graph.refresh();
            println!("Failed to decode graph {}", e);
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_destroy(graph: *mut Graph) {
    let _ = Box::from_raw(graph);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_add_module(graph: &mut Graph, plugins: &Plugins, id: &i8) -> *const Node {
    let id = str_from_char(id);

    match graph.add_module(plugins, id) {
        Some(node) => Rc::into_raw(node),
        None => std::ptr::null()
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_remove_node(patch: &mut Graph, id: i32) -> bool {
    patch.remove_module(id);
    println!("Skipped check if remove suceeded");
    true
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_get_node_count(patch: &mut Graph) -> usize {
    patch.nodes.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_get_node(patch: &mut Graph, index: usize) -> &Node {
    patch.nodes[index].as_ref()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_get_connector_count(patch: &mut Graph) -> usize {
    patch.connectors.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_get_connector(patch: &mut Graph, index: usize) -> Connector {
    patch.connectors[index]
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_add_connector(patch: &mut Graph, start_id: i32, start_index: i32, end_id: i32, end_index: i32) -> bool {
    return patch.add_connector(
        Connector {
            start: Connection {
                module_id: start_id,
                pin_index: start_index,
            },
            end: Connection {
                module_id: end_id,
                pin_index: end_index,
            },
        }
    );
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_remove_connector(patch: &mut Graph, module_id: i32, pin_index: i32) {
    patch.remove_connector(module_id, pin_index);
}

/* Node */

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_id(node: &mut Node) -> i32 {
    node.id
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_x(node: &mut Node) -> f64 {
    node.position.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_y(node: &mut Node) -> f64 {
    node.position.1
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_set_x(node: &mut Node, x: f64) {
    node.position.0 = x;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_set_y(node: &mut Node, y: f64) {
    node.position.1 = y;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_width(node: &mut Node, patch: &Graph) -> f32 {
    match node.info().size {
        Size::Static(w, h) => w as f32,
        Size::Reisizable { default, min, max } => node.module.get_module_size().0,
        Size::Dynamic(f) => {
            let mut inputs = Vec::new();
            for _ in 0..node.info().inputs.len() {
                inputs.push(false);
            }

            let mut outputs = Vec::new();
            for _ in 0..node.info().outputs.len() {
                outputs.push(false);
            }

            for connector in &patch.connectors {
                if connector.start.module_id == node.id {
                    outputs[connector.start.pin_index as usize - inputs.len()] = true;
                }

                if connector.end.module_id == node.id {
                    inputs[connector.end.pin_index as usize] = true;
                }
            }

            f(&inputs, &outputs).0 as f32
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_height(node: &mut Node, patch: &Graph) -> f32 {
    match node.info().size {
        Size::Static(w, h) => h as f32,
        Size::Reisizable { default, min, max } => node.module.get_module_size().1,
        Size::Dynamic(f) => {
            let mut inputs = Vec::new();
            for _ in 0..node.info().inputs.len() {
                inputs.push(false);
            }

            let mut outputs = Vec::new();
            for _ in 0..node.info().outputs.len() {
                outputs.push(false);
            }

            for connector in &patch.connectors {
                if connector.start.module_id == node.id {
                    outputs[connector.start.pin_index as usize - inputs.len()] = true;
                }

                if connector.end.module_id == node.id {
                    inputs[connector.end.pin_index as usize] = true;
                }
            }

            f(&inputs, &outputs).1 as f32
        }
    }
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
        Size::Dynamic(f) => f(&[], &[]).0 as i32,
        Size::Dynamic(_) => panic!("Got min width on dynamic module"),
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_min_height(node: &mut Node) -> i32 {
    match node.info().size {
        Size::Static(_w, _h) => panic!("Got min height on statically sized module"),
        Size::Reisizable { default: _, min, max: _ } => min.1 as i32,
        Size::Dynamic(_) => panic!("Got min height on dynamic module"),
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_max_width(node: &mut Node) -> i32 {
    match node.info().size {
        Size::Static(_w, _h) => panic!("Got max width on statically sized module"),
        Size::Reisizable { default: _, min: _, max } => max.0 as i32,
        Size::Dynamic(_) => panic!("Got max width on dynamic module"),
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_max_height(node: &mut Node) -> i32 {
    match node.info().size {
        Size::Static(_w, _h) => panic!("Got max height on statically sized module"),
        Size::Reisizable { default: _, min: _, max } => max.1 as i32,
        Size::Dynamic(_) => panic!("Got max height on dynamic module"),
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_resizable(node: &mut Node) -> bool {
    match node.info().size {
        Size::Static(_w, _h) => false,
        Size::Reisizable { default: _, min: _, max: _ } => true,
        Size::Dynamic(_) => unimplemented!(),
    }
}

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
        Pin::ExternalAudio(_) => 0,
        Pin::ExternalNotes(_) => 0,
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_output_pin_y(node: &mut Node, pin_index: usize) -> i32 {
    match node.info().outputs[pin_index] {
        Pin::Audio(_x, y) => y,
        Pin::Notes(_x, y) => y,
        Pin::Control(_x, y) => y,
        Pin::Time(_x, y) => y,
        Pin::ExternalAudio(_) => 0,
        Pin::ExternalNotes(_) => 0,
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_node_get_name(node: &mut Node) -> *const i8 {
    println!("Getting node name");
    let name = node.info().title;
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

#[no_mangle]
pub unsafe extern "C" fn ffi_plugin_get_name(plugin: &Plugin) -> *const i8 {
    let name = plugin.name;
    let s = CString::new(name).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_plugin_get_version(plugin: &Plugin) -> u64 {
    plugin.version
}

#[no_mangle]
pub unsafe extern "C" fn ffi_plugin_get_module_info_count(plugin: &Plugin) -> usize {
    plugin.modules.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_plugin_get_module_info(plugin: &Plugin, index: usize) -> *const ModuleSpec {
    &plugin.modules[index]
}

#[no_mangle]
pub unsafe extern "C" fn ffi_module_info_get_id(info: &ModuleSpec) -> *const i8 {
    let name = info.id;
    let s = CString::new(name).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_module_info_get_name(info: &ModuleSpec) -> *const i8 {
    let name = info.name;
    let s = CString::new(name).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_module_info_get_path_elements_count(info: &ModuleSpec) -> usize {
    info.path.len()
}

#[no_mangle]
pub unsafe extern "C" fn ffi_module_info_get_path_element(info: &ModuleSpec, index: usize) -> *const i8 {
    let name = info.path[index];
    let s = CString::new(name).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_module_info_get_color(info: &ModuleSpec) -> Color {
    info.color
}

#[no_mangle]
pub unsafe extern "C" fn ffi_module_info_destroy(info: &ModuleSpec) {
    let _ = Box::from_raw(info as *const ModuleSpec as *mut ModuleSpec);
}

/* Plugins */

#[no_mangle]
pub unsafe extern "C" fn ffi_create_plugins() -> *mut Plugins {
    Box::into_raw(Box::new(Plugins::new()))
}

#[no_mangle]
pub unsafe extern "C" fn ffi_plugins_load(plugins: &mut Plugins, path: &i8) -> *const Plugin {
    let path = str_from_char(path);
    match plugins.load(path) {
        Some(plugin) => plugin as *const Plugin,
        None => std::ptr::null_mut()
    }
}

#[no_mangle]
pub unsafe extern "C" fn ffi_plugins_unload(plugins: &mut Plugins, path: &i8) {
    let path = str_from_char(path);
    plugins.unload(path);
}
*/