use modules::*;

pub struct GetVelocity;

impl Module for GetVelocity {
    type Voice = f32;

    const INFO: Info = Info {
        title: "Vel",
        id: "default.sequencing.get_velocity",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(90, 35),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 10),
        ],
        outputs: &[
            Pin::Control("Velocity (hz)", 10)
        ],
        path: &["Notes", "Effects", "Get Velocity"],
        presets: Presets::NONE
    };
    
    fn new() -> Self {
        Self
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        0.0
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 20),
            size: (40, 40),
            child: Icon {
                path: "comparisons/equals.svg",
                color: Color::GREEN,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch: _, pressure } => {
                    *voice = pressure;
                },
                Event::Pressure(velocity) => {
                    *voice = velocity;
                },
                _ => ()
            }
        }

        outputs.control[0] = *voice;
    }
}
