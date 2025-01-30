use cmajor::*;
use cmajor::performer::*;
use endpoints::stream::StreamType;
use value::ValueRef;

use cmajor::performer::endpoints::value::{GetOutputValue, SetInputValue};

use flutter_rust_bridge::*;

#[frb(ignore)]
pub enum Voices {
    Mono(Performer),
    Poly(Vec<Performer>)
}

impl Voices {
    pub fn advance(&mut self) {
        match self {
            Voices::Mono(performer) => {
                performer.advance();
            },
            Voices::Poly(performers) => {
                for performer in performers {
                    performer.advance();
                }
            }
        }
    }

    pub fn set_block_size(&mut self, frames: usize) {
        match self {
            Voices::Mono(performer) => {
                performer.set_block_size(frames as u32);
            },
            Voices::Poly(performers) => {
                for performer in performers {
                    performer.set_block_size(frames as u32);
                }
            }
        }
    }

    pub fn read<T: StreamType>(&self, endpoint: Endpoint<OutputStream<T>>, buffer: &mut [T]) {
        match self {
            Voices::Mono(performer) => {
                performer.read(endpoint, buffer);
            },
            Voices::Poly(performers) => {
                todo!()
            }
        }
    }

    pub fn write<T: StreamType>(&mut self, endpoint: Endpoint<InputStream<T>>, buffer: &[T]) {
        match self {
            Voices::Mono(performer) => {
                performer.write(endpoint, buffer);
            },
            Voices::Poly(performers) => {
                for performer in performers {
                    performer.write(endpoint, buffer);
                }
            }
        }
    }

    pub fn get<T: GetOutputValue>(&mut self, endpoint: Endpoint<OutputValue<T>>) -> T::Output<'_> {
        match self {
            Voices::Mono(performer) => {
                performer.get(endpoint)
            },
            Voices::Poly(performers) => {
                todo!()
            }
        }
    }

    pub fn set<T: SetInputValue + Copy>(&mut self, endpoint: Endpoint<InputValue<T>>, value: T) {
        match self {
            Voices::Mono(performer) => {
                performer.set(endpoint, value);
            },
            Voices::Poly(performers) => {
                for performer in performers {
                    performer.set(endpoint, value);
                }
            }
        }
    }

    pub fn post<'a>(&mut self, endpoint: Endpoint<InputEvent>, event: impl Into<ValueRef<'a>>) -> Result<(), EndpointError> {
        match self {
            Voices::Mono(performer) => {
                performer.post(endpoint, event)
            },
            Voices::Poly(performers) => {
                todo!()
            }
        }
    }

    pub fn fetch(&mut self, endpoint: Endpoint<OutputEvent>, callback: impl FnMut(usize, ValueRef<'_>)) -> Result<(), EndpointError> {
        match self {
            Voices::Mono(performer) => {
                performer.fetch(endpoint, callback)
            },
            Voices::Poly(performers) => {
                todo!()
            }
        }
    }

    pub fn copy_streams_to<T: StreamType>(&self, src_endpoint: Endpoint<OutputStream<T>>, dst_voices: &mut Self, dst_endpoint: Endpoint<InputStream<T>>, buffer: &mut [T]) {
        match (self, dst_voices) {
            (Voices::Mono(src_voice), Voices::Mono(dst_voice)) => {
                src_voice.read(src_endpoint, buffer);
                dst_voice.write(dst_endpoint, buffer);
            },
            (Voices::Poly(src_voices), Voices::Poly(dst_voices)) => {
                for (src_voice, dst_voice) in src_voices.iter().zip(dst_voices.iter_mut()) {
                    src_voice.read(src_endpoint, buffer);
                    dst_voice.write(dst_endpoint, buffer);
                }
            },
            _ => todo!()
        }
    }

    pub fn convert_copy_streams_to<A, B>(
        &self,
        src_endpoint: Endpoint<OutputStream<A>>,
        src_buffer: &mut [A],
        dst_voices: &mut Self,
        dst_endpoint: Endpoint<InputStream<B>>,
        dst_buffer: &mut [B])
            where
                A: StreamType + ConvertTo<B>, B: StreamType {

        match (self, dst_voices) {
            (Voices::Mono(src_voice), Voices::Mono(dst_voice)) => {
                // Read the source samples
                src_voice.read(src_endpoint, src_buffer);

                // Convert the samples between the buffers
                for (s, d) in src_buffer.iter().zip(dst_buffer.iter_mut()) {
                    *d = s.convert_to();
                }

                // Write the converted samples
                dst_voice.write(dst_endpoint, dst_buffer);
            },
            (Voices::Poly(src_voices), Voices::Poly(dst_voices)) => {
                for (src_voice, dst_voice) in src_voices.iter().zip(dst_voices.iter_mut()) {
                    // Read the source samples
                    src_voice.read(src_endpoint, src_buffer);

                    // Convert the samples between the buffers
                    for (s, d) in src_buffer.iter().zip(dst_buffer.iter_mut()) {
                        *d = s.convert_to();
                    }

                    // Write the converted samples
                    dst_voice.write(dst_endpoint, dst_buffer);
                }
            },
            _ => todo!()
        }
    }

    pub fn copy_values_to<T>(&mut self, src_endpoint: Endpoint<OutputValue<T>>, dst_voices: &mut Self, dst_endpoint: Endpoint<InputValue<T>>) 
        where
            T: Copy + SetInputValue + for<'a> GetOutputValue<Output<'a> = T> {

        match (self, dst_voices) {
            (Voices::Mono(src_voice), Voices::Mono(dst_voice)) => {
                let value = src_voice.get(src_endpoint);
                dst_voice.set(dst_endpoint, value);
            },
            (Voices::Poly(src_voices), Voices::Poly(dst_voices)) => {
                for (src_voice, dst_voice) in src_voices.iter_mut().zip(dst_voices.iter_mut()) {
                    let value = src_voice.get(src_endpoint);
                    dst_voice.set(dst_endpoint, value);
                }
            },
            _ => todo!()
        }
    }

    pub fn copy_events_to(&mut self, src_endpoint: Endpoint<OutputEvent>, dst_voices: &mut Self, dst_endpoint: Endpoint<InputEvent>) {
        match (self, dst_voices) {
            (Voices::Mono(src_voice), Voices::Mono(dst_voice)) => {
                src_voice.fetch(src_endpoint, |_, event| {
                    dst_voice.post(dst_endpoint, event).unwrap();
                }).unwrap();
            },
            (Voices::Poly(src_voices), Voices::Poly(dst_voices)) => {
                for (src_voice, dst_voice) in src_voices.iter_mut().zip(dst_voices.iter_mut()) {
                    src_voice.fetch(src_endpoint, |_, event| {
                        dst_voice.post(dst_endpoint, event).unwrap();
                    }).unwrap();
                }
            },
            _ => todo!()
        }
    }
}

pub trait ConvertTo<T> {
    fn convert_to(&self) -> T;
}

// Convert mono samples to stereo
impl<T: Copy> ConvertTo<[T; 2]> for T {
    fn convert_to(&self) -> [T; 2] {
        [*self, *self]
    }
}

// Convert stereo samples to mono
impl<T: std::ops::Add<Output = T> + Copy> ConvertTo<T> for [T; 2] {
    fn convert_to(&self) -> T {
        self[0] + self[1]
    }
}