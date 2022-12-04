use std::mem::transmute_copy;
use std::mem::ManuallyDrop;

use pa_dsp::buffers::IO;

use std::rc::Rc;

use crate::graph::*;
use crate::*;

type Ptr<T> = ManuallyDrop<Box<T>>;

enum CopyAction<T> {
    AudioCopy {
        // src: Ptr<T>,
        // dest: Ptr<T>,
        src: Ptr<Bus<T>>,
        dest: Ptr<Bus<T>>,
        src_index: usize,
        dest_index: usize,
        should_copy: bool,
    },
    NotesCopy {
        src: Ptr<Bus<NoteBuffer>>,
        dest: Ptr<Bus<NoteBuffer>>,
        src_index: usize,
        dest_index: usize,
        should_copy: bool,
    },
    ControlCopy {
        src: Ptr<Bus<Box<f32>>>,
        dest: Ptr<Bus<Box<f32>>>,
        src_index: usize,
        dest_index: usize,
        should_copy: bool,
    },
    TimeCopy {
        src: Ptr<Bus<Box<Time>>>,
        dest: Ptr<Bus<Box<Time>>>,
        src_index: usize,
        dest_index: usize,
        should_copy: bool,
    },
}

impl<T> Clone for CopyAction<T> {
    fn clone(&self) -> Self {
        unsafe { transmute_copy(self) }
    }
}

pub struct ProcessAction {
    id: i32,
    module: *mut dyn PolyphonicModule,
    voice_index: usize,
    node: Rc<Node>,
    audio_inputs: Ptr<Bus<Stereo>>,
    audio_outputs: Ptr<Bus<Stereo>>,
    events_inputs: Ptr<Bus<NoteBuffer>>,
    events_outputs: Ptr<Bus<NoteBuffer>>,
    control_inputs: Ptr<Bus<Box<f32>>>,
    control_outputs: Ptr<Bus<Box<f32>>>,
    time_inputs: Ptr<Bus<Box<Time>>>,
    time_outputs: Ptr<Bus<Box<Time>>>,
    copy_actions: Vec<CopyAction<Stereo>>,
}

impl Clone for ProcessAction {
    fn clone(&self) -> Self {
        unsafe {
            Self {
                id: self.id.clone(),
                module: self.module.clone(),
                voice_index: self.voice_index.clone(),
                node: self.node.clone(),
                audio_inputs: transmute_copy(&self.audio_inputs),
                audio_outputs: transmute_copy(&self.audio_outputs),
                events_inputs: transmute_copy(&self.events_inputs),
                events_outputs: transmute_copy(&self.events_outputs),
                control_inputs: transmute_copy(&self.control_inputs),
                control_outputs: transmute_copy(&self.control_outputs),
                time_inputs: transmute_copy(&self.time_inputs),
                time_outputs: transmute_copy(&self.time_outputs),
                copy_actions: self.copy_actions.clone(),
            }
        }
    }
}

pub struct GraphProcessor {
    pub actions: Vec<ProcessAction>,

    pub audio_buffers: Vec<Box<Bus<Stereo>>>,
    pub events_buffers: Vec<Box<Bus<NoteBuffer>>>,
    pub control_buffers: Vec<Box<Bus<Box<f32>>>>,
    pub time_buffers: Vec<Box<Bus<Box<Time>>>>,

    pub nodes: Vec<Rc<Node>>,
    pub block_size: usize,
    pub processed: u32,
    pub voice_count: usize,
}

impl Default for GraphProcessor {
    fn default() -> Self {
        GraphProcessor {
            actions: Vec::new(),
            audio_buffers: Vec::new(),
            events_buffers: Vec::new(),
            control_buffers: Vec::new(),
            time_buffers: Vec::new(),
            nodes: Vec::new(),
            block_size: 128,
            processed: 0,
            voice_count: 16,
        }
    }
}

impl GraphProcessor {
    pub fn new(
        nodes: &Vec<Rc<Node>>,
        connectors: &Vec<Connector>,
        block_size: usize,
        sample_rate: u32,
    ) -> Self {
        let voice_count = 8;

        println!("Creating graph processor {} {}", sample_rate, block_size);

        let nodes = GraphProcessor::sorted_nodes(nodes, connectors);

        println!("\nProcess order is:");
        for node in nodes.iter() {
            println!(" > Node {}", node.id);
        }

        println!("Connections are:");
        for c in connectors.iter() {
            println!(
                " > {} {} -> {} {}",
                c.start.module_id, c.start.pin_index, c.end.module_id, c.end.pin_index
            );
        }

        let mut audio_channels_buffers: Vec<Box<Bus<Stereo>>> = Vec::new();
        let mut events_channels_buffers: Vec<Box<Bus<NoteBuffer>>> = Vec::new();
        let mut control_channels_buffers: Vec<Box<Bus<Box<f32>>>> = Vec::new();
        let mut time_channels_buffers: Vec<Box<Bus<Box<Time>>>> = Vec::new();
        let mut process_actions: Vec<ProcessAction> = Vec::new();

        /* Allocate channel buffers */

        println!("Allocating channel buffers");

        for node in nodes.iter() {
            let mut audio_input_channels_count = 0;
            let mut events_input_channels_count = 0;
            let mut control_input_channels_count = 0;
            let mut time_input_channels_count = 0;

            for input in node.info().inputs {
                match input {
                    Pin::Audio(_, _) => audio_input_channels_count += 1,
                    Pin::Notes(_, _) => events_input_channels_count += 1,
                    Pin::Control(_, _) => control_input_channels_count += 1,
                    Pin::Time(_, _) => time_input_channels_count += 1,
                    Pin::ExternalAudio(_) => audio_input_channels_count += 1,
                    Pin::ExternalNotes(_) => events_input_channels_count += 1,
                }
            }

            let mut audio_output_channels_count = 0;
            let mut events_output_channels_count = 0;
            let mut control_output_channels_count = 0;
            let mut time_output_channels_count = 0;

            for output in node.info().outputs {
                match output {
                    Pin::Audio(_, _) => audio_output_channels_count += 1,
                    Pin::Notes(_, _) => events_output_channels_count += 1,
                    Pin::Control(_, _) => control_output_channels_count += 1,
                    Pin::Time(_, _) => time_output_channels_count += 1,
                    Pin::ExternalAudio(_) => audio_output_channels_count += 1,
                    Pin::ExternalNotes(_) => events_output_channels_count += 1,
                }
            }

            let node_voice_count = match node.info().voicing {
                Voicing::Monophonic => 1,
                Voicing::Polyphonic => voice_count,
                _ => panic!("Need to update this"),
            };

            for voice_index in 0..node_voice_count {
                let mut audio_input_bus = Box::new(Bus::new());
                for i in 0..audio_input_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.end.module_id == node.id && conn.end.pin_index == i {
                            connected = true;
                        }
                    });

                    audio_input_bus.add_channel(Channel::new(Stereo::init(0.0, block_size), connected));
                }

                let mut audio_output_bus = Box::new(Bus::new());
                for i in 0..audio_output_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.start.module_id == node.id && conn.start.pin_index == i {
                            connected = true;
                        }
                    });

                    audio_output_bus.add_channel(Channel::new(Stereo::init(0.0, block_size), connected));
                }

                let mut events_input_bus = Box::new(Bus::new());
                for i in 0..events_input_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.end.module_id == node.id && conn.end.pin_index == i {
                            connected = true;
                        }
                    });

                    events_input_bus.add_channel(Channel::new(NoteBuffer::with_capacity(64), connected));
                }

                let mut events_output_bus = Box::new(Bus::new());
                for i in 0..events_output_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.start.module_id == node.id && conn.start.pin_index == i {
                            connected = true;
                        }
                    });

                    events_output_bus.add_channel(Channel::new(NoteBuffer::with_capacity(64), connected));
                }

                let mut control_input_bus = Box::new(Bus::new());
                for i in 0..control_input_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.end.module_id == node.id && conn.end.pin_index == i {
                            connected = true;
                        }
                    });

                    control_input_bus.add_channel(Channel::new(Box::new(0.0), connected));
                }

                let mut control_output_bus = Box::new(Bus::new());
                for i in 0..control_output_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.start.module_id == node.id && conn.start.pin_index == i {
                            connected = true;
                        }
                    });

                    control_output_bus.add_channel(Channel::new(Box::new(0.0), connected));
                }

                let mut time_input_bus = Box::new(Bus::new());
                for i in 0..time_input_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.end.module_id == node.id && conn.end.pin_index == i {
                            connected = true;
                        }
                    });

                    time_input_bus.add_channel(Channel::new(Box::new(Time::from(0.0, 0.0)), connected));
                }

                let mut time_output_bus = Box::new(Bus::new());
                for i in 0..time_output_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.start.module_id == node.id && conn.start.pin_index == i {
                            connected = true;
                        }
                    });

                    time_output_bus.add_channel(Channel::new(Box::new(Time::from(0.0, 0.0)), connected));
                }

                unsafe {
                    let node_ptr = Rc::as_ptr(node) as *mut Node;
                    let module_ptr: *mut dyn PolyphonicModule = &mut *(*node_ptr).module;

                    let action = ProcessAction {
                        id: node.id,
                        module: module_ptr,
                        voice_index,
                        node: node.clone(),
                        audio_inputs: transmute_copy(&audio_input_bus),
                        audio_outputs: transmute_copy(&audio_output_bus),
                        events_inputs: transmute_copy(&events_input_bus),
                        events_outputs: transmute_copy(&events_output_bus),
                        control_inputs: transmute_copy(&control_input_bus),
                        control_outputs: transmute_copy(&control_output_bus),
                        time_inputs: transmute_copy(&time_input_bus),
                        time_outputs: transmute_copy(&time_output_bus),
                        copy_actions: Vec::new(),
                    };

                    audio_channels_buffers.push(audio_input_bus);
                    audio_channels_buffers.push(audio_output_bus);

                    events_channels_buffers.push(events_input_bus);
                    events_channels_buffers.push(events_output_bus);

                    control_channels_buffers.push(control_input_bus);
                    control_channels_buffers.push(control_output_bus);

                    time_channels_buffers.push(time_input_bus);
                    time_channels_buffers.push(time_output_bus);

                    process_actions.push(action);
                }
            }
        }

        /* Push copy actions */

        let mut dest_audio_buffers_used = Vec::new();
        let mut dest_events_buffers_used = Vec::new();
        let mut dest_control_buffers_used = Vec::new();
        let mut dest_time_buffers_used = Vec::new();

        let mut process_actions_final: Vec<ProcessAction> = Vec::new();

        /*fn helper_channel<T>(process_actions: &Vec<ProcessAction>, action1: &ProcessAction, new_action: &mut ProcessAction, connector: &Connector, dest_buffers_used: &mut Vec<(i32, usize, usize)>) {
            let index1 = GraphProcessor::get_node_channel(
                action1.node.clone(),
                connector.start.pin_index,
            ) as usize;

            let source1 = action1.audio_outputs.channel(index1);

            for action2 in process_actions.iter() {
                if connector.end.module_id == action2.id
                    && (action2.voice_index == action1.voice_index
                        || action1.node.info().voicing == Voicing::Monophonic
                        || action2.node.info().voicing == Voicing::Monophonic)
                {
                    let index2 = GraphProcessor::get_node_channel(action2.node.clone(), connector.end.pin_index) as usize;

                    let dest1 = action2.audio_inputs.channel(index2);

                    let dest_id = action2.node.id;
                    let dest_voice_index = action2.voice_index;
                    let dest_index1 = index2;

                    let dest_used1 = dest_buffers_used.contains(&(dest_id, dest_index1, dest_voice_index));

                    if !dest_used1 {
                        dest_buffers_used.push((dest_id, dest_index1, dest_voice_index));
                    }

                    unsafe {
                        new_action.copy_actions.push(CopyAction::AudioCopy {
                            src: transmute_copy(source1),
                            dest: transmute_copy(dest1),
                            should_copy: !dest_used1,
                        });
                    }
                }
            }
        }

        fn process_stuff(nodes: &Vec<Rc<Node>>, actions: &Vec<ProcessAction>, connectors: &Vec<Connector>, dest_buffers_used: &mut Vec<(i32, usize, usize)>) {
            for action1 in actions.iter() {
                let mut new_action: ProcessAction = action1.clone();

                for connector in connectors.iter() {
                    if connector.start.module_id == action1.id {
                        match GraphProcessor::get_connector_type(&nodes, connector) {
                            Pin::Audio(_, _) => {
                                helper_channel::<Stereo>(actions, action1, &mut new_action, connector, dest_buffers_used);
                            }
                            _ => ()
                        }
                    }
                }
            }
        }*/

        for action1 in process_actions.iter() {
            let mut new_action: ProcessAction = action1.clone();

            for connector in connectors.iter() {
                if connector.start.module_id == action1.id {
                    match GraphProcessor::get_connector_type(&nodes, connector) {
                        // Audio copy actions
                        Pin::Audio(_a, _b) => {
                            // Find start buffer
                            let index1 = GraphProcessor::get_node_channel(
                                action1.node.clone(),
                                connector.start.pin_index,
                            ) as usize;

                            let source1 = action1.audio_outputs.channel(index1);

                            for action2 in process_actions.iter() {
                                if connector.end.module_id == action2.id
                                    && (action2.voice_index == action1.voice_index
                                        || action1.node.info().voicing == Voicing::Monophonic
                                        || action2.node.info().voicing == Voicing::Monophonic)
                                {
                                    let index2 = GraphProcessor::get_node_channel(
                                        action2.node.clone(),
                                        connector.end.pin_index,
                                    ) as usize;

                                    let dest1 = action2.audio_inputs.channel(index2);

                                    let dest_id = action2.node.id;
                                    let dest_voice_index = action2.voice_index;
                                    let dest_index1 = index2;

                                    let dest_used1 = dest_audio_buffers_used.contains(&(
                                        dest_id,
                                        dest_index1,
                                        dest_voice_index,
                                    ));

                                    if !dest_used1 {
                                        dest_audio_buffers_used.push((
                                            dest_id,
                                            dest_index1,
                                            dest_voice_index,
                                        ));
                                    }

                                    unsafe {
                                        new_action.copy_actions.push(CopyAction::AudioCopy {
                                            src: transmute_copy(&action1.audio_outputs),
                                            dest: transmute_copy(&action2.audio_inputs),
                                            src_index: index1,
                                            dest_index: index2,
                                            should_copy: !dest_used1,
                                        });
                                    }
                                }
                            }
                        }

                        // Notes copy actions
                        Pin::Notes(_a, _b) => {
                            // Find start buffer
                            let index1 = GraphProcessor::get_node_channel(
                                action1.node.clone(),
                                connector.start.pin_index,
                            ) as usize;

                            let source1 = action1.events_outputs.channel(index1);

                            for action2 in process_actions.iter() {
                                if connector.end.module_id == action2.id
                                    && (action2.voice_index == action1.voice_index
                                        || action1.node.info().voicing == Voicing::Monophonic
                                        || action2.node.info().voicing == Voicing::Monophonic)
                                {
                                    let index2 = GraphProcessor::get_node_channel(
                                        action2.node.clone(),
                                        connector.end.pin_index,
                                    ) as usize;

                                    let dest1 = action2.events_inputs.channel(index2);

                                    let dest_id = action2.node.id;
                                    let dest_voice_index = action2.voice_index;
                                    let dest_index1 = index2;

                                    let dest_used1 = dest_events_buffers_used.contains(&(
                                        dest_id,
                                        dest_index1,
                                        dest_voice_index,
                                    ));

                                    if !dest_used1 {
                                        dest_events_buffers_used.push((
                                            dest_id,
                                            dest_index1,
                                            dest_voice_index,
                                        ));
                                    }

                                    unsafe {
                                        new_action.copy_actions.push(CopyAction::NotesCopy {
                                            src: transmute_copy(&action1.events_outputs),
                                            dest: transmute_copy(&action2.events_inputs),
                                            src_index: index1,
                                            dest_index: index2,
                                            should_copy: !dest_used1,
                                        });
                                    }
                                }
                            }
                        }

                        // Control copy actions
                        Pin::Control(_a, _b) => {
                            let index1 = GraphProcessor::get_node_channel(
                                action1.node.clone(),
                                connector.start.pin_index,
                            ) as usize;

                            let source1 = action1.control_outputs.channel(index1);

                            for action2 in process_actions.iter() {
                                if connector.end.module_id == action2.id
                                    && (action2.voice_index == action1.voice_index
                                        || action1.node.info().voicing == Voicing::Monophonic
                                        || action2.node.info().voicing == Voicing::Monophonic)
                                {
                                    let index2 = GraphProcessor::get_node_channel(
                                        action2.node.clone(),
                                        connector.end.pin_index,
                                    ) as usize;

                                    let dest1 = action2.control_inputs.channel(index2);

                                    let dest_id = action2.node.id;
                                    let dest_voice_index = action2.voice_index;
                                    let dest_index1 = index2;

                                    let dest_used1 = dest_control_buffers_used.contains(&(
                                        dest_id,
                                        dest_index1,
                                        dest_voice_index,
                                    ));

                                    if !dest_used1 {
                                        dest_control_buffers_used.push((
                                            dest_id,
                                            dest_index1,
                                            dest_voice_index,
                                        ));
                                    }

                                    unsafe {
                                        new_action.copy_actions.push(CopyAction::ControlCopy {
                                            src: transmute_copy(&action1.control_outputs),
                                            dest: transmute_copy(&action2.control_inputs),
                                            src_index: index1,
                                            dest_index: index2,
                                            should_copy: !dest_used1,
                                        });
                                    }
                                }
                            }
                        }

                        // Time copy actions
                        Pin::Time(_a, _b) => {
                            let index1 = GraphProcessor::get_node_channel(
                                action1.node.clone(),
                                connector.start.pin_index,
                            ) as usize;

                            let source1 = action1.time_outputs.channel(index1);

                            for action2 in process_actions.iter() {
                                if connector.end.module_id == action2.id
                                    && (action2.voice_index == action1.voice_index
                                        || action1.node.info().voicing == Voicing::Monophonic
                                        || action2.node.info().voicing == Voicing::Monophonic)
                                {
                                    let index2 = GraphProcessor::get_node_channel(
                                        action2.node.clone(),
                                        connector.end.pin_index,
                                    ) as usize;

                                    let dest1 = action2.time_inputs.channel(index2);

                                    let dest_id = action2.node.id;
                                    let dest_voice_index = action2.voice_index;
                                    let dest_index1 = index2;

                                    let dest_used1 = dest_time_buffers_used.contains(&(
                                        dest_id,
                                        dest_index1,
                                        dest_voice_index,
                                    ));

                                    if !dest_used1 {
                                        dest_time_buffers_used.push((
                                            dest_id,
                                            dest_index1,
                                            dest_voice_index,
                                        ));
                                    }

                                    unsafe {
                                        new_action.copy_actions.push(CopyAction::TimeCopy {
                                            src: transmute_copy(&action1.time_outputs),
                                            dest: transmute_copy(&action2.time_inputs),
                                            src_index: index1,
                                            dest_index: index2,
                                            should_copy: !dest_used1,
                                        });
                                    }
                                }
                            }
                        },
                        _ => ()
                    }
                }
            }

            process_actions_final.push(new_action.clone());
        }

        // TODO: Use actions variable to make multithreaded

        return GraphProcessor {
            actions: process_actions_final,

            audio_buffers: audio_channels_buffers,
            events_buffers: events_channels_buffers,
            control_buffers: control_channels_buffers,
            time_buffers: time_channels_buffers,

            nodes,
            block_size,
            processed: 0,
            voice_count,
        };
    }

    pub fn process(
        &mut self,
        time: &Time,
        audio: &mut [AudioBuffer],
        events: &mut NoteBuffer,
    ) {
        /* Zero all audio buffers */
        for bus in &mut self.audio_buffers {
            for i in 0..bus.num_channels() {
                bus.channel_mut(i).left.zero();
                bus.channel_mut(i).right.zero();
            }
        }

        /* Clear the events buffers */
        for bus in &mut self.events_buffers {
            for i in 0..bus.num_channels() {
                bus.channel_mut(i).clear();
            }
        }

        /* Initialize all time buffers */
        for time_bus in &mut self.time_buffers {
            for i in 0..time_bus.num_channels() {
                time_bus[i] = *time;
            }
        }

        /* Process modules */
        for action in &mut self.actions {
            unsafe {
                let module = action.module;

                let mut inputs = IO {
                    audio: transmute_copy(&**action.audio_inputs),
                    events: transmute_copy(&**action.events_inputs),
                    control: transmute_copy(&**action.control_inputs),
                    time: transmute_copy(&**action.time_inputs),
                };

                let mut outputs = IO {
                    audio: transmute_copy(&**action.audio_outputs),
                    events: transmute_copy(&**action.events_outputs),
                    control: transmute_copy(&**action.control_outputs),
                    time: transmute_copy(&**action.time_outputs),
                };

                /* Copy IO Inputs */

                let mut audio_index = 0;
                let mut events_index = 0;

                for pin in (*module).info().inputs {
                    match pin {
                        Pin::Audio(_, _) => audio_index += 1,
                        Pin::Notes(_, _) => events_index += 1,
                        Pin::Control(_, _) => (),
                        Pin::Time(_, _) => (),
                        Pin::ExternalAudio(i) => {
                            inputs.audio[audio_index].left.copy_from(&audio[*i * 2]);
                            inputs.audio[audio_index].right.copy_from(&audio[*i * 2 + 1]);
                            audio_index += 1;
                        },
                        Pin::ExternalNotes(_) => {
                            if action.voice_index == 0 {
                                inputs.events[events_index].copy_from(events);
                            }

                            events_index += 1;
                        },
                    }
                }

                /* Process Voice */

                (*module).process_voice(action.voice_index, &inputs, &mut outputs);

                /* Copy IO Outputs */

                let mut audio_index = 0;
                let mut events_index = 0;
                
                for pin in (*module).info().outputs {
                    match pin {
                        Pin::Audio(_, _) => audio_index += 1,
                        Pin::Notes(_, _) => events_index += 1,
                        Pin::Control(_, _) => (),
                        Pin::Time(_, _) => (),
                        Pin::ExternalAudio(i) => {
                            audio[*i * 2].copy_from(&outputs.audio[audio_index].left);
                            audio[*i * 2 + 1].copy_from(&outputs.audio[audio_index].right);
                            audio_index += 1;
                        },
                        Pin::ExternalNotes(_) => {
                            events.copy_from(&outputs.events[events_index]);
                            events_index += 1;
                        },
                    }
                }

                std::mem::forget(inputs);
                std::mem::forget(outputs);
            }

            for copy_action in &mut action.copy_actions {
                match *copy_action {
                    CopyAction::AudioCopy {
                        ref src,
                        ref mut dest,
                        src_index,
                        dest_index,
                        should_copy,
                    } => {
                        if should_copy {
                            dest[dest_index].copy_from(&src[src_index]);
                        } else {
                            dest[dest_index].add_from(&src[src_index]);
                        }
                    }
                    CopyAction::NotesCopy {
                        ref src,
                        ref mut dest,
                        src_index,
                        dest_index,
                        should_copy,
                    } => {
                        if should_copy {
                            dest[dest_index].copy_from(&src[src_index]);
                        } else {
                            dest[dest_index].append_from(&src[src_index]);
                        }
                    }
                    CopyAction::ControlCopy {
                        ref src,
                        ref mut dest,
                        src_index,
                        dest_index,
                        should_copy,
                    } => {
                        if should_copy {
                            dest[dest_index] = src[src_index];
                        } else {
                            dest[dest_index] = dest[dest_index] + src[src_index];
                        }
                    }
                    CopyAction::TimeCopy {
                        ref src,
                        ref mut dest,
                        src_index,
                        dest_index,
                        should_copy,
                    } => {
                        if should_copy {
                            dest[dest_index] = src[src_index];
                        } else {
                            dest[dest_index] = src[src_index];
                        }
                    }
                }
            }
        }
    }

    pub fn get_connector_type(nodes: &Vec<Rc<Node>>, connector: &Connector) -> Pin {
        for node in nodes {
            if node.id == connector.end.module_id {
                return node.info().inputs[connector.end.pin_index as usize];
            }
        }

        panic!("Couldn't find connector type");
    }

    pub fn get_node_channel(node: Rc<Node>, pin_index: i32) -> usize {
        let mut audio_channel = 0;
        let mut events_channel = 0;
        let mut control_channel = 0;
        let mut time_channel = 0;

        let mut curr_index = 0;

        for input in node.info().inputs {
            if curr_index == pin_index {
                match input {
                    Pin::Audio(_, _) => return audio_channel,
                    Pin::Notes(_, _) => return events_channel,
                    Pin::Control(_, _) => return control_channel,
                    Pin::Time(_, _) => return time_channel,
                    Pin::ExternalAudio(_) => return audio_channel,
                    Pin::ExternalNotes(_) => return events_channel,
                }
            }

            match input {
                Pin::Audio(_, _) => audio_channel += 2,
                Pin::Notes(_, _) => events_channel += 1,
                Pin::Control(_, _) => control_channel += 1,
                Pin::Time(_, _) => time_channel += 1,
                Pin::ExternalAudio(_) => audio_channel += 2,
                Pin::ExternalNotes(_) => events_channel += 1,
            }

            curr_index += 1;
        }

        audio_channel = 0;
        events_channel = 0;
        control_channel = 0;
        time_channel = 0;

        for output in node.info().outputs {
            if curr_index == pin_index {
                match output {
                    Pin::Audio(_, _) => return audio_channel,
                    Pin::Notes(_, _) => return events_channel,
                    Pin::Control(_, _) => return control_channel,
                    Pin::Time(_, _) => return time_channel,
                    Pin::ExternalAudio(_) => return audio_channel,
                    Pin::ExternalNotes(_) => return events_channel,
                }
            }

            match output {
                Pin::Audio(_, _) => audio_channel += 2,
                Pin::Notes(_, _) => events_channel += 1,
                Pin::Control(_, _) => control_channel += 1,
                Pin::Time(_, _) => time_channel += 1,
                Pin::ExternalAudio(_) => return audio_channel,
                Pin::ExternalNotes(_) => return events_channel,
            }

            curr_index += 1;
        }

        panic!("Failed to get channel from pin");
    }

    pub fn sorted_nodes(nodes: &Vec<Rc<Node>>, connectors: &Vec<Connector>) -> Vec<Rc<Node>> {
        let mut seq = Vec::new();

        for node in nodes.iter() {
            if node.info().name == "Audio Output" {
                GraphProcessor::sort_nodes_rec(&mut seq, node.clone(), nodes, connectors);
            }
        }

        for node in nodes.iter() {
            if !seq.contains(&node) {
                GraphProcessor::sort_nodes_rec(&mut seq, node.clone(), nodes, connectors);
            }
        }

        return seq;
    }

    pub fn sort_nodes_rec(
        visited: &mut Vec<Rc<Node>>,
        last_node: Rc<Node>,
        nodes: &Vec<Rc<Node>>,
        connectors: &Vec<Connector>,
    ) {
        for node in GraphProcessor::get_input_nodes(last_node.clone(), nodes, connectors) {
            if !visited.contains(&node) {
                GraphProcessor::sort_nodes_rec(visited, node.clone(), nodes, connectors);
            }
        }

        visited.push(last_node.clone());
    }

    pub fn get_input_nodes(
        node: Rc<Node>,
        nodes: &Vec<Rc<Node>>,
        connectors: &Vec<Connector>,
    ) -> Vec<Rc<Node>> {
        let mut nodes_ret: Vec<Rc<Node>> = Vec::new();

        for c in connectors.iter() {
            if c.end.module_id == node.id {
                let id = c.start.module_id;

                for node in nodes.iter() {
                    if node.id == id {
                        nodes_ret.push(node.clone());
                        break;
                    }
                }
            }
        }

        return nodes_ret;
    }
}
