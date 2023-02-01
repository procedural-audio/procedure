use crate::widget::Color;

pub trait IntoColor {
    fn into_color(&self) -> Color;
    fn animated(&self) -> bool;
}

impl IntoColor for crate::Color {
    fn into_color(&self) -> Color {
        *self
    }

    fn animated(&self) -> bool {
        false
    }
}

impl<'a> IntoColor for &'a Color {
    fn into_color(&self) -> Color {
        **self
    }

    fn animated(&self) -> bool {
        true
    }
}
