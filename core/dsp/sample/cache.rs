use std::sync::RwLock;

use crate::sample::sample::*;

//use crate::AudioChannel;
//use crate::AudioChannels;
use crate::buffers::*;

use hound::Sample;
use lazy_static::*;

lazy_static! {
    static ref SAMPLE_CACHE_STEREO: RwLock<Vec<(String, Arc<Buffer<Stereo2>>)>> = RwLock::new(Vec::new());
}

use std::sync::Arc;

pub trait FileLoad<T> {
    fn load(path: &str) -> T {
        panic!("File loader note implemented");
    }
}

impl FileLoad<SampleFile<Stereo2>> for SampleFile<Stereo2> {
    fn load(path: &str) -> SampleFile<Stereo2> {
        /* Load sample from cache */

        for (p, buffer) in &*SAMPLE_CACHE_STEREO.read().unwrap() {
            if p.as_str() == path {
                return SampleFile::from(buffer.clone(), 440.0, 44100, path.to_string());
            }
        }

        /* Load sample from files asynchronously */

        println!("Loading {}", path);

        // let buffer = Arc::new(AudioBuffer::new(0));
        // let buffer_ret = buffer.clone();

        let mut reader = hound::WavReader::open(path.to_string()).unwrap();
        let sample_rate = reader.spec().sample_rate;

        // let _handle = std::thread::spawn(move || {
        {
            let size = reader.samples::<i16>().len();
            println!("Size is {}", size);
            let mut buffer_new = StereoBuffer::init(Stereo2 { left: 0.0, right: 0.0 }, size);

            let mut i = 0;
            reader.samples::<i16>()
                .fold(0.0, |_, v| {
                    let sample = v.unwrap() as f32 * (1.0/32768.0);
                    buffer_new.as_slice_mut()[i].left = sample;
                    buffer_new.as_slice_mut()[i].right = sample;
                    i += 1;
                    0.0
                }
            );

            println!("Should set sample here");

            return SampleFile::from(Arc::new(buffer_new), 440.0, sample_rate, path.to_string());
        }

            //println!("Loaded sample {}", path);
        // });

        /*let spec = reader.spec();
        let size = reader.samples::<i16>().len();
        let mut buffer_new = StereoBuffer::with_capacity(size / spec.channels as usize);
        // ^^^ SIZE OF SINGLE CHANNEL

        println!("{:?}", spec);

        match spec.bits_per_sample {
            16 => {
                let mut i = 0;
                reader.samples::<i16>().for_each(|s| {
                    unsafe {
                        let sample = s.unwrap() as f32 * (1.0 / 32768.0);
                        if i % 2 == 0 {
                            *buffer_new
                                .left
                                .as_mut_ptr()
                                .offset(i / spec.channels as isize) = sample;
                        } else {
                            *buffer_new
                                .right
                                .as_mut_ptr()
                                .offset(i / spec.channels as isize) = sample;
                        }
                        // ^^^ Takes only left channel
                        i += 1;
                    }
                });
            }
            24 => {
                let mut i = 0;
                reader.samples::<i32>().for_each(|s| {
                    unsafe {
                        let sample = s.unwrap() as f32 * (1.0 / 32768.0);
                        *buffer_new.left.as_mut_ptr().offset(i / spec.channels as isize) = sample;
                        // ^^^ Takes only left channel
                        i += 1;
                    }
                });
            }
            _ => {
                panic!("Unsupported wave file bit width");
            }
        }

        /*println!("    {:?}", &buffer_new.as_slice()[64+4*0..64+4*1]);
        println!("    {:?}", &buffer_new.as_slice()[64+4*1..64+4*2]);
        println!("    {:?}", &buffer_new.as_slice()[64+4*2..64+4*3]);
        println!("    {:?}", &buffer_new.as_slice()[64+4*3..64+4*4]);*/

        let seconds = size as f64 / spec.sample_rate as f64;
        println!(
            "    rate: {}, format: {:?}, bits: {}, channels: {}",
            spec.sample_rate, spec.sample_format, spec.bits_per_sample, spec.channels
        );
        /*println!(
            "    rms: {}, peak: {}",
            &buffer_new.rms(),
            &buffer_new.peak()
        );*/
        println!("    length: {} seconds", seconds / spec.channels as f64);
        println!("");

        // println!("Converting {} to 44100", reader.spec().sample_rate);
        // let buffer_new = samplerate::convert(reader.spec().sample_rate, 44100, 1, samplerate::ConverterType::SincFastest, buffer_new.as_slice()).unwrap();
        // let buffer_new = AudioBuffer::from(buffer_new);

        return Sample::from(Arc::new(buffer_new), 440.0, sample_rate, path.to_string());*/
    }
}