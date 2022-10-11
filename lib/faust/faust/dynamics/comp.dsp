// Found here: https://cm-gitlab.stanford.edu/mjolsen/Compressor/

// comp.dsp - an implementation of a variety of compressor elements and 
// architectures including different types of level detectors, gain 
// computers and feedforward/feedback compressor architectures. The main 
// idea is to make the different components modular so they can be used 
// in a variety of configurations.
// Based on information from the course notes of Stanford course MUS424

declare name "Faust Audio Compressor Library";
declare author "Michael J. Olsen (mjolsen at ccrma.stanford.edu)";
declare copyright "Michael Jorgen Olsen";
declare version "1.0";
declare license "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license)

// import stdfaust which gives access to all standard libraries
import("stdfaust.lib");


//----------------------- level detectors ------------------------
// *** should be added to analyzers.lib ***

//------------------- amp_follower_(RMS/RMP) --------------------
// RMS envelope follower:
//
// ### USAGE: 
//
// _ : amp_follower_RMS(rel) : _;
//
// where: rel = desired release time of the leaky integrator (in sec.)
amp_follower_RMS(rel) = val with {
    a1 = ba.tau2pole(rel);
    b0 = 1.0 - a1;
    val = _^2 : fi.tf1(b0,0,-1.0*a1) : sqrt;
};

// RMP envelope follower
//
// ### USAGE: 
//
// _ : amp_follower_RMP(rel,p) : _;
//
// where:
// rel = desired release time of the leaky integrator (in sec.)
// p = power and inverse root (e.g. 2 => RMS)
amp_follower_RMP(rel,p) = abs : val with {
    a1 = ba.tau2pole(rel);
    b0 = 1.0 - a1;
    val = pow(_,p) : fi.tf1(b0,0,-1.0*a1) : pow(_,1.0/p);
};

//--------------------- amp_follower_ud_(rtv/rtz/rtt) ----------------------
// peak envelope followers with separate attack and release time constants
// and various release behaviors: release to signal value, release to zero 
// and release to the threshold of compression
//
// ### USAGE:
//
//  _ : amp_follower_ud_rtv(att,rel) : _;
//  _ : amp_follower_ud_rtz(att,rel) : _;
//  _ : amp_follower_ud_rtt(att,rel,thresh) : _;
// where:
//  att = attack time = amplitude-envelope time constant (sec) going up
//  rel = release time = amplitude-envelope time constant (sec) going down
//  thresh = threshold of compression
amp_follower_ud_rtv(att,rel) = abs : val with {
    a1_a = ba.tau2pole(att);
    a1_r = ba.tau2pole(rel);
    val = ((_,_,_) : (_,(_<:_,_),(_<:_,_,_)) :
           (_,_,ro.cross(2),_,_) : (_,<,>=,_) :
           (_,a1_a*_,a1_r*_,_) : (_,+,_) : (_,(_<:_,_),_) :
           (*,1-_,_) : (_,*) : (+))~(_<:_,_);
};

amp_follower_ud_rtz(att,rel) = abs : val with {
    a1_a = ba.tau2pole(att);
    a1_r = ba.tau2pole(rel);
    val = ((_,_,_) : (_,(_<:_,_),(_<:_,_,_)) :
           (_,_,ro.cross(2),_,_) : (_,<,>=,_) :
           (_,(_<:_,_),_,_) : (_,_,ro.cross(2),_) :
           (_,_,_,*) : (_,a1_a*_,a1_r*_,_) : (_,+,_) : 
           (_,(_<:_,_),_) : (*,1-_,_) : (_,*) : +)~(_<:_,_);
};

amp_follower_ud_rtt(att,rel,thresh) = abs : val with {
    a1_a = ba.tau2pole(att);
    a1_r = ba.tau2pole(rel);
    val = ((_,_,_) : (_,(_<:_,_),(_<:_,_,_)) :
           (_,_,ro.cross(2),_,_) : (_,<,>=,_) :
           (_,(_<:_,_),(_<:_,_),_) : (_,_,ro.cross(2),ro.cross(2)) :
           (_,_,_,*,_*thresh) : (_,_,_,+) : (_,a1_a*_,a1_r*_,_) : (_,+,_) : 
           (_,(_<:_,_),_) : (*,1-_,_) : (_,*) : +)~(_<:_,_);
};

//---------------------- amp_follower_(rtz/rtt) -----------------------
// peak envelope followers with instant attack and exponential releases
// which either release to zero or release to the threshold of 
// compression release
//
// ### USAGE: 
//
// _ : amp_follower_rtz(rel) : _;
// _ : amp_follower_rtt(rel,thresh) : _;
// where:
//  rel = release time = amplitude-envelope time constant (sec) going down
//  thresh = threshold of compression
amp_follower_rtz(rel) = abs : val with {
    a1 = ba.tau2pole(rel);
    val = ((_,_,_) : (_,(_<:_,_),(_<:_,_,_)) :
           (_,_,ro.cross(2),_,_) : (_,<,>=,_) :
           (_,_,a1*_,_) : (_,ro.cross(2),_) :
	   (_,_,*) : (*,_) : +)~(_<:_,_);
};

amp_follower_rtt(rel,thresh) = abs : val with {
    a1 = ba.tau2pole(rel);
    val = ((_,_,_) : (_,(_<:_,_),(_<:_,_,_)) :
           (_,_,ro.cross(2),_,_) : (_,<,>=,_) :
	   (_,ro.cross(2),_) : (_,(_<:_,_),_,_) :
	   (_,_,a1,_,*) : (_,_,(_<:_,_),-1,1,_,_) : 
	   (_,*,*,_,_,_) : (*,+,thresh,_,_) :
	   (_,*,_,_) : (_,*,_) : (+,_) : +)~(_<:_,_);
};

//------------------------ amp_follower_pd -------------------------
// program dependent peak detector comprised of slow and fast peak
// detectors for quick release on transients and slow release
// to gain computer threshold after long high energy signal portions. 
//
// ### USAGE: 
//
// _ : amp_follower_pd(att_s,rel_s,att_f,rel_f,thresh) : _;
//
// where:
//  att_s = slow attack time (typically between 100-200ms)
//  att_f = fast attack time
//  rel = slow release time (typically around 1 sec.)
//  rel = fast release time
//  thresh = threshold of compression
amp_follower_pd(att_s,rel_s,att_f,rel_f,thresh) = abs : val with {
    a1_as = ba.tau2pole(att_s);
    a1_rs = ba.tau2pole(rel_s);
    a1_af = ba.tau2pole(att_f);
    a1_rf = ba.tau2pole(rel_f);

    sval = amp_follower_rtt(att_s,rel_s,thresh);
    fval = ((_,_,_,_) : (_,(_<:_,_),(_<:_,_,_),_) :
           (_,_,ro.cross(2),_,_,_) : (_,<,>=,_,_) :
           (_,(_<:_,_),(_<:_,_),_,_) : (_,_,ro.cross(2),ro.cross(2),_) :
           (_,_,_,*,*) : (_,_,_,+) : (_,a1_af*_,a1_rf*_,_) : (_,+,_) : 
           (_,(_<:_,_),_) : (*,1-_,_) : (_,*) : +)~(_<:_,_);
    val = _ <: (_@1,sval) : fval;
};


//----------------------- gain computers ------------------------
// ***** should add to compressors.lib

//---------------------- gainComputer_ff -------------------------
// feedforward gain computer that computes linear gain coefficient
// suitable for use in a feedfoward compressor structure
//
// ### USAGE:
//
// _ : gainComputer_ff(thresh,ratio) : _;
//
// where:
//  thresh is the threshold of compression
//  ratio is the compression ratio
gainComputer_ff(thresh,ratio) = val with {
    pval = 1.0/float(ratio)-1.0;
    val = _<:(_<=thresh,pow((_/thresh),pval),1) : select2;
};

//---------------------- gainComputer_fb -------------------------
// feedback gain computer that computes linear gain coefficient
// suitable for use in a feedback compressor structure
//
// ### USAGE:
//
// _ : gainComputer_fb(thresh,ratio) : _;
//
// where:
//  thresh is the threshold of compression
//  ratio is the compression ratio
gainComputer_fb(thresh,ratio) = val with {
    pval = 1.0-float(ratio);
    val =  _<:(_<=thresh,pow((_/thresh),pval),1) : select2;
};


//------------------------- compressors --------------------------


//------------------------ compressor_ff -------------------------
// feedforward compressor where gain value is computed from input signal
//
// ### USAGE:
//
// _ : compressor_ff(detector,thresh,ratio) : _;
//
// where:
//  detector is a variable that points to a level detector,
//  thresh is the threshold of compression 
//  ratio is the compression ratio
compressor_ff(detector,thresh,ratio) = val with {
    val = _ <: ((_ : detector : gainComputer_ff(thresh,ratio)),_) : *;
};

//------------------------ compressor_fb -------------------------
// feedback compressor where gain value is computed from output signal
//
// ### USAGE:
//
// _ : compressor_fb(detector,thresh,ratio) : _;
//
// where:
//  detector is a variable that points to a level detector,
//  thresh is the threshold of compression 
//  ratio is the compression ratio
compressor_fb(detector,thresh,ratio) = val with {
    val = *(_)~(_ : detector : gainComputer_fb(thresh,ratio));
};

// demo program:
// this program implements a feedback compressor
// using a program dependence level detector
// note: you will need to route audio into the demo compressor
// in order to use/test it
compressor_demo = _ : compressor_fb(amp_follower_pd(as,ts,af,tf,thresh),thresh,ratio) with
{
    // GUI controls
    as = hslider("slow attack",0.1,0.0001,1.0,0.0001);
    ts = hslider("slow release",1.0,0.001,3.0,0.001);
    af = hslider("fast attack",0.001,0.0001,1.0,0.0001);
    tf = hslider("fast release",0.01,0.001,1.0,0.001);
    thresh = hslider("threshold",0.1,0.001,1.0,0.001);
    ratio = hslider("Comp Ratio",2.0,1.0,100.0,0.5);
};

// run the demo
process = compressor_demo;
