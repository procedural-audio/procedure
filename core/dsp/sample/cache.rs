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

        let mut reader = hound::WavReader::open(path.to_string()).unwrap();
        let spec = reader.spec();
        let sample_rate = reader.spec().sample_rate;

        {
            let size = reader.samples::<i16>().len();
            println!("Size is {}", size);
            let mut buffer_new = StereoBuffer::init(Stereo2 { left: 0.0, right: 0.0 }, size / 2);

            let mut i = 0;
            reader.samples::<i16>()
                .fold(0.0, |_, v| {
                    let sample = v.unwrap() as f32 * (1.0/32768.0);
                    if i % 2 == 0 {
                        buffer_new.as_slice_mut()[i / spec.channels as usize].left = sample;
                    } else {
                        buffer_new.as_slice_mut()[i / spec.channels as usize].right = sample;
                    }

                    i += 1;
                    0.0
                }
            );

            println!("Should set sample here");

            return SampleFile::from(Arc::new(buffer_new), 440.0, sample_rate, path.to_string());
        }
    }
}