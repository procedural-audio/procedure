use std::mem::transmute_copy;
use std::mem::ManuallyDrop;

use tonevision_types::buffers::IO;
use tonevision_types::AudioChannelMut;

use crate::graph::*;

/* Actions */

enum CopyAction<T: AudioChannels> {
    AudioCopy {
        src: T,
        dest: T,
        should_copy: bool,
    },
    NotesCopy {
        src: NoteBuffer,
        dest: NoteBuffer,
        should_copy: bool,
    },
    ControlCopy {
        src: ManuallyDrop<ControlBuffer>,
        dest: ManuallyDrop<ControlBuffer>,
        should_copy: bool,
    },
    TimeCopy {
        src: ManuallyDrop<TimeBuffer>,
        dest: ManuallyDrop<TimeBuffer>,
        should_copy: bool,
    },
}

impl<T: AudioChannels> Clone for CopyAction<T> {
    fn clone(&self) -> Self {
        unsafe {
            match self {
                Self::AudioCopy {
                    src,
                    dest,
                    should_copy,
                } => Self::AudioCopy {
                    src: src.unowned(),
                    dest: dest.unowned(),
                    should_copy: should_copy.clone(),
                },
                Self::NotesCopy {
                    src,
                    dest,
                    should_copy,
                } => Self::NotesCopy {
                    src: src.unowned(),
                    dest: dest.unowned(),
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
    audio: Audio<Stereo>,
    events: Notes,
    control_inputs: ManuallyDrop<Bus<ControlBuffer>>,
    control_outputs: ManuallyDrop<Bus<ControlBuffer>>,
    time_inputs: ManuallyDrop<Bus<TimeBuffer>>,
    time_outputs: ManuallyDrop<Bus<TimeBuffer>>,
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
                audio: self.audio.unowned(),
                events: self.events.unowned(),
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

    pub audio_buffers: Vec<AudioBus<Stereo>>,
    pub audio_input_buffers: Vec<AudioBus<Stereo>>,
    pub audio_output_buffers: Vec<AudioBus<Stereo>>,

    pub events_buffers: Vec<NotesBus>,
    pub events_input_buffers: Vec<NotesBus>,
    pub events_output_buffers: Vec<NotesBus>,

    pub control_buffers: Vec<Bus<ControlBuffer>>,
    pub time_buffers: Vec<Bus<TimeBuffer>>,

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

        let mut audio_channels_buffers: Vec<AudioBus<Stereo>> = Vec::new();
        let mut audio_input_channels_buffers: Vec<AudioBus<Stereo>> = Vec::new();
        let mut audio_output_channels_buffers: Vec<AudioBus<Stereo>> = Vec::new();

        let mut events_channels_buffers: Vec<NotesBus> = Vec::new();
        let mut events_input_channels_buffers: Vec<NotesBus> = Vec::new();
        let events_output_channels_buffers: Vec<NotesBus> = Vec::new();

        let mut control_channels_buffers: Vec<Bus<ControlBuffer>> = Vec::new();

        let mut time_channels_buffers: Vec<Bus<TimeBuffer>> = Vec::new();

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
                }
            }

            let node_voice_count = match node.info().voicing {
                Voicing::Monophonic => 1,
                Voicing::Polyphonic => voice_count,
                _ => panic!("Need to update this"),
            };

            for voice_index in 0..node_voice_count {
                let audio_inputs_buffer = AudioBus::new(audio_input_channels_count, block_size);
                let audio_outputs_buffer = AudioBus::new(audio_output_channels_count, block_size);

                let events_inputs_buffer = NotesBus::new(events_input_channels_count, block_size);
                let events_outputs_buffer = NotesBus::new(events_output_channels_count, block_size);

                let mut control_input_bus = Bus::new();
                for i in 0..control_input_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.end.module_id == node.id && conn.end.pin_index == i {
                            connected = true;
                        }
                    });

                    control_input_bus.add_channel(Channel::new(ControlBuffer::new(), connected));
                }

                let mut control_output_bus = Bus::new();
                for i in 0..control_output_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.start.module_id == node.id && conn.start.pin_index == i {
                            connected = true;
                        }
                    });

                    control_output_bus.add_channel(Channel::new(ControlBuffer::new(), connected));
                }

                let mut time_input_bus = Bus::new();
                for i in 0..time_input_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.end.module_id == node.id && conn.end.pin_index == i {
                            connected = true;
                        }
                    });

                    time_input_bus.add_channel(Channel::new(TimeBuffer::new(), connected));
                }

                let mut time_output_bus = Bus::new();
                for i in 0..time_output_channels_count {
                    let mut connected = false;

                    connectors.iter().for_each(|conn| {
                        if conn.start.module_id == node.id && conn.start.pin_index == i {
                            connected = true;
                        }
                    });

                    time_output_bus.add_channel(Channel::new(TimeBuffer::new(), connected));
                }

                if node.info().name == "Audio Input" {
                    audio_input_channels_buffers.push(audio_outputs_buffer.unowned());
                    // events_input_channels_buffers.push(events_outputs_buffer.unowned());
                }

                if node.info().name == "Audio Output" {
                    audio_output_channels_buffers.push(audio_inputs_buffer.unowned());
                    // events_output_channels_buffers.push(events_inputs_buffer.unowned());
                }

                if voice_index == 0 {
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
                }

                unsafe {
                    let node_ptr = Rc::as_ptr(node) as *mut Node;
                    let module_ptr: *mut dyn PolyphonicModule = &mut *(*node_ptr).module;

                    let action = ProcessAction {
                        id: node.id,
                        module: module_ptr,
                        voice_index,
                        node: node.clone(),
                        audio: Audio {
                            inputs: audio_inputs_buffer.unowned(),
                            outputs: audio_outputs_buffer.unowned(),
                        },
                        events: Notes {
                            inputs: events_inputs_buffer.unowned(),
                            outputs: events_outputs_buffer.unowned(),
                        },
                        control_inputs: transmute_copy(&control_input_bus),
                        control_outputs: transmute_copy(&control_output_bus),
                        time_inputs: transmute_copy(&time_input_bus),
                        time_outputs: transmute_copy(&time_output_bus),
                        copy_actions: Vec::new(),
                    };

                    audio_channels_buffers.push(audio_inputs_buffer);
                    audio_channels_buffers.push(audio_outputs_buffer);

                    events_channels_buffers.push(events_inputs_buffer);
                    events_channels_buffers.push(events_outputs_buffer);

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

                            let source1 = action1.audio.outputs.get_channel(index1).unwrap();

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

                                    let dest1 = action2.audio.inputs.get_channel(index2).unwrap();

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

                                    new_action.copy_actions.push(CopyAction::AudioCopy {
                                        src: source1.unowned(),
                                        dest: dest1.unowned(),
                                        should_copy: !dest_used1,
                                    });
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

                            let source1 = action1.events.outputs.get_channel(index1).unwrap();

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

                                    let dest1 = action2.events.inputs.get_channel(index2).unwrap();

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

                                    new_action.copy_actions.push(CopyAction::NotesCopy {
                                        src: source1.unowned(),
                                        dest: dest1.unowned(),
                                        should_copy: !dest_used1,
                                    });
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
                        }
                    }
                }
            }

            process_actions_final.push(new_action.clone());
        }

        /* Figure out which actions can be parallel */

        /*let mut actions = Vec::new();
        let mut i = 0;

        while i < process_actions_final.len() {
            let mut par_actions: Vec<ProcessAction> = Vec::new();
            let mut seq_actions: Vec<ProcessAction> = Vec::new();

            while i < process_actions_final.len() && process_actions_final[i].node.module.voicing() == Voicing::Polyphonic {
                par_actions.push(process_actions_final[i].clone());
                i += 1;
            }

            while i < process_actions_final.len() && process_actions_final[i].node.module.voicing() != Voicing::Polyphonic {
                seq_actions.push(process_actions_final[i].clone());
                i += 1;
            }

            if par_actions.len() > 0 {
                actions.push(Action::Parallel(par_actions));
            }

            if seq_actions.len() > 0 {
                actions.push(Action::Sequential(seq_actions));
            }
        }

        println!("Actions are:");

        for action in actions {
            match action {
                Action::Parallel(par_actions) => {
                    println!(" > Parallel:");
                    for par_action in par_actions {
                        println!("   Process node {} voice {}", par_action.id, par_action.voice_index);
                        for copy_action in par_action.audio_copy_actions {
                            match copy_action {
                                CopyAction::AudioCopy { src, dest, should_copy} => {
                                    if should_copy {
                                        println!("      Copy audio buffer {:p} to {:p}", src.left.as_ptr(), dest.left.as_ptr());
                                    } else {
                                        println!("      Add audio buffer {:p} to {:p}", src.left.as_ptr(), dest.left.as_ptr());
                                    }
                                },
                                CopyAction::NotesCopy { src, dest, should_copy} => {
                                    if should_copy {
                                        println!("      Copy events buffer {:p} to {:p}", src.as_ptr(), dest.as_ptr());
                                    } else {
                                        println!("      Add events buffer {:p} to {:p}", src.as_ptr(), dest.as_ptr());
                                    }
                                },
                                CopyAction::ControlCopy { src, dest, should_copy} => {
                                    if should_copy {
                                        println!("      Copy control {:p} to {:p}", src.as_ptr(), dest.as_ptr());
                                    } else {
                                        println!("      Add control {:p} to {:p}", src.as_ptr(), dest.as_ptr());
                                    }
                                },
                            }
                        }
                    }
                },
                Action::Sequential(seq_actions) => {
                    println!(" > Sequential:");
                    for seq_action in seq_actions {
                        println!("   Process node {} voice {}", seq_action.id, seq_action.voice_index);
                        for copy_action in seq_action.audio_copy_actions {
                            match copy_action {
                                CopyAction::AudioCopy { src, dest, should_copy} => {
                                    if should_copy {
                                        println!("      Copy audio buffer {:p} to {:p}", src.left.as_ptr(), dest.left.as_ptr());
                                    } else {
                                        println!("      Add audio buffer {:p} to {:p}", src.left.as_ptr(), dest.left.as_ptr());
                                    }
                                },
                                CopyAction::NotesCopy { src, dest, should_copy} => {
                                    if should_copy {
                                        println!("      Copy events buffer {:p} to {:p}", src.as_ptr(), dest.as_ptr());
                                    } else {
                                        println!("      Add events buffer {:p} to {:p}", src.as_ptr(), dest.as_ptr());
                                    }
                                },
                                CopyAction::ControlCopy { src, dest, should_copy} => {
                                    if should_copy {
                                        println!("      Copy control {:p} to {:p}", src.as_ptr(), dest.as_ptr());
                                    } else {
                                        println!("      Add control {:p} to {:p}", src.as_ptr(), dest.as_ptr());
                                    }
                                },
                            }
                        }
                    }
                },
            }

            println!("");
        }
        */

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
        events: &mut [NoteBuffer],
    ) {
        /* Zero all audio buffers */
        for bus in &mut self.audio_buffers {
            for channel in bus {
                channel.zero();
            }
        }

        for bus in &mut self.events_buffers {
            for channel in bus {
                channel.clear();
            }
        }

        /* Initialize all time buffers */
        for time_bus in &mut self.time_buffers {
            for i in 0..time_bus.num_channels() {
                *time_bus[i] = *time;
            }
        }

        /* Copy all input channels */
        for channels in &mut self.audio_input_buffers {
            for (src_channel, dest_channel) in audio.iter_mut().zip(channels) {
                dest_channel.left.copy_from(src_channel);
                dest_channel.right.copy_from(src_channel);
            }
        }

        /* Copy all input channels */
        for event in &events[0] {
            for bus in &mut self.events_input_buffers {
                for buffer in bus.as_mut() {
                    buffer.push(*event);
                }
            }
        }

        /* Process modules */
        for action in &mut self.actions {
            unsafe {
                let module = action.module;
                let audio = action.audio.unowned();
                let events = action.events.unowned();

                let inputs = IO {
                    audio: audio.inputs,
                    events: events.inputs,
                    control: transmute_copy(&action.control_inputs),
                    time: transmute_copy(&action.time_inputs),
                };

                let mut outputs = IO {
                    audio: audio.outputs,
                    events: events.outputs,
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
                            dest.add_from(src);
                        }
                    }
                    CopyAction::ControlCopy {
                        ref src,
                        ref mut dest,
                        should_copy,
                    } => {
                        if should_copy {
                            dest.set(src.get());
                        } else {
                            let value = dest.get();
                            dest.set(value + src.get());
                        }
                    }
                    CopyAction::TimeCopy {
                        ref src,
                        ref mut dest,
                        should_copy,
                    } => {
                        if should_copy {
                            dest.set(src.get());
                        } else {
                            dest.set(src.get());
                        }
                    }
                }
            }
        }

        /* Copy all output channels */
        for channels in &mut self.audio_output_buffers {
            for bus in channels {
                if audio.len() == 1 {
                    audio[0].add_from(&mut bus.left);
                } else if audio.len() == 2 {
                    audio[0].add_from(&mut bus.left);
                    audio[1].add_from(&mut bus.right);
                } else {
                    panic!("Unsupported input count");
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
                }
            }

            match input {
                Pin::Audio(_, _) => audio_channel += 2,
                Pin::Notes(_, _) => events_channel += 1,
                Pin::Control(_, _) => control_channel += 1,
                Pin::Time(_, _) => time_channel += 1,
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
                }
            }

            match output {
                Pin::Audio(_, _) => audio_channel += 2,
                Pin::Notes(_, _) => events_channel += 1,
                Pin::Control(_, _) => control_channel += 1,
                Pin::Time(_, _) => time_channel += 1,
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
