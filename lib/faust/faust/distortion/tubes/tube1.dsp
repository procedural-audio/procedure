import("stdfaust.lib");
import("filters.lib");

tubes = component("tubes.lib").T1_12AX7 : *(preamp):
    lowpass(1,6531.0) : component("tubes.lib").T2_12AX7 : *(preamp):
    lowpass(1,6531.0) : component("tubes.lib").T3_12AX7 : *(gain) with {
    preamp = vslider("Pregain",-6,-20,20,0.1) : ba.db2linear : si.smooth(0.999);
    gain  = vslider("Gain", -6, -20.0, 20.0, 0.1) : ba.db2linear : si.smooth(0.999);
};

process = tubes;
