import("stdfaust.lib");
freq = hslider("freq",0.5,0,1,0.001);
q = hslider("q",1,0.5,10,0.01);
gain = hslider("gain",1,0.5,10,0.01);
process = _ : fi.svf.hs(freq, q, gain);
