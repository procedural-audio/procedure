import("stdfaust.lib");
freq = hslider("freq[style:numerical]", -0.5, -1.0, 1.0, 0.001) : si.smoo;
process = no.colored_noise(2, freq);
