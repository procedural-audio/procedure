use tonevision_types::*;

static mut POINTS: [(f32, f32); 40] = [(0.0, 0.0); 40];

pub struct Bend {
    value: f32,
    exp: f32,
}

impl Module for Bend {
    type Voice = ();

    const INFO: Info = Info {
        name: "Bend",
        features: &[],
        color: Color::RED,
        size: Size::Static(240, 160),
        voicing: Voicing::Monophonic,
        vars: &[],
        inputs: &[
            Pin::Control("Control Input", 20),
            Pin::Control("Bend Amount", 50),
        ],
        outputs: &[
            Pin::Control("Control Output", 20)
        ],
    };

    fn new() -> Self {
        Self {
            value: 0.0,
            exp: 1.0,
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        println!("Building stuff");
        return Box::new(Stack {
            children: (
                Transform {
                    position: (40, 40),
                    size: (100, 60),
                    child: Painter {
                        painter: Box::new(|canvas| {
                            let mut paint = Paint::new();

                            paint.set_color(Color::RED);
                            paint.set_width(2.0);

                            unsafe {
                                for i in 0..40 {
                                    let x = (i as f32) / 40.0;
                                    let y = f32::powf(x, self.exp);

                                    POINTS[i] = (x * 50.0 + 50.0, y * 30.0 + 30.0);
                                }

                                canvas.draw_points(&POINTS, paint);
                            }
                        }),
                    },
                },
                Transform {
                    position: (40 + 70 + 40, 40),
                    size: (60, 70),
                    child: Knob {
                        text: "Bend",
                        color: Color::RED,
                        value: &mut self.value,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
            ),
        });
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _vars: &Vars, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let x = inputs.control[0].get();

        if self.value > 0.5 {
            self.exp = self.value * 10.0 - 5.0;
        } else {
            self.exp = 1.0 / (self.value * 10.0);
        }

        let y = f32::powf(x, self.exp);

        outputs.control[0].set(y);
    }
}
