use crate::modules::*;

use crate::dsp::filter::*;

pub struct DigitalFilter {
    low_pass_6: LowPass6,
    low_pass_12: LowPass12,
    low_pass_24: LowPass24,
    high_pass_6: HighPass6,
    high_pass_12: HighPass12,
    high_pass_24: HighPass24,
}

pub struct DigitalFilterState {
    slope: u32,
    low: bool,
}

type ModuleState<'a> = MState<'a, DigitalFilter>;

impl Module for DigitalFilter {
    type Widgets = (Box<SVGButton>, Box<SVGButton>, Box<TextButton>, Box<TextButton>, Box<TextButton>, Box<Knob>);
    type FrontendWidgets = ();
    type SharedState = DigitalFilterState;

    const INFO: ModuleInfo = ModuleInfo {
        name: "Digital Filter",
                color: Color::BLUE,
        size: Size::Static(315-60, 200-70),
        voicing: Voicing::Polyphonic,
        params: &[],
inputs: &[
            IO::Audio(10, 20),
            IO::Control(10, 50),
        ],
        outputs: &[
            IO::Audio(230, 20),
        ],
    };

    fn new() -> Self {
        Self {
            low_pass_6: LowPass6::new(),
            low_pass_12: LowPass12::new(),
            low_pass_24: LowPass24::new(),
            high_pass_6: HighPass6::new(),
            high_pass_12: HighPass12::new(),
            high_pass_24: HighPass24::new(),
        }
    }

    fn init_state() -> Self::SharedState {
        DigitalFilterState {
            slope: 6,
            low: true,
        }
    }

    fn init_gui() -> Self::Widgets {(
        SVGButton::new() // Low pass
            .init_position(40, 40-5)
            .init_size(50, 50)
            .init_pressed(true)
            .init_svg("square_wave.svg")
            .init_color(Color::BLUE),
        SVGButton::new() // High pass
            .init_position(40+50, 40-5)
            .init_size(50, 50)
            .init_pressed(false)
            .init_svg("square_wave.svg")
            .init_color(Color::BLUE),
        TextButton::new()
            .init_position(50+30*0, 40+50)
            .init_size(30, 30)
            .init_pressed(false)
            .init_text("6")
            .init_color(Color::BLUE),
        TextButton::new()
            .init_position(50+30*1, 40+50)
            .init_size(30, 30)
            .init_pressed(true)
            .init_text("12")
            .init_color(Color::BLUE),
        TextButton::new()
            .init_position(50+30*2, 40+50)
            .init_size(30, 30)
            .init_pressed(false)
            .init_text("24")
            .init_color(Color::BLUE),
        Knob::new()
            .init_position(160, 45)
            .init_size(50, 50)
            .init_value(0.0)
            .init_color(Color::BLUE)
            .init_label("Cutoff"),
    )}

    fn init_frontend() -> Self::FrontendWidgets {
        ()
    }

    fn load(state: ModuleState, state2: &State, widgets: &mut Self::Widgets) {

    }

    fn save(state: ModuleState, state2: &mut State, widgets: &Self::Widgets) {

    }

    fn update(state: ModuleState, (low, high, filter6, filter12, filter24, cutoff): &mut Self::Widgets, voice: usize) {
        if voice == 0 {
            if low.updated() && low.pressed() {
                if high.pressed() { high.set_pressed(false); high.refresh(); }
            }

            if high.updated() && high.pressed() {
                if low.pressed() { low.set_pressed(false); low.refresh(); }
            }

            if filter6.updated() && filter6.get_pressed() {
                if filter12.get_pressed() { filter12.set_pressed(false); filter12.refresh(); }
                if filter24.get_pressed() { filter24.set_pressed(false); filter24.refresh(); }
            }

            if filter12.updated() && filter12.get_pressed() {
                if filter6.get_pressed() { filter6.set_pressed(false); filter6.refresh(); }
                if filter24.get_pressed() { filter24.set_pressed(false); filter24.refresh(); }
            }

            if filter24.updated() && filter24.get_pressed() {
                if filter6.get_pressed() { filter6.set_pressed(false); filter6.refresh(); }
                if filter12.get_pressed() { filter12.set_pressed(false); filter12.refresh(); }
            }

            state.shared.low = low.pressed();

            if filter6.get_pressed() {
                state.shared.slope = 6;
            } else if filter12.get_pressed() {
                state.shared.slope = 12;
            } else if filter24.get_pressed() {
                state.shared.slope = 24;
            }
        }

        if cutoff.updated(){
            let value = cutoff.get_value() * 10000.0 + 100.0;

            state.voice.low_pass_6.set_cutoff(value);
            state.voice.low_pass_12.set_cutoff(value);
            state.voice.low_pass_24.set_cutoff(value);

            state.voice.high_pass_6.set_cutoff(value);
            state.voice.high_pass_12.set_cutoff(value);
            state.voice.high_pass_24.set_cutoff(value);
        }
    }

    fn prepare(state: ModuleState, sample_rate: u32, block_size: usize) {
        state.voice.low_pass_6.prepare(sample_rate, block_size);
        state.voice.low_pass_12.prepare(sample_rate, block_size);
        state.voice.low_pass_24.prepare(sample_rate, block_size);
        state.voice.high_pass_6.prepare(sample_rate, block_size);
        state.voice.high_pass_12.prepare(sample_rate, block_size);
        state.voice.high_pass_24.prepare(sample_rate, block_size);
    }

    fn process(state: ModuleState, mut audio: Audio<Stereo>, _events: Notes, _control: Control) {
        if state.shared.low && state.shared.slope == 6 {
            state.voice.low_pass_6.process(&audio.inputs[0], &mut audio.outputs[0]);
        } else if state.shared.low && state.shared.slope == 12 {
            state.voice.low_pass_12.process(&audio.inputs[0], &mut audio.outputs[0]);
        } else if state.shared.low && state.shared.slope == 24 {
            state.voice.low_pass_24.process(&audio.inputs[0], &mut audio.outputs[0]);
        } else if !state.shared.low && state.shared.slope == 6 {
            state.voice.high_pass_6.process(&audio.inputs[0], &mut audio.outputs[0]);
        } else if !state.shared.low && state.shared.slope == 12 {
            state.voice.high_pass_12.process(&audio.inputs[0], &mut audio.outputs[0]);
        } else if !state.shared.low && state.shared.slope == 24 {
            state.voice.high_pass_24.process(&audio.inputs[0], &mut audio.outputs[0]);
        }
    }
}