import("stdfaust.lib");
import("math.lib");

// Notches: number of spectral notches (MACRO ARGUMENT - not a signal)
// width: approximate width of spectral notches in Hz
// frqmin: approximate minimum frequency of first spectral notch in Hz
// fratio: ratio of adjacent notch frequencies
// frqmax: approximate maximum frequency of first spectral notch in Hz
// speed: LFO frequency in Hz (rate of periodic notch sweep cycles)
// depth: effect strength between 0 and 1 (1 typical) (aka "intensity") when depth=2, "vibrato mode" is obtained (pure allpass chain)
// fb: feedback gain between -1 and 1 (0 typical)
// invert: 0 for normal, 1 to invert sign of flanging sum

// _,_ : phaser2_stereo(Notches,width,frqmin,fratio,frqmax,speed,depth,fb,invert) : _,_

Notches = 5;
width = 60;
frqmin = 100;
fratio = 2;
frqmax = 5000;
speed = 5;
depth = hslider("Depth", 0, 0, 1, 0.001);
fb = hslider("Feedback", 0, -0.999, 0.999, 0.001);
invert = 0;

process = _,_ : pf.phaser2_stereo(Notches,width,frqmin,fratio,frqmax,speed,depth,fb,invert) : _,_;

