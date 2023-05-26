use modules::*;

pub struct MidSideSplit;

impl Module for MidSideSplit {
    type Voice = ();

    const INFO: Info = Info {
        title: "M/S Split",
        id: "default.audio.dynamics.mid_side_split",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Input", 15),
        ],
        outputs: &[
            Pin::Audio("Mid", 15),
            Pin::Audio("Side", 45),
        ],
        path: &["Audio", "Dynamics", "Mid-Side Split"],
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
            position: (30, 25),
            size: (40, 40),
            child: Icon {
                path: "operations/divide.svg",
                color: Color::BLUE,
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
		let (output1, output2) = if let [outputs0, outputs1, ..] = outputs.audio.channels.as_mut_slice() {
	        (outputs0.as_slice_mut(), outputs1.as_slice_mut())
		} else {
			panic!("wrong number of outputs");
		};

        for ((out1, out2), inp) in output1.iter_mut().zip(output2).zip(inputs.audio[0].as_slice().iter()) {
            let mid = inp.left + inp.right;
            let side = inp.left - inp.right;

            out1.left = mid;
            out1.right = mid;
            out2.left = side;
            out2.right = side;
        }
    }
}
