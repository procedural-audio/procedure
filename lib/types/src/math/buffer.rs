use crate::math::float::*;

pub trait FloatBuffer {
    fn fill(&mut self, value: f32);
    fn delay(&mut self, _samples: usize);
    fn copy_from(&mut self, source: &Self)
    where
        Self: Sized;
    fn add_from(&mut self, source: &Self)
    where
        Self: Sized;
    fn zero(&mut self);
    fn gain(&mut self, decibals: f32);
}

/*pub trait FloatBuffer {
    fn as_ptr(&self) -> *mut f32;
    fn size(&self) -> usize;

    fn as_ref<'a>(&self) -> &'a [f32] {
        unsafe {
            slice::from_raw_parts(self.as_ptr() as *const _, self.size())
        }
    }

    fn as_mut(&mut self) -> &mut [f32] {
        unsafe {
            slice::from_raw_parts_mut(self.as_ptr(), self.size())
        }
    }


    fn fill(&mut self, value: f32) {
        for sample in self.as_mut() {
            *sample = value;
        }
    }

    fn delay(&mut self, _samples: usize) {
        todo!("Implement this");
    }

    fn copy_from(&mut self, source: &Self) where Self: Sized {
        if self.size() == source.size() {
            unsafe {
                libc::memcpy(
                    self.as_ptr() as *mut libc::c_void,
                    source.as_ptr() as *const libc::c_void,
                    self.size() * 4
                );
            }
        } else {
            panic!("Source and dest buffer sizes differ")
        }
    }

    fn add_from(&mut self, source: &Self) where Self: Sized {
        for (dest, source) in self.as_mut().into_iter().zip(source.as_ref()) {
            *dest += *source;
        }
    }
}*/

/*impl<T> Float for T where T: FloatBuffer {

    /* Basic Operations */

    fn zero(&mut self) {
        for sample in self.as_mut() {
            sample.zero();
        }
    }

    fn neg(&mut self) {
        for sample in self.as_mut() {
            sample.neg();
        }
    }

    fn add(&mut self, value: f32) {
        for sample in self.as_mut() {
            sample.add(value);
        }
    }

    fn sub(&mut self, value: f32) {
        for sample in self.as_mut() {
            sample.sub(value);
        }
    }

    fn mul(&mut self, value: f32) {
        for sample in self.as_mut() {
            sample.mul(value);
        }
    }

    fn div(&mut self, value: f32) {
        for sample in self.as_mut() {
            sample.div(value);
        }
    }

    /* Trigonometric Operations */

    fn sin(&mut self) {
        for sample in self.as_mut() {
            sample.sin();
        }
    }

    fn cos(&mut self) {
        for sample in self.as_mut() {
            sample.cos();
        }
    }

    fn tan(&mut self) {
        for sample in self.as_mut() {
            sample.tan();
        }
    }

    fn sinh(&mut self) {
        for sample in self.as_mut() {
            sample.sinh();
        }
    }

    fn cosh(&mut self) {
        for sample in self.as_mut() {
            sample.cosh();
        }
    }

    fn tanh(&mut self) {
        for sample in self.as_mut() {
            sample.tanh();
        }
    }

    /* Music Operations */

    fn bias(&mut self, decibals: f32) {
        for sample in self.as_mut() {
            sample.bias(decibals);
        }
    }

    fn gain(&mut self, decibals: f32) {
        for sample in self.as_mut() {
            sample.gain(decibals);
        }
    }
}*/

pub trait StereoFloatBuffer {
    fn left_as_ref<'a>(&self) -> &'a [f32];
    fn left_as_mut(&mut self) -> &mut [f32];
    fn right_as_ref<'a>(&self) -> &'a [f32];
    fn right_as_mut(&mut self) -> &mut [f32];
}

impl<T> StereoFloat for T
where
    T: StereoFloatBuffer,
{
    /* Basic Operations */

    fn zero(&mut self) {
        for sample in self.left_as_mut() {
            sample.zero();
        }

        for sample in self.right_as_mut() {
            sample.zero();
        }
    }

    fn add(&mut self, value: f32) {
        for sample in self.left_as_mut() {
            sample.add(value);
        }

        for sample in self.right_as_mut() {
            sample.add(value);
        }
    }

    fn sub(&mut self, value: f32) {
        for sample in self.left_as_mut() {
            sample.sub(value);
        }

        for sample in self.right_as_mut() {
            sample.sub(value);
        }
    }

    fn mul(&mut self, value: f32) {
        for sample in self.left_as_mut() {
            sample.mul(value);
        }

        for sample in self.right_as_mut() {
            sample.mul(value);
        }
    }

    fn div(&mut self, value: f32) {
        for sample in self.left_as_mut() {
            sample.div(value);
        }

        for sample in self.right_as_mut() {
            sample.div(value);
        }
    }

    /* Trigonometric Operations */

    fn sin(&mut self) {
        for sample in self.left_as_mut() {
            sample.sin();
        }

        for sample in self.right_as_mut() {
            sample.sin();
        }
    }

    fn cos(&mut self) {
        for sample in self.left_as_mut() {
            sample.cos();
        }

        for sample in self.right_as_mut() {
            sample.cos();
        }
    }

    fn tan(&mut self) {
        for sample in self.left_as_mut() {
            sample.tan();
        }

        for sample in self.right_as_mut() {
            sample.tan();
        }
    }

    fn sinh(&mut self) {
        for sample in self.left_as_mut() {
            sample.sinh();
        }

        for sample in self.right_as_mut() {
            sample.sinh();
        }
    }

    fn cosh(&mut self) {
        for sample in self.left_as_mut() {
            sample.cosh();
        }

        for sample in self.right_as_mut() {
            sample.cosh();
        }
    }

    fn tanh(&mut self) {
        for sample in self.left_as_mut() {
            sample.tanh();
        }

        for sample in self.right_as_mut() {
            sample.tanh();
        }
    }

    /* Music Operations */

    fn bias(&mut self, decibals: f32) {
        for sample in self.left_as_mut() {
            sample.bias(decibals);
        }

        for sample in self.right_as_mut() {
            sample.bias(decibals);
        }
    }

    fn gain(&mut self, decibals: f32) {
        for sample in self.left_as_mut() {
            sample.gain(decibals);
        }

        for sample in self.right_as_mut() {
            sample.gain(decibals);
        }
    }

    /* Stereo Operations */

    fn pan(&mut self, decibals: f32) {
        for l in self.left_as_mut() {
            l.gain(decibals);
        }

        for r in self.right_as_mut() {
            r.gain(decibals);
        }
    }
}

/*impl<A, B> StereoFloatBuffer for (A, B) where A: FloatBuffer, B: FloatBuffer {
    fn left_as_ref<'a>(&self) -> &'a [f32] {
        self.0.as_ref()
    }

    fn left_as_mut(&mut self) -> &mut [f32] {
        self.0.as_mut()
    }

    fn right_as_ref<'a>(&self) -> &'a [f32] {
        self.0.as_ref()
    }

    fn right_as_mut(&mut self) -> &mut [f32] {
        self.0.as_mut()
    }
}*/
