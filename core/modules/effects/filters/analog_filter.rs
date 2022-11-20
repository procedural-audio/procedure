use crate::*;

use pa_dsp::*;

pub struct AnalogFilter {
    selected: u32,
    cutoff: f32,
    resonance: f32,
}

pub struct AnalogFilterVoice {
    /*korg: Korg35LPF,
    diode: DiodeLPF,
    oberheim: OberheimLPF,
    ladder: LadderLPF,
    half_ladder: HalfLadderLPF,
    moog: MoogLPF,
    sallen_key: SallenKeyLPF,*/
}

impl Module for AnalogFilter {
    type Voice = AnalogFilterVoice;

    const INFO: Info = Info {
        name: "Analog Filter",
        color: Color::BLUE,
        size: Size::Static(200, 170),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 20),
            Pin::Control("Control Input", 50),
            Pin::Control("Control Input", 80),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 20)
        ],
    };

    
    fn new() -> Self {
        Self {
            selected: 0,
            cutoff: 10000.0,
            resonance: 0.0,
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        Self::Voice {
            /*korg: Korg35LPF::new(),
            diode: DiodeLPF::new(),
            oberheim: OberheimLPF::new(),
            ladder: LadderLPF::new(),
            half_ladder: HalfLadderLPF::new(),
            moog: MoogLPF::new(),
            sallen_key: SallenKeyLPF::new(),*/
        }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        return Box::new(Stack {
            children: (
                Transform {
                    position: (50, 40 + 70),
                    size: (100, 40),
                    child: Dropdown {
                        index: &mut self.selected,
                        color: Color::BLUE,
                        elements: &[
                            "Korg 35",
                            "Diode",
                            "Oberheim",
                            "Ladder",
                            "Half Ladder",
                            "Moog",
                            "Sallen Key",
                        ],
                    },
                },
                Transform {
                    position: (40, 40),
                    size: (60, 70),
                    child: Knob {
                        text: "Cutoff", // Cutoff
                        color: Color::BLUE,
                        value: &mut self.cutoff,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (40 + 70, 40),
                    size: (60, 70),
                    child: Knob {
                        text: "Res", // Resonance
                        color: Color::BLUE,
                        value: &mut self.resonance,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
            ),
        });
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        /*voice.korg.prepare(sample_rate, block_size);
        voice.diode.prepare(sample_rate, block_size);
        voice.oberheim.prepare(sample_rate, block_size);
        voice.ladder.prepare(sample_rate, block_size);
        voice.half_ladder.prepare(sample_rate, block_size);
        voice.moog.prepare(sample_rate, block_size);
        voice.sallen_key.prepare(sample_rate, block_size);*/
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let input = inputs.audio[0].as_array();
        let mut output = outputs.audio[0].as_array_mut();

        /*match self.selected {
            0 => {
                voice.korg.set_param(0, self.cutoff);
                voice.korg.set_param(1, self.resonance);
                voice.korg.process(&input, &mut output);
            }
            1 => {
                voice.diode.set_param(0, self.cutoff);
                voice.diode.set_param(1, self.resonance);
                voice.diode.process(&input, &mut output);
            }
            2 => {
                voice.oberheim.set_param(0, self.cutoff);
                voice.oberheim.set_param(1, self.resonance);
                voice.oberheim.process(&input, &mut output);
            }
            3 => {
                voice.ladder.set_param(0, self.cutoff);
                voice.ladder.set_param(1, self.resonance);
                voice.ladder.process(&input, &mut output);
            }
            4 => {
                voice.half_ladder.set_param(0, self.cutoff);
                voice.half_ladder.set_param(1, self.resonance);
                voice.half_ladder.process(&input, &mut output);
            }
            5 => {
                voice.moog.set_param(0, self.cutoff);
                voice.moog.set_param(1, self.resonance);
                voice.moog.process(&input, &mut output);
            }
            6 => {
                voice.sallen_key.set_param(0, self.cutoff);
                voice.sallen_key.set_param(1, self.resonance);
                voice.sallen_key.process(&input, &mut output);
            }
            _ => panic!("Dropdown value out of range"),
        }*/
    }
}

/*faust!(Korg35LPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0,10,0.01);
    process = _,_ : ve.korg35LPF(freq, res), ve.korg35LPF(freq, res);
);

faust!(DiodeLPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0.5,10,0.01);
    process = _,_ : ve.diodeLadder(freq, res), ve.diodeLadder(freq, res);
);

faust!(OberheimLPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0.5,10,0.01);
    process = _,_ : ve.oberheimLPF(freq, res), ve.oberheimLPF(freq, res);
);

faust!(LadderLPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0.5,10,0.01);
    process = _,_ : ve.moogLadder(freq * 0.8, res), ve.moogLadder(freq * 0.8, res);
);

faust!(HalfLadderLPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0.5,10,0.01);
    process = _,_ : ve.moogHalfLadder(freq, res), ve.moogHalfLadder(freq, res);
);

faust!(MoogLPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0.5,10,0.01);
    process = _,_ : ve.moog_vcf(res, freq), ve.moog_vcf(res, freq);
);

faust!(SallenKeyLPF,
    freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
    res = hslider("res",1,0.5,10,0.01);
    process = _,_ : ve.sallenKeyOnePoleLPF(freq), ve.sallenKeyOnePoleLPF(freq);
);*/