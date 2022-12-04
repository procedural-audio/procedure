use crate::*;

/// Produces quantized impulses as a function of time. For non quantized impulses that aren't a function of time, use the LFO.
pub struct Clock {
    value: f32,
}

impl Module for Clock {
    type Voice = ();

    const INFO: Info = Info {
        title: Title("Clock", Color::RED),
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Control("Rate (0-1)", 25),
            Pin::Time("Time", 55)
        ],
        outputs: &[
            Pin::Control("Clock Pulses", 25)
        ],
    };
    
    fn new() -> Self {
        Self { value: 0.0 }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Rate",
                color: Color::RED,
                value: &mut self.value,
                feedback: Box::new(|v| rate_to_str(linear_to_rate_quantized(v))),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let rate = linear_to_rate_quantized(self.value) as f64;

        outputs.control[0] = 0.0;

        inputs.time[0].on_each(rate, | _ | {
            outputs.control[0] = 1.0;
        });
    }
}

fn linear_to_rate_quantized(v: f32) -> f32 {
    let v = f32::clamp(v, 0.0, 1.0);
    let v = v - 0.05;

    if v <= 0.0 {
        1.0 / 32.0
    } else if v > 0.0 && v < 0.1 {
        1.0 / 16.0
    } else if v > 0.1 && v <= 0.2 {
        1.0 / 8.0
    } else if v > 0.2 && v <= 0.3 {
        1.0 / 4.0
    } else if v > 0.3 && v <= 0.4 {
        1.0 / 2.0
    } else if v > 0.4 && v <= 0.5 {
        1.0
    } else if v > 0.5 && v <= 0.6 {
        2.0
    } else if v > 0.6 && v <= 0.7 {
        4.0
    } else if v > 0.7 && v <= 0.8 {
        8.0
    } else if v > 0.8 && v <= 0.9 {
        16.0
    } else if v > 0.9 {
        32.0
    } else {
        panic!("Unsupported rate");
    }
}

fn rate_to_str(v: f32) -> String {
    if v == 1.0 / 64.0 {
        String::from("1 / 64")
    } else if v == 1.0 / 32.0 {
        String::from("1 / 32")
    } else if v == 1.0 / 16.0 {
        String::from("1 / 16")
    } else if v == 1.0 / 8.0 {
        String::from("1 / 8")
    } else if v == 1.0 / 4.0 {
        String::from("1 / 4")
    } else if v == 1.0 / 2.0 {
        String::from("1 / 2")
    } else {
        format!("{}", f32::round(v) as u32)
    }
}
