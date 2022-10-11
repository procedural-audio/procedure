declare name "korg35LPF";
declare description "Korg 35 LPF";
declare author "Chase Kanipe";

import("stdfaust.lib");

freq = hslider("freq[style:knob][position: 100 100][scale: 1 1][location: config]",0.5,0,1,0.001) : si.smoo;
res = hslider("res",1,0.5,10,0.01);
process = _,_ : ve.sallenKeyOnePoleLPF(freq), ve.sallenKeyOnePoleLPF(freq);
