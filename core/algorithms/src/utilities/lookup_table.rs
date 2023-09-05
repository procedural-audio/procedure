use pa_dsp::*;

// pass in a std::ops::Range<T> type???

pub const fn lookup_table<F: Float, const C: usize>() -> LookupTable<F, C> {
    LookupTable::from()
}

pub struct LookupTable<F: Float, const C: usize> {
    table: [(f32, F); C]
}

impl<F: Float, const C: usize> LookupTable<F, C> {
    pub const fn from() -> Self {
        LookupTable {
            table: [(0.0, F::ZERO); C]
        }
    }
}