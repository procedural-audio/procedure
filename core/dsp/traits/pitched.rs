pub trait Pitched {
    fn get_pitch(&self) -> f32;
    fn set_pitch(&mut self, hz: f32);
}
