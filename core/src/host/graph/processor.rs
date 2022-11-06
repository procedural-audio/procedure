use std::mem::transmute_copy;
use std::mem::ManuallyDrop;

use tonevision_types::buffers::IO;
use tonevision_types::AudioChannelMut;

use crate::graph::*;

/* Actions */

enum CopyAction<T> {
    AudioCopy {
        src: ManuallyDrop<T>,
        dest: ManuallyDrop<T>,
        should_copy: bool,
    },
    NotesCopy {
        src: ManuallyDrop<NoteBuffer>,
        dest: ManuallyDrop<NoteBuffer>,
        should_copy: bool,
    },
    ControlCopy {
        src: ManuallyDrop<Box<f32>>,
        dest: ManuallyDrop<Box<f32>>,
        should_copy: bool,
    },
    TimeCopy {
        src: ManuallyDrop<Box<Time>>,
        dest: ManuallyDrop<Box<Time>>,
        should_copy: bool,
    },
}

impl<T> Clone for CopyAction<T> {
    fn clone(&self) -> Self {
        // SIMPLIFY THIS TO A SINGLE transmute_copy
        unsafe {
            match self {
                Self::AudioCopy {
                    src,
                    dest,
                    should_copy,
                } => Self::AudioCopy {
                    src: transmute_copy(src),
                    dest: transmute_copy(dest),
                    should_copy: should_copy.clone(),
                },
                Self::NotesCopy {
                    src,
                    dest,
                    should_copy,
                } => Self::NotesCopy {
                    src: transmute_copy(src),
                    dest: transmute_copy(dest),
                    should_copy: should_copy.clone(),
                },
                Self::ControlCopy {
                    src,
                    dest,
                    should_copy,
                } => Self::ControlCopy {
                    src: transmute_copy(src),
                    dest: transmute_copy(dest),
                    should_copy: should_copy.clone(),
                },
                Self::TimeCopy {
                    src,
                    dest,
                    should_copy,
                } => Self::TimeCopy {
                    src: transmute_copy(src),
                    dest: transmute_copy(dest),
                    should_copy: should_copy.clone(),
                },
            }
        }
    }
}

pub struct ProcessAction {
    id: i32,
    module: *mut dyn PolyphonicModule,
    voice_index: usize,
    node: Rc<Node>,
    audio_inputs: ManuallyDrop<Bus<Stereo>>,
    audio_outputs: ManuallyDrop<Bus<Stereo>>,
    events_inputs: ManuallyDrop<Bus<NoteBuffer>>,
    events_outputs: ManuallyDrop<Bus<NoteBuffer>>,
    control_inputs: ManuallyDrop<Bus<Box<f32>>>,
    control_outputs: ManuallyDrop<Bus<Box<f32>>>,
    time_inputs: ManuallyDrop<Bus<Box<Time>>>,
    time_outputs: ManuallyDrop<Bus<Box<Time>>>,
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

    pub audio_buffers: Vec<Bus<Stereo>>,
    pub audio_input_buffers: Vec<Bus<Stereo>>,
    pub audio_output_buffers: Vec<Bus<Stereo>>,

    pub events_buffers: Vec<Bus<NoteBuffer>>,
    pub events_input_buffers: Vec<Bus<NoteBuffer>>,
    pub events_output_buffers: Vec<Bus<NoteBuffer>>,

    pub control_buffers: Vec<Bus<Box<f32>>>,
    pub time_buffers: Vec<Bus<Box<Time>>>,

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
            audio_input_buffers: Vec::new(),
            audio_output_buffers: Vec::new(),
            events_buffers: Vec::new(),
            events_input_buffers: Vec::new(),
            events_output_buffers: Vec::new(),
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

        let mut audio_channels_buffers: Vec<Bus<Stereo>> = Vec::new();
        let mut audio_input_channels_buffers: Vec<Bus<Stereo>> = Vec::new();
        let mut audio_output_channels_buffers: Vec<Bus<Stereo>> = Vec::new();

        let mut events_channels_buffers: Vec<Bus<NoteBuffer>> = Vec::new();
        let mut events_input_channels_buffers: Vec<Bus<NoteBuffer>> = Vec::new();
        let mut events_output_channels_buffers: Vec<Bus<NoteBuffer>> = Vec::new();

        let mut control_channels_buffers: Vec<Bus<Box<f32>>> = Vec::new();

        let mut time_channels_buffers: Vec<Bus<Box<Time>>> = Vec::new();

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
                // let audio_inputs_buffer = AudioBus::new(audio_input_channels_count, block_size);
                // let audio_outputs_buffer = AudioBus::new(audio_output_channels_count, block_size);

                let mut audio_input_bus = Bus::new();
                for i in 0..audio_input_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.end.module_id == node.id && conn.end.pin_index == i {
                            connected = true;
                        }
                    });

                    audio_input_bus.add_channel(Channel::new(Stereo::init(0.0, block_size), connected));
                }

                let mut audio_output_bus = Bus::new();
                for i in 0..audio_output_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.start.module_id == node.id && conn.start.pin_index == i {
                            connected = true;
                        }
                    });

                    audio_output_bus.add_channel(Channel::new(Stereo::init(0.0, block_size), connected));
                }

                // let events_inputs_buffer = NotesBus::new(events_input_channels_count, block_size);
                // let events_outputs_buffer = NotesBus::new(events_output_channels_count, block_size);

                let mut events_input_bus = Bus::new();
                for i in 0..events_input_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.end.module_id == node.id && conn.end.pin_index == i {
                            connected = true;
                        }
                    });

                    events_input_bus.add_channel(Channel::new(NoteBuffer::with_capacity(32), connected));
                }

                let mut events_output_bus = Bus::new();
                for i in 0..events_output_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.start.module_id == node.id && conn.start.pin_index == i {
                            connected = true;
                        }
                    });

                    events_output_bus.add_channel(Channel::new(NoteBuffer::with_capacity(32), connected));
                }

                let mut control_input_bus = Bus::new();
                for i in 0..control_input_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.end.module_id == node.id && conn.end.pin_index == i {
                            connected = true;
                        }
                    });

                    control_input_bus.add_channel(Channel::new(Box::new(0.0), connected));
                }

                let mut control_output_bus = Bus::new();
                for i in 0..control_output_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.start.module_id == node.id && conn.start.pin_index == i {
                            connected = true;
                        }
                    });

                    control_output_bus.add_channel(Channel::new(Box::new(0.0), connected));
                }

                let mut time_input_bus = Bus::new();
                for i in 0..time_input_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.end.module_id == node.id && conn.end.pin_index == i {
                            connected = true;
                        }
                    });

                    time_input_bus.add_channel(Channel::new(Box::new(Time::from(0.0, 0.0)), connected));
                }

                let mut time_output_bus = Bus::new();
                for i in 0..time_output_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.start.module_id == node.id && conn.start.pin_index == i {
                            connected = true;
                        }
                    });

                    time_output_bus.add_channel(Channel::new(Box::new(Time::from(0.0, 0.0)), connected));
                }

                if node.info().name == "Audio Input" {
                    // audio_input_channels_buffers.push(audio_outputs_buffer.unowned());
                    // events_input_channels_buffers.push(events_outputs_buffer.unowned());
                }

                if node.info().name == "Audio Output" {
                    // audio_output_channels_buffers.push(audio_inputs_buffer.unowned());
                    // events_output_channels_buffers.push(events_inputs_buffer.unowned());
                }

                /*if voice_index == 0 {
                    for feature in node.info().features {
                        match feature {
                            Feature::MidiInput => {
                                events_input_channels_buffers.push(events_inputs_buffer.unowned());
                            }
                            Feature::MidiOutput => {}
                            Feature::AudioInput => {}
                            Feature::AudioOutput => {}
                        }
                    }
                }*/

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

        println!("Pushing copy actions");

        let mut dest_audio_buffers_used = Vec::new();
        let mut dest_events_buffers_used = Vec::new();
        let mut dest_control_buffers_used = Vec::new();
        let mut dest_time_buffers_used = Vec::new();

        let mut process_actions_final: Vec<ProcessAction> = Vec::new();

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
                                            src: transmute_copy(source1),
                                            dest: transmute_copy(dest1),
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
                                            src: transmute_copy(source1),
                                            dest: transmute_copy(dest1),
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
                                            src: transmute_copy(source1),
                                            dest: transmute_copy(dest1),
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
                                            src: transmute_copy(source1),
                                            dest: transmute_copy(dest1),
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
            audio_input_buffers: audio_input_channels_buffers,
            audio_output_buffers: audio_output_channels_buffers,

            events_buffers: events_channels_buffers,
            events_input_buffers: events_input_channels_buffers,
            events_output_buffers: events_output_channels_buffers,

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
        vars: &Vars,
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

        /* Copy all input channels */
        for channels in &mut self.audio_input_buffers {
            /* SHOULD DO INPUT CHANNEL COPYING HERE */
        }

        /* Copy all input channels */
        for event in events {
            for bus in &mut self.events_input_buffers {
                /* COPY INPUT EVENTS TO CORRECT BUFFER HERE */
            }
        }

        /* Process modules */
        for action in &mut self.actions {
            unsafe {
                let module = action.module;

                let inputs = IO {
                    audio: transmute_copy(&action.audio_inputs),
                    events: transmute_copy(&action.events_inputs),
                    control: transmute_copy(&action.control_inputs),
                    time: transmute_copy(&action.time_inputs),
                };

                let mut outputs = IO {
                    audio: transmute_copy(&action.audio_outputs),
                    events: transmute_copy(&action.events_outputs),
                    control: transmute_copy(&action.control_outputs),
                    time: transmute_copy(&action.time_outputs),
                };

                (*module).process_voice(vars, action.voice_index, &inputs, &mut outputs);

                std::mem::forget(inputs);
                std::mem::forget(outputs);
            }

            for copy_action in &mut action.copy_actions {
                match *copy_action {
                    CopyAction::AudioCopy {
                        ref src,
                        ref mut dest,
                        should_copy,
                    } => {
                        if should_copy {
                            dest.copy_from(src);
                        } else {
                            dest.add_from(src);
                        }
                    }
                    CopyAction::NotesCopy {
                        ref src,
                        ref mut dest,
                        should_copy,
                    } => {
                        if should_copy {
                            dest.copy_from(src);
                        } else {
                            dest.append_from(src);
                        }
                    }
                    CopyAction::ControlCopy {
                        ref src,
                        ref mut dest,
                        should_copy,
                    } => {
                        if should_copy {
                            ***dest = ***src;
                        } else {
                            ***dest = ***dest + ***src;
                        }
                    }
                    CopyAction::TimeCopy {
                        ref src,
                        ref mut dest,
                        should_copy,
                    } => {
                        if should_copy {
                            ***dest = ***src;
                        } else {
                            ***dest = ***src;
                        }
                    }
                }
            }
        }

        /* Copy all output channels */
        for channels in &mut self.audio_output_buffers {

            /* SHOULD TO OUTPUT CHANNEL COPYING HERE */

            /*for bus in channels {
                if audio.len() == 1 {
                    audio[0].add_from(&mut bus.left);
                } else if audio.len() == 2 {
                    audio[0].add_from(&mut bus.left);
                    audio[1].add_from(&mut bus.right);
                } else {
                    panic!("Unsupported input count");
                }
            }*/
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
