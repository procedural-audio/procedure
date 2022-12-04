use crate::*;

pub struct Chorus {
    level: f32,
    freq: f32,
    delay: f32,
    depth: f32,
}

impl Module for Chorus {
    type Voice = (); // ChorusDsp;

    const INFO: Info = Info {
        title: "Chorus",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(310 - 40 - 70, 200),
        voicing: Voicing::Monophonic,
        inputs: &[Pin::Audio("Audio Input", 20), Pin::Control("Control 1", 50)],
        outputs: &[Pin::Audio("Audio Output", 20)],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        Chorus {
            level: 0.5,
            freq: 0.5,
            delay: 0.5,
            depth: 0.5,
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        () // ChorusDsp::new()
    }

    fn load(&mut self, _json: &JSON) {
        // Should use generics like serde
    }

    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        let _size = 50;

        return Box::new(Stack {
            children: (
                Transform {
                    position: (40 + 70 * 0, 40 + 80 * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Level",
                        color: Color::BLUE,
                        value: &mut self.level,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70 * 1, 40 + 80 * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "Freq",
                        color: Color::BLUE,
                        value: &mut self.freq,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70 * 1, 40 + 80 * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Delay",
                        color: Color::BLUE,
                        value: &mut self.delay,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70 * 0, 40 + 80 * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "Depth",
                        color: Color::BLUE,
                        value: &mut self.depth,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
            ),
        });
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        // voice.prepare(sample_rate, block_size);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        /*voice.process(
            &inputs.audio[0].as_array(),
            &mut outputs.audio[0].as_array_mut(),
        );*/
    }
}

/*faust!(ChorusDsp,
    import("music.lib");

    level	= hslider("level", 0.5, 0, 1, 0.01);
    freq	= hslider("freq", 2, 0, 10, 0.01);
    dtime	= hslider("delay", 0.025, 0, 0.2, 0.001);
    depth	= hslider("depth", 0.02, 0, 1, 0.001);

    tblosc(n,f,freq,mod)	= (1-d)*rdtable(n,wave,i&(n-1)) +
                d*rdtable(n,wave,(i+1)&(n-1))
    with {
        wave	 	= time*(2.0*PI)/n : f;
        phase		= freq/SR : (+ : decimal) ~ _;
        modphase	= decimal(phase+mod/(2*PI))*n;
        i		= int(floor(modphase));
        d		= decimal(modphase);
    };

    chorus(d,freq,depth)	= fdelay(1<<16, t)
    with {	t		= SR*d/2*(1+depth*tblosc(1<<16, sin, freq, 0)); };

    process			= vgroup("chorus", (c, c))
    with { c(x) = x+level*chorus(dtime,freq,depth,x); };
);*/
