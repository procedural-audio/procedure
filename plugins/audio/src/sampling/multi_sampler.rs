use crate::*;

use pa_dsp::loadable::{Loadable, Lock};

pub struct MultiSampler {
    map: Lock<SampleMap>,
}

impl Module for MultiSampler {
    type Voice = PitchedSamplePlayer<Stereo2>;

    const INFO: Info = Info {
        title: "Multi-Sampler",
        id: "default.sampling.multisampler",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(600, 400),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Midi Input", 10)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 10)
        ],
        path: &["Audio", "Sampling", "Multi-Sampler"],
        presets: Presets {
            path: "multi-samples",
            extension: ".multisample"
        }
    };

    fn new() -> Self {
        Self {
            map: Lock::new(SampleMap::new()),
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        PitchedSamplePlayer::new()
    }

    fn load(&mut self, version: &str, state: &State) {
        // *self.map.write().unwrap() = state.load("map");
    }

    fn save(&self, state: &mut State) {
        // state.save("map", *self.map.read().unwrap());
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(
            Padding {
                padding: (5, 35, 5, 5),
                child: Browser {
                    loadable: self.map.clone(),
                    directory: Directory::SAMPLES,
                    extensions: &[".multisample", ".dspreset"],
                    child: Scripter {
                        dir: "directory/goes/here",
                        on_update: | script | {
                            println!("Update script with {}", script);
                        },
                        child: SampleMapper {
                            map: self.map.clone(),
                        }
                    }
                }
            }
        );
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.prepare(sample_rate, block_size);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure: _ } => {
                    /*if let Ok(map) = self.map.try_read() {
                        for region in &map.regions {
                            let num = pitch_to_num(pitch);
                            if region.low_note <= num && region.high_note >= num {
                                println!("Playing note {}", num);
                                voice.set_sample(region.sounds[0].clone());
                                voice.set_pitch(pitch);
                                voice.play();
                                break;
                            }
                        }
                    }*/
                },
                Event::NoteOff => voice.stop(),
                Event::Pitch(pitch) => voice.set_pitch(pitch),
                _ => ()
            }
        }

        voice.generate_block(&mut outputs.audio[0]);
    }
}

/* ===== Sample Mapper ===== */

pub struct SampleMapper {
    pub map: Lock<SampleMap>,
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
    (*widget.map.read()).regions.len()
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_add_region(
    widget: &mut SampleMapper,
    low_note: u32,
    high_note: u32,
    low_velocity: f32,
    high_velocity: f32,
) {
    (*widget.map.write())
        .regions
        .push(SoundRegion::<SampleFile<Stereo2>> {
            low_note,
            high_note,
            low_velocity,
            high_velocity,
            index: 0,
            sounds: Vec::new(),
        });
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_load(widget: &mut SampleMapper, path: &i8) {
    let path= str_from_char(path);
    *widget.map.write() = SampleMap::load(path).unwrap();
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_remove_region(widget: &mut SampleMapper, index: usize) {
    (*widget.map.write()).regions.remove(index);
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_low_note(
    widget: &mut SampleMapper,
    index: usize,
) -> u32 {
    (*widget.map.read()).regions[index].low_note
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_set_region_low_note(
    widget: &mut SampleMapper,
    index: usize,
    low_note: u32,
) {
    (*widget.map.write()).regions[index].low_note = low_note;
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_high_note(
    widget: &mut SampleMapper,
    index: usize,
) -> u32 {
    (*widget.map.read()).regions[index].high_note
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_set_region_high_note(
    widget: &mut SampleMapper,
    index: usize,
    high_note: u32,
) {
    (*widget.map.write()).regions[index].high_note = high_note;
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_low_velocity(
    widget: &mut SampleMapper,
    index: usize,
) -> f32 {
    (*widget.map.read()).regions[index].low_velocity
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_set_region_low_velocity(
    widget: &mut SampleMapper,
    index: usize,
    low_velocity: f32,
) {
    (*widget.map.write()).regions[index].low_velocity = low_velocity;
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_high_velocity(
    widget: &mut SampleMapper,
    index: usize,
) -> f32 {
    (*widget.map.read()).regions[index].high_velocity
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_set_region_high_velocity(
    widget: &mut SampleMapper,
    index: usize,
    high_velocity: f32,
) {
    (*widget.map.write()).regions[index].high_velocity = high_velocity;
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_sample_count(
    widget: &mut SampleMapper,
    index: usize,
) -> usize {
    (*widget.map.write()).regions[index].sounds.len()
}

#[no_mangle]
pub extern "C" fn ffi_sample_mapper_get_region_sample_path(
    widget: &mut SampleMapper,
    index: usize,
    sample_index: usize,
) -> *const i8 {
    let map = &*widget.map.read();
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
    let sample = &(*widget.map.read()).regions[index].sounds[sample_index];

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
    let sample = &(*widget.map.read()).regions[index].sounds[sample_index];

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
    // let sample = &(*widget.map.read().unwrap()).regions[index].sounds[sample_index];
    // return sample.len() as f64 / sample.sample_rate() as f64 * 1000.0;
    todo!()
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

pub struct MySampler {
    pub map: Lock<SampleMap>,
}

impl MySampler {
    pub fn new() -> Self {
        Self {
            map: Lock::new(SampleMap::new()),
        }
    }
}

pub struct SampleMap {
    regions: Vec<SoundRegion<SampleFile<Stereo2>>>,
}

impl SampleMap {
    pub fn new() -> Self {
        let mut temp = Self {
            regions: Vec::new(),
        };

        if cfg!(target_os = "macos") {
            Self::load("/Users/chasekanipe/Music/Decent Samples/Flamenco Dreams Guitar/FlamencoDreams2.dspreset").unwrap()
        } else {
            Self::load("/home/chase/guitar_samples/guitar.dspreset").unwrap()
        }
    }
}

impl Loadable for SampleMap {
    fn load(path: &str) -> Result<Self, String> {
        if path.ends_with(".dspreset") {
            Ok(SampleMap { regions: load_dspreset(path) })
        } else {
            Err("Load not implemented".to_string())
        }
    }
}

fn load_dspreset(path: &str) -> Vec<SoundRegion<SampleFile<Stereo2>>> {
    use std::fs::File;
    use std::io::BufReader;
    use xml::reader::{EventReader, XmlEvent};

    let mut regions: Vec<SoundRegion<SampleFile<Stereo2>>> = Vec::new();

    match File::open(path) {
        Ok(file) => {
            let reader = BufReader::new(file);
            let mut parser = EventReader::new(reader);

            loop {
                // println!("Loop");
                match parser.next() {
                    Ok(XmlEvent::StartElement {
                        name,
                        attributes: _,
                        namespace: _,
                    }) => {
                        // println!("Element {}", name);
                        match name.to_string().as_str() {
                            "ui" => loop {
                                match parser.next() {
                                    Ok(XmlEvent::StartElement {
                                        name,
                                        attributes: _,
                                        namespace: _,
                                    }) => match name.to_string().as_str() {
                                        /*"tab" => println!("Found tab"),
                                        "labeled-knob" => println!("Found knob"),
                                        "binding" => println!("Found binding"),*/
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
                                // println!("Found groups");
                                match parser.next() {
                                    Ok(XmlEvent::StartElement {
                                        name,
                                        attributes: _,
                                        namespace: _,
                                    }) => match name.to_string().as_str() {
                                        "group" => loop {
                                            // println!("Found group");
                                            match parser.next() {
                                                Ok(XmlEvent::StartElement {
                                                    name,
                                                    attributes,
                                                    namespace: _,
                                                }) => match name.to_string().as_str() {
                                                    "sample" => {
                                                        let mut region =
                                                            SoundRegion::<SampleFile<Stereo2>> {
                                                                low_note: 0,
                                                                high_note: 127,
                                                                low_velocity: 0.0,
                                                                high_velocity: 1.0,
                                                                index: 0,
                                                                sounds: Vec::new(),
                                                            };

                                                        let mut root_note = 0;
                                                        let mut start = 0;
                                                        let mut end = 0;

                                                        let mut sample_path = String::new();

                                                        for a in attributes {
                                                            match a.name.to_string().as_str() {
                                                                "start" => start = a.value.to_string().parse::<usize>().unwrap(),
                                                                "end" => end = a.value.to_string().parse::<usize>().unwrap(),
                                                                "loNote" => region.low_note = a.value.to_string().parse::<u32>().unwrap(),
                                                                "hiNote" => region.high_note = a.value.to_string().parse::<u32>().unwrap(),
                                                                "loVel" => region.low_velocity = a.value.to_string().parse::<u32>().unwrap() as f32 / 127.0,
                                                                "hiVel" => region.high_velocity = a.value.to_string().parse::<u32>().unwrap() as f32 / 127.0,
                                                                "rootNote" => root_note = a.value.to_string().parse::<u32>().unwrap(),
                                                                "seqPosition" => (),
                                                                "tuning" => (),
                                                                "volume" => (),
                                                                "pan" => (),
                                                                "loopEnabled" => (),
                                                                "loopStart" => (),
                                                                "loopEnd" => (),
                                                                "loopCrossfade" => (),
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
                                                                let mut sample = SampleFile::load(&sample_path).unwrap();
                                                                sample.pitch = Some(num_to_pitch(root_note));

                                                                if start != 0 {
                                                                    sample.start = start;
                                                                }

                                                                if end != 0 {
                                                                    sample.end = end;
                                                                }

                                                                // println!("Adding sample to existing region");
                                                                found = true;
                                                                r.sounds.push(sample);
                                                            }
                                                        }

                                                        if !found {
                                                            let mut sample = SampleFile::load(&sample_path).unwrap();
                                                            sample.pitch = Some(num_to_pitch(root_note));
                                                            println!("Set num to {}", root_note);

                                                            if start != 0 {
                                                                sample.start = start;
                                                            }

                                                            if end != 0 {
                                                                sample.end = end;
                                                            }
                                                            // println!("Adding sample to new region");
                                                            region.sounds.push(sample);
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

    return regions;
}