use modules::*;

pub struct MidSideMerge;

impl Module for MidSideMerge {
    type Voice = ();

    const INFO: Info = Info {
        title: "M/S Merge",
        id: "default.audio.dynamics.mid_side_merge",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(150, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Mid", 15),
            Pin::Audio("Side", 45),
        ],
        outputs: &[
            Pin::Audio("Output", 30),
        ],
        path: &["Audio", "Dynamics", "Mid-Side Merge"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (50, 25),
            size: (40, 40),
            child: Icon {
                path: "operations/multiply.svg",
                color: Color::BLUE,
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
		let (input1, input2) = if let [inputs0, inputs1, ..] = inputs.audio.channels.as_slice() {
	        (inputs0.as_slice(), inputs1.as_slice())
		} else {
			panic!("wrong number of inputs");
		};

        for ((in1, in2), out) in input1.iter().zip(input2).zip(outputs.audio[0].as_slice_mut().iter_mut()) {
            out.left = in1.mono() + in2.mono();
            out.right = in1.mono() - in2.mono();
        }
    }
}
