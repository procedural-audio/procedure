use crate::*;

pub struct LevelMeter {
    left: f32,
    right: f32,
}

impl Module for LevelMeter {
    type Voice = ();

    const INFO: Info = Info {
        title: "Level",
        version: "0.0.0",
        color: Color::GREEN,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        inputs: &[Pin::Audio("Audio Input", 25)],
        outputs: &[Pin::Control("RMS", 25)],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        Self {
            left: 0.5,
            right: 0.5,
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: _LevelMeter {
                left: &mut self.left,
                right: &mut self.right,
                color_1: Color::BLUE,
                color_2: Color::PURPLE,
            },
        })
    }

    fn build_ui<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(_LevelMeter {
            left: &mut self.left,
            right: &mut self.right,
            color_1: Color::BLUE,
            color_2: Color::PURPLE,
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, _outputs: &mut IO) {
        /* Left */

        let mut sum = 0.0;

        for v in &inputs.audio[0].left {
            sum += (*v).powf(2.0);
        }

        let avg = sum / inputs.audio[0].left.capacity() as f32;
        let rms = f32::sqrt(avg);

        self.left = rms;

        /* Right */

        let mut sum = 0.0;

        for v in &inputs.audio[0].right {
            sum += (*v).powf(2.0);
        }

        let avg = sum / inputs.audio[0].left.capacity() as f32;
        let rms = f32::sqrt(avg);

        self.right = rms;
    }
}

#[repr(C)]
pub struct _LevelMeter<'a> {
    pub left: &'a mut f32,
    pub right: &'a mut f32,
    pub color_1: Color,
    pub color_2: Color,
}

impl<'a> WidgetNew for _LevelMeter<'a> {
    fn get_name(&self) -> &'static str {
        "LevelMeter"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_level_meter_get_color_1(knob: &mut _LevelMeter) -> u32 {
    knob.color_1.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_level_meter_get_color_2(knob: &mut _LevelMeter) -> u32 {
    knob.color_2.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_level_meter_get_left(knob: &mut _LevelMeter) -> f32 {
    *knob.left = *knob.left + 0.1;

    if *knob.left >= 1.0 {
        *knob.left = 0.0;
    }

    *knob.left
}

#[no_mangle]
pub unsafe extern "C" fn ffi_level_meter_get_right(knob: &mut _LevelMeter) -> f32 {
    *knob.right
}
