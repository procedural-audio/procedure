use pa_dsp::AudioBuffer;

// https://github.com/electro-smith/DaisySP/blob/master/Source/PhysicalModeling/stringvoice.h

struct Svf {
    sr: f32,
    fc: f32,
    res: f32,
    drive: f32,
    freq: f32,
    damp: f32,
    notch: f32,
    low: f32,
    high: f32,
    band: f32,
    peak: f32,
    input: f32,
    out_low: f32,
    out_high: f32,
    out_band: f32,
    out_peak: f32,
    out_notch: f32,
    pre_drive: f32,
    fc_max: f32,
}

impl Svf {
    pub fn new() -> Self {
        Self {
            sr: 0.0,
            fc: 200.0,
            res: 0.5,
            drive: 0.5,
            pre_drive: 0.5,
            freq: 0.25,
            damp: 0.0,
            notch: 0.0,
            low: 0.0,
            high: 0.0,
            band: 0.0,
            peak: 0.0,
            input: 0.0,
            out_notch: 0.0,
            out_low: 0.0,
            out_high: 0.0,
            out_peak: 0.0,
            out_band: 0.0,
            fc_max: 0.0,
        }
    }

    pub fn prepare(&mut self, sample_rate: u32, _block_size: usize) {
        self.sr = sample_rate as f32;
        self.fc_max = self.sr / 3.0;
    }

    pub fn process(&mut self, buffers: &mut [AudioBuffer]) {
        for buffer in buffers {
            for sample in buffer {
                self.input = *sample;

                // First pass

                self.notch = self.input - self.damp * self.band;
                self.low = self.low + self.freq * self.band;
                self.high = self.notch - self.low;
                self.band = self.freq * self.high + self.band
                    - self.drive * self.band * self.band * self.band;

                // Take first sample of output

                self.out_low = 0.5 * self.low;
                self.out_high = 0.5 * self.high;
                self.out_band = 0.5 * self.band;
                self.out_peak = 0.5 * (self.low - self.high);
                self.out_notch = 0.5 * self.notch;

                // Second pass

                self.notch = self.input - self.damp * self.band;
                self.low = self.low + self.freq * self.band;
                self.high = self.notch - self.low;
                self.band = self.freq * self.high + self.band
                    - self.drive * self.band * self.band * self.band;

                // Averate second pass outputs

                self.out_low += 0.5 * self.low;
                self.out_high = 0.5 * self.high;
                self.out_band = 0.5 * self.band;
                self.out_peak = 0.5 * (self.low - self.high);
                self.out_notch = 0.5 * self.notch;
            }
        }
    }

    pub fn set_freq(&mut self, freq: f32) {
        self.fc = f32::clamp(freq, 1.0e-6, self.fc_max);

        self.freq =
            2.0 * f32::sin(std::f32::consts::PI * f32::min(0.25, self.fc / (self.sr * 2.0)));

        self.damp = f32::min(
            2.0 * (1.0 - f32::powf(self.res, 0.25)),
            f32::min(2.0, 2.0 / self.freq - self.freq * 0.5),
        );
    }

    pub fn set_res(&mut self, freq: f32) {
        let res = f32::clamp(freq, 0.0, 1.0);
        self.res = res;

        // recalculate dump

        self.damp = f32::min(
            2.0 * (1.0 - f32::powf(self.res, 0.25)),
            f32::min(2.0, 2.0 / self.freq - self.freq * 0.5),
        );
        self.drive = self.pre_drive * self.res;
    }

    pub fn set_drive(&mut self, drive: f32) {
        let drv = f32::clamp(drive * 0.1, 0.0, 1.0);
        self.pre_drive = drv;
        self.drive = self.pre_drive * self.res;
    }

    pub fn low(&self) -> f32 {
        self.out_low
    }

    pub fn high(&self) -> f32 {
        self.out_high
    }

    pub fn band(&self) -> f32 {
        self.out_band
    }

    pub fn notch(&self) -> f32 {
        self.out_notch
    }

    pub fn peak(&self) -> f32 {
        self.out_peak
    }
}

// DUST.h

/*
#pragma once
#ifndef DSY_DUST_H
#define DSY_DUST_H
#include <cstdlib>
#include <random>
#include "Utility/dsp.h"
#ifdef __cplusplus

/** @file dust.h */

namespace daisysp
{
/**
       @brief Dust Module
       @author Ported by Ben Sergentanis
       @date Jan 2021
       Randomly Clocked Samples \n \n
       Ported from pichenettes/eurorack/plaits/dsp/noise/dust.h \n
       to an independent module. \n
       Original code written by Emilie Gillet in 2016. \n

*/
class Dust
{
  public:
    Dust() {}
    ~Dust() {}

    void Init() { SetDensity(.5f); }

    float Process()
    {
        float inv_density = 1.0f / density_;
        float u           = rand() * kRandFrac;
        if(u < density_)
        {
            return u * inv_density;
        }
        return 0.0f;
    }

    void SetDensity(float density)
    {
        density_ = fclamp(density, 0.f, 1.f);
        density_ = density_ * .3f;
    }

  private:
    float                  density_;
    static constexpr float kRandFrac = 1.f / (float)RAND_MAX;
};
} // namespace daisysp
#endif
#endif
*/

// STRINGVOICE.h

/*
#pragma once
#ifndef DSY_STRINGVOICE_H
#define DSY_STRINGVOICE_H

#include "Filters/svf.h"
#include "PhysicalModeling/KarplusString.h"
#include "Noise/dust.h"
#include <stdint.h>
#ifdef __cplusplus

/** @file stringvoice.h */

namespace daisysp
{
/**
       @brief Extended Karplus-Strong, with all the niceties from Rings
       @author Ben Sergentanis
       @date Jan 2021
       Ported from pichenettes/eurorack/plaits/dsp/physical_modelling/string_voice.h \n
       and pichenettes/eurorack/plaits/dsp/physical_modelling/string_voice.cc \n
       to an independent module. \n
       Original code written by Emilie Gillet in 2016. \n
*/
class StringVoice
{
  public:
    StringVoice() {}
    ~StringVoice() {}

    /** Initialize the module
        \param sample_rate Audio engine sample rate
    */
    void Init(float sample_rate);

    /** Reset the string oscillator */
    void Reset();

    /** Get the next sample
        \param trigger Strike the string. Defaults to false.
    */
    float Process(bool trigger = false);

    /** Continually excite the string with noise.
        \param sustain True turns on the noise.
    */
    void SetSustain(bool sustain);

    /** Strike the string. */
    void Trig();

    /** Set the string root frequency.
        \param freq Frequency in Hz.
    */
    void SetFreq(float freq);

    /** Hit the string a bit harder. Influences brightness and decay.
        \param accent Works 0-1.
    */
    void SetAccent(float accent);

    /** Changes the string's nonlinearity (string type).
        \param structure Works 0-1. 0-.26 is curved bridge, .26-1 is dispersion.
    */
    void SetStructure(float structure);

    /** Set the brighness of the string, and the noise density.
        \param brightness Works best 0-1
    */
    void SetBrightness(float brightness);

    /** How long the resonant body takes to decay relative to the accent level.
        \param damping Works best 0-1. Full damp is only achieved with full accent.
    */
    void SetDamping(float damping);

    /** Get the raw excitation signal. Must call Process() first. */
    float GetAux();

  private:
    float sample_rate_;

    bool  sustain_, trig_;
    float f0_, brightness_, damping_;
    float density_, accent_;
    float aux_;

    Dust   dust_;
    Svf    excitation_filter_;
    String string_;
    size_t remaining_noise_samples_;
};
} // namespace daisysp
#endif
#endif
*/

// STRINGVOICE.cpp

/*

#include "stringvoice.h"
#include <algorithm>
#include "dsp.h"

using namespace daisysp;

void StringVoice::Init(float sample_rate)
{
    sample_rate_ = sample_rate;

    excitation_filter_.Init(sample_rate);
    string_.Init(sample_rate_);
    dust_.Init();
    remaining_noise_samples_ = 0;

    SetSustain(false);
    SetFreq(440.f);
    SetAccent(.8f);
    SetStructure(.7f);
    SetBrightness(.2f);
    SetDamping(.7f);
}

void StringVoice::Reset()
{
    string_.Reset();
}

void StringVoice::SetSustain(bool sustain)
{
    sustain_ = sustain;
}

void StringVoice::Trig()
{
    trig_ = true;
}

void StringVoice::SetFreq(float freq)
{
    string_.SetFreq(freq);
    f0_ = freq / sample_rate_;
    f0_ = fclamp(f0_, 0.f, .25f);
}

void StringVoice::SetAccent(float accent)
{
    accent_ = fclamp(accent, 0.f, 1.f);
}

void StringVoice::SetStructure(float structure)
{
    structure = fclamp(structure, 0.f, 1.f);
    const float non_linearity
        = structure < 0.24f
              ? (structure - 0.24f) * 4.166f
              : (structure > 0.26f ? (structure - 0.26f) * 1.35135f : 0.0f);
    string_.SetNonLinearity(non_linearity);
}

void StringVoice::SetBrightness(float brightness)
{
    brightness_ = fclamp(brightness, 0.f, 1.f);
    density_    = brightness_ * brightness_;
}

void StringVoice::SetDamping(float damping)
{
    damping_ = fclamp(damping, 0.f, 1.f);
}

float StringVoice::GetAux()
{
    return aux_;
}

float StringVoice::Process(bool trigger)
{
    const float brightness = brightness_ + .25 * accent_ * (1.f - brightness_);
    const float damping    = damping_ + .25 * accent_ * (1.f - damping_);

    // Synthesize excitation signal.
    if(trigger || trig_ || sustain_)
    {
        trig_              = false;
        const float range  = 72.0f;
        const float f      = 4.0f * f0_;
        const float cutoff = fmin(
            f
                * powf(2.f,
                       kOneTwelfth * (brightness * (2.0f - brightness) - 0.5f)
                           * range),
            0.499f);
        const float q            = sustain_ ? 1.0f : 0.5f;
        remaining_noise_samples_ = static_cast<size_t>(1.0f / f0_);
        excitation_filter_.SetFreq(cutoff * sample_rate_);
        excitation_filter_.SetRes(q);
    }

    float temp = 0.f;

    if(sustain_)
    {
        const float dust_f = 0.00005f + 0.99995f * density_ * density_;
        dust_.SetDensity(dust_f);
        temp = dust_.Process() * (8.0f - dust_f * 6.0f) * accent_;
    }
    else if(remaining_noise_samples_)
    {
        temp = 2.0f * rand() * kRandFrac - 1.0f;
        remaining_noise_samples_--;
        remaining_noise_samples_ = DSY_MAX(remaining_noise_samples_, 0.f);
    }

    excitation_filter_.Process(temp);
    temp = excitation_filter_.Low();

    aux_ = temp;

    string_.SetBrightness(brightness);
    string_.SetDamping(damping);

    return string_.Process(temp);
}

*/
