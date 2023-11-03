pub trait ModuleNew {
    type Voice;

    type Stream;

    fn new() -> Self;
    fn new_voice(&self, index: usize) -> Self::Voice;

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: f64);

    fn on_event(&mut self);
    fn process(&mut self, voice: &mut Self::Voice, stream: Self::Stream);
}

pub struct NewModule;

impl ModuleNew for NewModule {
    type Voice = ();
    type Stream = (f32, f32, f32);

    fn new() -> Self {
        NewModule
    }

    fn new_voice(&self, index: usize) -> Self::Voice {
        ()
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: f64) {
        println!("Prepare stuff")
    }

    fn on_event(&mut self) {
        
    }

    fn process(&mut self, voice: &mut Self::Voice, stream: Self::Stream) {

    }
}
