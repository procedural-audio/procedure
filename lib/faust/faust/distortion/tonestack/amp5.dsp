import("stdfaust.lib");

preamp = vslider("pregain",-6,-20,20,0.1) : ba.db2linear : si.smooth(0.999);
gain  = vslider("gain", -6, -20.0, 20.0, 0.1) : ba.db2linear : si.smooth(0.999);

amp = component("tonestacks.lib").jcm800(t,m,l)
with {
    t = vslider("Treble", 0.5, 0, 1, 0.01);
    m = vslider("Middle", 0.5, 0, 1, 0.01);
    l = vslider("Bass", 0.5, 0, 1, 0.01);
};

process = _,_ : *(preamp), *(preamp) : amp, amp : *(gain), *(gain);

