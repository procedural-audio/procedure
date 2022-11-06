use std::ops::Add;

#[derive(Copy, Clone)]
pub struct Time {
    start: f64,
    length: f64,
    cycle: Option<f64>,
}

impl Time {
    pub fn from(start: f64, end: f64) -> Self {
        Self {
            start,
            length: end - start,
            cycle: None,
        }
    }

    pub fn start(&self) -> f64 {
        self.start
    }

    pub fn length(&self) -> f64 {
        self.length
    }

    pub fn end(&self) -> f64 {
        match self.cycle {
            Some(cycle) => (self.start + self.length) % cycle,
            None => self.start + self.length,
        }
    }

    pub fn contains(&self, beat: f64) -> bool {
        match self.cycle {
            Some(cycle) => {
                if self.length >= 0.0 {
                    if (self.start <= beat
                        && self.start + self.length >= beat
                        && self.length != 0.0)
                        || (0.0 >= beat && (cycle - self.start) >= beat && self.length != 0.0)
                    {
                        true
                    } else {
                        false
                    }
                } else {
                    if (self.start >= beat
                        && self.start + self.length <= beat
                        && self.length != 0.0)
                        || (0.0 >= beat && (cycle - self.start) <= beat && self.length != 0.0)
                    {
                        true
                    } else {
                        false
                    }
                }
            }
            None => {
                if self.length >= 0.0 {
                    if self.start <= beat && self.start + self.length >= beat && self.length != 0.0
                    {
                        true
                    } else {
                        false
                    }
                } else {
                    if self.start >= beat && self.start + self.length <= beat && self.length != 0.0
                    {
                        true
                    } else {
                        false
                    }
                }
            }
        }
    }

    pub fn rate(&self, rate: f64) -> Time {
        match self.cycle {
            Some(cycle) => Time {
                start: (self.start * rate) % cycle,
                length: self.length * rate,
                cycle: Some(cycle),
            },
            None => Time {
                start: self.start * rate,
                length: self.length * rate,
                cycle: None,
            },
        }
    }

    pub fn shift(&self, beats: f64) -> Time {
        Time::from(self.start + beats, self.start + beats + self.length)
    }

    pub fn cycle(&self, beats: f64) -> Time {
        match self.cycle {
            Some(cycle) => {
                if beats < cycle {
                    Time {
                        start: self.start % beats,
                        length: self.length,
                        cycle: Some(beats),
                    }
                } else {
                    *self
                }
            }
            None => Time {
                start: self.start % beats,
                length: self.length,
                cycle: Some(beats),
            },
        }
    }

    pub fn on_each<F: FnMut(usize)>(&self, rate: f64, mut f: F) {
        let end = self.start + self.length;

        if self.length > 0.0 {
            match self.cycle {
                Some(cycle) => {
                    if self.start + self.length <= cycle {
                        if self.start % rate > end % rate {
                            (f)(((end - (end % rate)) / rate).round() as usize - 1);
                        }
                    } else {
                        if self.start % rate > cycle % rate {
                            (f)(((cycle - (cycle % rate)) / rate).round() as usize - 1);
                        }

                        if 0.0 % rate > (self.start + self.length - cycle) % rate {
                            (f)(0)
                        }
                    }
                }
                None => {
                    if self.start % rate > end % rate {
                        (f)(((end - (end % rate)) / rate).round() as usize - 1);
                    }
                }
            }
        } else if self.length < 0.0 {
            if self.start % rate < end % rate {
                (f)(((self.start - (self.start % rate)) / rate).round() as usize - 1);
            }
        }
    }

    /*pub fn next(&self) -> Time {
      if self.start <= self.end {
        let delta = self.end - self.start;
        Time::from(self.end, self.end + delta)
      } else {
        let delta = self.start - self.end;
        Time::from(self.end, self.end - delta)
      }
    }*/
}

impl Add for Time {
    type Output = Time;

    fn add(self, _rhs: Self) -> Self::Output {
        panic!("Time add not implemented");
    }
}

/*

Time only affects phase of note and control modules
Control values should be a function of time

Modules
 - Global Time
 - Time (pass it a BPM)
 - Rate (make time move twice as fast, etc)
 - Reverse
 - Random (can randomize measure, beat, 8th, 16th, etc)
 - On Time (output 1 if at certain time)

Graph level variables
 - Useful for file IO

*/
