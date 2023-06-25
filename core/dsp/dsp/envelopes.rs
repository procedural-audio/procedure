use crate::traits::*;

/* ========== ADSR ========== */

pub struct ADSR<T: Generator> {
    src: T,
    attack: f32,
    decay: f32,
    sustain: f32,
    release: f32,
}

/* ========== Complex Envelope ========== */

pub struct ComplexEnvelope {}

pub enum ComplexEnvelopeFunction {}
