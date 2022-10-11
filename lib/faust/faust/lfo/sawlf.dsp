import("stdfaust.lib");

freq = hslider("freq[style:numerical]",0.1,0,10,0.0001) : si.smoo;
process = os.lf_saw(freq);

