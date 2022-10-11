declare name "highpass6";
declare description "Low Pass";
declare author "Chase Kanipe";

import("stdfaust.lib");

freq = hslider("freq[style:knob]", 10000, 100, 10000, 0.001) : si.smoo;

process = _,_ : fi.highpass(5, freq), fi.highpass(5, freq);
