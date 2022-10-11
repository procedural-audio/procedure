import("stdfaust.lib");

freq = hslider("freq[style:numerical]",500,200,12000,0.001) : si.smoo;

process = os.osc(freq);

