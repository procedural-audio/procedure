pub trait Interpolator {
    // fn interpolate(&self, sample_offset: f32) -> f32;
}

#[inline(always)]
fn hermite_interpolation(v0: f32, v1: f32, v2: f32, v3: f32, sample_offset: f32) -> f32 {
    let slope0 = (v2 - v0) * 0.5;
    let slope1 = (v3 - v1) * 0.5;
    let v = v1 - v2;
    let w = slope0 + v;
    let a = w + v + slope1;
    let b_neg = w + a;
    let stage1 = a * sample_offset - b_neg;
    let stage2 = stage1 * sample_offset + slope0;
    let result = stage2 * sample_offset + v1;

    return result;
}
