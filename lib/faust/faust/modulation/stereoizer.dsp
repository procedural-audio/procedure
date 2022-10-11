import("stdfaust.lib");
import("math.lib");

periodDuration = 10;

process = _,_ <: _,widthdelay : stereopanner
with {
    W = hslider("v:Spat/spatial width", 0.5, 0, 1, 0.01);
    A = hslider("v:Spat/pan angle", 0.6, 0, 1, 0.01);
    widthdelay = de.delay(4096,W*periodDuration/2);
    stereopanner = _,_ : *(1.0-A), *(A);
};

