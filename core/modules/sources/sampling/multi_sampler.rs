use crate::*;

use std::sync::{Arc, RwLock};

pub struct MultiSampler {
    map: Arc<RwLock<SampleMap>>,
}

impl Module for MultiSampler {
    type Voice = Vec<SamplePlayer>;

    const INFO: Info = Info {
        title: "Multi-Sampler",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(600, 400),
        voicing: Voicing::Monophonic,
        inputs: &[Pin::Notes("Midi Input", 20)],
        outputs: &[Pin::Audio("Audio Output", 20)],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        Self {
            map: Arc::new(RwLock::new(SampleMap::new())),
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        vec![
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
            SamplePlayer::new(),
        ]
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Transform {
            position: (35, 35),
            size: (600 - 35 * 2, 400 - 35 - 20),
            child: Tabs {
                tabs: (
                    Tab {
                        icon: Icon {
                            path: "logos/audio.svg",
                            color: Color::BLUE,
                        },
                        child: SampleMapper {
                            map: self.map.clone(),
                        },
                    },
                    Tab {
                        icon: Icon {
                            path: "logos/audio.svg",
                            color: Color::BLUE,
                        },
                        child: SampleEditor {},
                    },
                    Tab {
                        icon: Icon {
                            path: "logos/audio.svg",
                            color: Color::BLUE,
                        },
                        child: LuaEditor {
                            dir: "~/temp.lua"
                        },
                    },
                ),
            },
        });
    }

    fn prepare(&self, voices: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        println!("Sample rate is {}", sample_rate);

        for voice in voices {
            // voice.prepare(sample_rate, block_size);
        }
    }

    fn process(&mut self, voices: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        /*for note in &inputs.events[0] {
            match note {
                Event::NoteOn { note, offset } => {
                    if let Ok(map) = self.map.try_read() {
                        let mut sample = None;
                        let note = Note::from_pitch(note.pitch);

                        /* Find sample to play */

                        for region in &map.regions {
                            if region.low_note <= note.num() && region.high_note >= note.num() {
                                let low = Note::from_num(region.low_note);
                                let high = Note::from_num(region.high_note);

                                println!("Region {} {}", low.pitch(), high.pitch());

                                if region.sounds.len() > 0 {
                                    sample = Some(region.sounds[0].clone());
                                }

                                break;
                            }
                        }

                        // sample = Some(map.regions[0].sounds[0].clone()); // COMMENT THIS LINE OUT !!!!!!!!!!

                        if let Some(sample) = sample {
                            /* Find voice to play note */

                            let mut found = false;
                            let mut i = 0;
                            voices.iter_mut().for_each(|voice| {
                                if !voice.is_active() && !found {
                                    println!("Playing note {}", note.name());
                                    voice.set_sample(sample.clone());
                                    voice.note_on(
                                        note.id,
                                        *offset,
                                        Note::from_pitch(note.pitch),
                                        note.pressure,
                                    );
                                    found = true;
                                }

                                i += 1;
                            });

                            /* Steal voice to play note */

                            let mut voice_index = 0;
                            let mut sample_index = usize::MAX;
                            if !found {
                                for i in 0..voices.len() {
                                    if voices[i].position() < sample_index {
                                        voice_index = i;
                                        sample_index = voices[i].position();
                                    }
                                }

                                if sample_index < usize::MAX {
                                    voices[voice_index].set_sample(sample);
                                    voices[voice_index].note_on(
                                        note.id,
                                        *offset,
                                        NoteMessage::from_pitch(note.pitch),
                                        note.pressure,
                                    );
                                } else {
                                    println!("Failed to find available voice");
                                }
                            }
                        } else {
                            println!("Couldn't find sample for note");
                        }
                    } else {
                        println!("Couldn't read map while writing");
                    }
                }
                Event::NoteOff { id } => {
                    voices.iter_mut().for_each(|voice| {
                        if voice.id() != *id {
                            voice.note_off();
                        }
                    });
                }
                Event::Pitch { id, freq } => {
                    voices.iter_mut().for_each(|voice| {
                        if voice.id() != *id {
                            voice.set_pitch(*freq);
                        }
                    });
                }
                Event::Pressure { id, pressure } => {
                    voices.iter_mut().for_each(|voice| {
                        if voice.id() != *id {
                            voice.set_pressure(*pressure);
                        }
                    });
                }
                Event::Controller { id: _, value: _ } => (),
                Event::ProgramChange { id: _, value: _ } => (),
                Event::None => break,
            }
        }

        voices.iter_mut().for_each(|voice| {
            if voice.is_active() {
                voice.process(&mut outputs.audio[0]);
            }
        });*/
    }
}

/* ===== Sample Mapper ===== */

pub struct SampleMapper {
    pub map: Arc<RwLock<SampleMap>>,
}

impl WidgetNew for SampleMapper {
    fn get_name(&self) -> &'static str {
        "SampleMapper"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_count(widget: &mut SampleMapper) -> usize {
    (*widget.map.read().unwrap()).regions.len()
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_add_region(
    widget: &mut SampleMapper,
    low_note: u32,
    high_note: u32,
    low_velocity: f32,
    high_velocity: f32,
) {
    (*widget.map.write().unwrap())
        .regions
        .push(SoundRegion::<SampleFile<2>> {
            low_note,
            high_note,
            low_velocity,
            high_velocity,
            index: 0,
            sounds: Vec::new(),
        });
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_remove_region(widget: &mut SampleMapper, index: usize) {
    (*widget.map.write().unwrap()).regions.remove(index);
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_low_note(
    widget: &mut SampleMapper,
    index: usize,
) -> u32 {
    (*widget.map.read().unwrap()).regions[index].low_note
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_set_region_low_note(
    widget: &mut SampleMapper,
    index: usize,
    low_note: u32,
) {
    (*widget.map.write().unwrap()).regions[index].low_note = low_note;
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_high_note(
    widget: &mut SampleMapper,
    index: usize,
) -> u32 {
    (*widget.map.read().unwrap()).regions[index].high_note
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_set_region_high_note(
    widget: &mut SampleMapper,
    index: usize,
    high_note: u32,
) {
    (*widget.map.write().unwrap()).regions[index].high_note = high_note;
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_low_velocity(
    widget: &mut SampleMapper,
    index: usize,
) -> f32 {
    (*widget.map.read().unwrap()).regions[index].low_velocity
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_set_region_low_velocity(
    widget: &mut SampleMapper,
    index: usize,
    low_velocity: f32,
) {
    (*widget.map.write().unwrap()).regions[index].low_velocity = low_velocity;
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_high_velocity(
    widget: &mut SampleMapper,
    index: usize,
) -> f32 {
    (*widget.map.read().unwrap()).regions[index].high_velocity
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_set_region_high_velocity(
    widget: &mut SampleMapper,
    index: usize,
    high_velocity: f32,
) {
    (*widget.map.write().unwrap()).regions[index].high_velocity = high_velocity;
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_sample_count(
    widget: &mut SampleMapper,
    index: usize,
) -> usize {
    (*widget.map.write().unwrap()).regions[index].sounds.len()
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_sample_path(
    widget: &mut SampleMapper,
    index: usize,
    sample_index: usize,
) -> *const i8 {
    let map = &*widget.map.read().unwrap();
    let path = map.regions[index].sounds[sample_index].path().clone();
    let s = std::ffi::CString::new(path).unwrap();
    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_sample_buffer_left(
    widget: &mut SampleMapper,
    index: usize,
    sample_index: usize,
) -> FFIBuffer {
    // let mut buffer_new = Vec::new();
    let sample = &(*widget.map.read().unwrap()).regions[index].sounds[sample_index];

    todo!();

    /*let skip = sample.as_array()[0].len() / 300;

    for sample in sample.as_array()[0].iter().step_by(skip) {
        buffer_new.push(*sample);
    }

    let buffer_ret = FFIBuffer {
        data: buffer_new.as_mut_ptr(),
        length: buffer_new.len(),
    };

    std::mem::forget(buffer_new);

    return buffer_ret;*/
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_sample_buffer_right(
    widget: &mut SampleMapper,
    index: usize,
    sample_index: usize,
) -> FFIBuffer {
    // let mut buffer_new = Vec::new();
    let sample = &(*widget.map.read().unwrap()).regions[index].sounds[sample_index];

    todo!();

    /*let skip = sample.as_array()[1].len() / 300;

    for sample in sample.as_array()[1].iter().step_by(skip) {
        buffer_new.push(*sample);
    }

    let buffer_ret = FFIBuffer {
        data: buffer_new.as_mut_ptr(),
        length: buffer_new.len(),
    };

    std::mem::forget(buffer_new);

    return buffer_ret;*/
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_sample_buffer_time_ms(
    widget: &mut SampleMapper,
    index: usize,
    sample_index: usize,
) -> f64 {
    let sample = &(*widget.map.read().unwrap()).regions[index].sounds[sample_index];
    return sample.len() as f64 / sample.sample_rate() as f64 * 1000.0;
}

/* ===== Sample Editor ===== */

pub struct SampleEditor {}

impl WidgetNew for SampleEditor {
    fn get_name(&self) -> &'static str {
        "SampleEditor"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

pub struct LuaEditor {
    pub dir: &'static str
}

impl WidgetNew for LuaEditor {
    fn get_name(&self) -> &'static str {
        "LuaEditor"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

pub struct MySampler {
    pub map: Arc<RwLock<SampleMap>>,
}

impl MySampler {
    pub fn new() -> Self {
        Self {
            map: Arc::new(RwLock::new(SampleMap::new())),
        }
    }
}

pub struct SampleMap {
    regions: Vec<SoundRegion<SampleFile<2>>>,
}

impl SampleMap {
    pub fn new() -> Self {
        let mut temp = Self {
            regions: Vec::new(),
        };

        if cfg!(target_os = "macos") {
            println!("Loading piano preset");
            // temp.load_dspreset("/Users/chasekanipe/piano_samples/piano.dspreset");
            temp.load_dspreset("/Users/chasekanipe/guitar_samples/guitar.dspreset");
        } else {
            temp.load_dspreset("/home/chase/guitar_samples/guitar.dspreset");
        }

        return temp;
    }

    pub fn load_dspreset(&mut self, path: &str) {
        use std::fs::File;
        use std::io::BufReader;
        use xml::reader::{EventReader, XmlEvent};

        let mut regions: Vec<SoundRegion<SampleFile<2>>> = Vec::new();

        match File::open(path) {
            Ok(file) => {
                let reader = BufReader::new(file);
                let mut parser = EventReader::new(reader);

                loop {
                    println!("Loop");
                    match parser.next() {
                        Ok(XmlEvent::StartElement {
                            name,
                            attributes: _,
                            namespace: _,
                        }) => {
                            println!("Element {}", name);
                            match name.to_string().as_str() {
                                "ui" => loop {
                                    match parser.next() {
                                        Ok(XmlEvent::StartElement {
                                            name,
                                            attributes: _,
                                            namespace: _,
                                        }) => match name.to_string().as_str() {
                                            "tab" => println!("Found tab"),
                                            "labeled-knob" => println!("Found knob"),
                                            "binding" => println!("Found binding"),
                                            "ui" => break,
                                            _ => (),
                                        },
                                        Ok(XmlEvent::EndElement { name }) => {
                                            match name.to_string().as_str() {
                                                "ui" => break,
                                                _ => (),
                                            }
                                        }
                                        Ok(XmlEvent::EndDocument) => break,
                                        Err(e) => {
                                            println!("Error {}", e);
                                            break;
                                        }
                                        _ => (),
                                    }
                                },
                                "groups" => loop {
                                    println!("Found groups");
                                    match parser.next() {
                                        Ok(XmlEvent::StartElement {
                                            name,
                                            attributes: _,
                                            namespace: _,
                                        }) => match name.to_string().as_str() {
                                            "group" => loop {
                                                println!("Found group");
                                                match parser.next() {
                                                    Ok(XmlEvent::StartElement {
                                                        name,
                                                        attributes,
                                                        namespace: _,
                                                    }) => match name.to_string().as_str() {
                                                        "sample" => {
                                                            println!("Found sample");
                                                            let mut region =
                                                                SoundRegion::<SampleFile<2>> {
                                                                    low_note: 0,
                                                                    high_note: 127,
                                                                    low_velocity: 0.0,
                                                                    high_velocity: 1.0,
                                                                    index: 0,
                                                                    sounds: Vec::new(),
                                                                };

                                                            let mut root_note = 0;

                                                            let mut sample_path = String::new();

                                                            for a in attributes {
                                                                match a.name.to_string().as_str() {
                                                                            "loNote" => region.low_note = a.value.to_string().parse::<u32>().unwrap(),
                                                                            "hiNote" => region.high_note = a.value.to_string().parse::<u32>().unwrap(),
                                                                            "loVel" => region.low_velocity = a.value.to_string().parse::<u32>().unwrap() as f32 / 127.0,
                                                                            "hiVel" => region.high_velocity = a.value.to_string().parse::<u32>().unwrap() as f32 / 127.0,
                                                                            "rootNote" => root_note = a.value.to_string().parse::<u32>().unwrap(),
                                                                            "seqPosition" => (),
                                                                            "path" => {
                                                                                let dir = std::path::Path::new(path);
                                                                                let mut path = dir.parent().unwrap().to_str().unwrap().to_owned();
                                                                                path.push_str("/");
                                                                                path.push_str(&a.value);

                                                                                sample_path = path;
                                                                            },
                                                                            s => println!("Unknown sample attribute {}", s),
                                                                        }
                                                            }

                                                            let mut found = false;
                                                            for r in &mut regions {
                                                                if r.low_note == region.low_note
                                                                    && r.high_note
                                                                        == region.high_note
                                                                {
                                                                    println!("Adding sample to existing region");
                                                                    found = true;
                                                                    r.sounds.push(SampleFile::load(
                                                                        &sample_path,
                                                                    ));
                                                                }
                                                            }

                                                            if !found {
                                                                println!(
                                                                    "Adding sample to new region"
                                                                );
                                                                region.sounds.push(SampleFile::load(
                                                                    &sample_path,
                                                                ));
                                                                regions.push(region);
                                                            }
                                                        }
                                                        _ => (),
                                                    },
                                                    Ok(XmlEvent::EndDocument) => break,
                                                    Err(_e) => break,
                                                    _ => (),
                                                }
                                            },
                                            _ => (),
                                        },
                                        Ok(XmlEvent::EndElement { name }) => {
                                            match name.to_string().as_str() {
                                                "groups" => break,
                                                _ => (),
                                            }
                                        }
                                        Ok(XmlEvent::EndDocument) => break,
                                        Err(_e) => break,
                                        _ => (),
                                    }
                                },
                                "effects" => {}
                                "midi" => {}
                                _ => (),
                            }
                        }
                        Ok(XmlEvent::EndElement { name: _ }) => {
                            // println!("{}-{}", indent(depth), name);
                        }
                        Err(_e) => break,
                        Ok(XmlEvent::EndDocument) => break,
                        _ => (),
                    }
                }
            }
            Err(_e) => println!("Couldn't open dspreset file {}", path),
        };

        self.regions.clear();
        self.regions = regions;
    }
}
