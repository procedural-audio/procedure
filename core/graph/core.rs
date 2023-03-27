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

use nodio::AudioPlugin;

use modules::*;

use std::ffi::CStr;
use std::ffi::CString;

/* Begin main */

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
pub unsafe extern "C" fn ffi_host_process(
    host: &mut Host,
    buffer: *mut *mut f32,
    num_channels: u32,
    num_samples: u32,
    events: *mut NoteMessage,
    events_count: u32,
) {
    let mut events = NoteBuffer::from_raw_parts(events, events_count as usize, events_count as usize);

    if num_channels == 0 {
        println!("No IO channels available");
    } else if num_channels == 1 {
        let buffer_center = AudioBuffer::from_raw_parts(*buffer.offset(0), num_samples as usize, num_samples as usize);

        let mut audio = [buffer_center];

        api_host_process(host, &mut audio, &mut events);

        std::mem::forget(audio);
    } else if num_channels == 2 {
        let buffer_left = AudioBuffer::from_raw_parts(*buffer.offset(0), num_samples as usize, num_samples as usize);
        let buffer_right = AudioBuffer::from_raw_parts(*buffer.offset(1), num_samples as usize, num_samples as usize);

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
    audio: &mut [AudioBuffer],
    events: &mut NoteBuffer,
) {
    for buffer in audio.iter_mut() {
        for sample in buffer {
            *sample = 0.0;
        }
    }

    host.process(audio, events);
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
pub unsafe extern "C" fn ffi_host_create_plugin(host: &mut Host, buffer: &i8) -> AudioPlugin {
    match host.plugin_manager.create_plugin(str_from_char(buffer)) {
        Some(plugin) => plugin,
        None => panic!("Failed to create plugin")
    }
}

/* Some other stuff */

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

/* Patch */

#[no_mangle]
pub unsafe extern "C" fn ffi_create_patch() -> *mut Graph {
    Box::into_raw(Box::new(Graph::new()))
}

#[no_mangle]
pub unsafe extern "C" fn ffi_patch_load(graph: &mut Graph, path: &i8) {
    let path = str_from_char(path);
    let data = std::fs::read_to_string(path).unwrap();

    println!("Loading patch from {}", path);
    println!("{}", data);

    match serde_json::from_str(&data) {
        Ok(new_graph) => {
            let mut new_graph: Graph = new_graph;
            new_graph.refresh();

            new_graph.refresh();
            *graph = new_graph;
        }
        Err(e) => {
            graph.nodes.clear();
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
pub unsafe extern "C" fn ffi_patch_add_module(graph: &mut Graph, module: *mut dyn PolyphonicModule) -> *const Node {
    let node = graph.add_module2(Box::from_raw(module));
    return node.as_ref() as *const Node;
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
pub unsafe extern "C" fn ffi_patch_get_add_node(patch: &mut Graph, module: *mut dyn PolyphonicModule) {
    patch.add_module2(Box::from_raw(module));
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
pub unsafe extern "C" fn ffi_module_info_create(info: &ModuleSpec) -> *const dyn PolyphonicModule {
    Box::into_raw(info.create())
}

#[no_mangle]
pub unsafe extern "C" fn ffi_module_info_destroy(info: &ModuleSpec) {
    let _ = Box::from_raw(info as *const ModuleSpec as *mut ModuleSpec);
}
