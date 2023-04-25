use crate::widget::Color;

pub trait IntoColor {
    fn into_color(&self) -> Color;
}

impl IntoColor for Color {
    fn into_color(&self) -> Color {
        *self
    }
}

impl<'a> IntoColor for &'a Color {
    fn into_color(&self) -> Color {
        **self
    }
}

impl<F: Fn() -> Color> IntoColor for F {
    fn into_color(&self) -> Color {
        self()
    }
}
