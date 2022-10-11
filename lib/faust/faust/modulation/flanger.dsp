import("stdfaust.lib");
import("math.lib");

//---------------`(pf.)flanger_stereo`-------------
// Stereo flanging effect.
// * `dmax`: maximum delay-line length (power of 2) - 10 ms typical
// * `curdel`: current dynamic delay (not to exceed dmax)
// * `depth`: effect strength between 0 and 1 (1 typical)
// * `fb`: feedback gain between 0 and 1 (0 typical)
// * `invert`: 0 for normal, 1 to invert sign of flanging sum
//------------------------------------------------------------

dmax = 2048;

lfol = component("oscillator.lib").oscrs; // sine for left channel
lfor = component("oscillator.lib").oscrc; // cosine for right channel

dflange = 0.001 * SR * hslider("[1] Flange Delay [unit:ms] [style:knob]", 10, 0, 20, 0.001);
odflange = 0.001 * SR * hslider("[2] Delay Offset [unit:ms] [style:knob]", 1, 0, 20, 0.001);
freq  = hslider("[1] Speed [unit:Hz] [style:knob]", 0.5, 0, 10, 0.01);
depth = hslider("[2] Depth [style:knob]", 1, 0, 1, 0.001);
fb = hslider("[3] Feedback [style:knob]", 0, -0.999, 0.999, 0.001);
level = hslider("Flanger Output Level [unit:dB]", 0, -60, 10, 0.1) : db2linear;

curdel1 = odflange+dflange*(1 + lfol(freq))/2;
curdel2 = odflange+dflange*(1 + lfor(freq))/2;

process = _,_ : pf.flanger_stereo(dmax,curdel1,curdel2,depth,fb,0) : _,_;

