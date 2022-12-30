import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:metasampler/host.dart';

import '../main.dart';
import 'settings.dart';

class RightClickView extends StatefulWidget {
  RightClickView(this.host, {required this.addPosition});

  Offset addPosition;
  Host host;

  @override
  State<RightClickView> createState() => _RightClickView();
}

class _RightClickView extends State<RightClickView> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    List<RightClickCategory> widgets = [];

    {
      List<Widget> category = [];

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(widget.host, "Audio Track",
            Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Sampler", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Multi-Sampler",
            AntDesign.sound, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Granular", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Slicer", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Sample Resynthesis",
            Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Looper", Icons.loop,
            Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("Sampling", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(widget.host, "Saw",
            MaterialCommunityIcons.wave, Colors.blue, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Square",
            MaterialCommunityIcons.wave, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Sine",
            MaterialCommunityIcons.wave, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Triangle",
            MaterialCommunityIcons.wave, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Pulse",
            MaterialCommunityIcons.wave, Colors.grey, 30, widget.addPosition));

        subCategory.add(RightClickElement(widget.host, "Analog Oscillator",
            MaterialCommunityIcons.wave, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Wavetable Oscillator",
            MaterialCommunityIcons.waves, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Additive Oscillator",
            MaterialCommunityIcons.vector_combine,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Harmonic Oscillator", // (Based of Pigments harmonic oscillator)
            MaterialCommunityIcons.vector_combine,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Noise",
            MaterialCommunityIcons.wave, Colors.blue, 30, widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Pluck",
            MaterialCommunityIcons.guitar_pick,
            Colors.grey,
            30,
            widget.addPosition));

        /*subCategory.add(RightClickElement(widget.host, 
            "Polygon Oscillator", Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Double Pendulum Oscillator",
            MaterialCommunityIcons.z_wave, Colors.grey, 30, widget.addPosition));
        subCategory
            .add(RightClickElement(widget.host, "Drum Synth", Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, 
            "Harmonics Painter", Icons.piano, Colors.grey, 30, widget.addPosition));*/

        category.add(RightClickCategory("Synthesis", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(
            widget.host,
            "String Model",
            MaterialCommunityIcons.violin,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Acoustic Guitar Model",
            MaterialCommunityIcons.guitar_acoustic,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Electric Guitar Model",
            MaterialCommunityIcons.guitar_electric,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Modal Oscillator",
            MaterialCommunityIcons.ring, Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("Physical Modeling", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(widget.host, "Tone Transfer",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Spectrogram Resynthesis",
            Icons.piano,
            Colors.grey,
            30,
            widget.addPosition));

        category.add(RightClickCategory("Machine Learning", 20, subCategory));
      }

      widgets.add(RightClickCategory("Sources", 10, category));
    }

    {
      List<Widget> category = [];

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(
            widget.host,
            "Gain",
            MaterialCommunityIcons.volume_plus,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Panner",
            MaterialCommunityIcons.pan, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Mute",
            MaterialCommunityIcons.volume_plus,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Mixer",
            MaterialCommunityIcons.mixer, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Gate",
            MaterialCommunityIcons.gate, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Compressor",
            Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Transient Shaper",
            Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Transient Separator",
            Icons.piano, Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("Dynamics", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(widget.host, "Amplifier", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Analog Saturator",
            Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Analog Distortion",
            Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Cassette", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Tape", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Tube", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Wavefolder",
            MaterialCommunityIcons.jabber,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Waveshaper",
            MaterialCommunityIcons.scan_helper,
            Colors.grey,
            30,
            widget.addPosition));
        //subCategory.add(RightClickElement(widget.host, "Pickup Model", Icons.piano, Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("Distortion", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(widget.host, "Digital Filter",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Analog Filter",
            Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Creative Filter",
            Icons.piano, Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("Filter", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(widget.host, "Reverb",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Delay", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Shimmer", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Convolution",
            Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Resonator", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Binaural Panner",
            Icons.piano, Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("Space", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(widget.host, "Equalizer",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Exciter", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Pitch Shifter",
            Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Pitch Corrector",
            Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Vocoder", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Crossover", Icons.piano,
            Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("Spectral", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(widget.host, "Chorus",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Flanger", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Phaser", Icons.piano,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Stereoizer",
            Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Vibrato", Icons.piano,
            Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("Modulation", 20, subCategory));
      }

      widgets.add(RightClickCategory("Effects", 10, category));
    }

    {
      List<Widget> category = [];

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(widget.host, "Notes Track",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Step Sequencer",
            MaterialCommunityIcons.view_sequential,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Arpeggiator",
            MaterialCommunityIcons.view_sequential,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Keyboard",
            MaterialCommunityIcons.piano, Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("Sources", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(
            widget.host,
            "Transpose",
            MaterialCommunityIcons.view_sequential,
            Colors.green,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Scale",
            MaterialCommunityIcons.view_sequential,
            Colors.green,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Pitch",
            MaterialCommunityIcons.view_sequential,
            Colors.green,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Pressure",
            MaterialCommunityIcons.view_sequential,
            Colors.green,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Timbre",
            MaterialCommunityIcons.view_sequential,
            Colors.green,
            30,
            widget.addPosition));

        category.add(RightClickCategory("Effects", 20, subCategory));
      }

      widgets.add(RightClickCategory("Notes", 10, category));
    }

    {
      List<Widget> category = [];

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(
            widget.host,
            "Constant",
            MaterialCommunityIcons.numeric,
            Colors.red,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "LFO",
            MaterialCommunityIcons.sine_wave,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Envelope",
            MaterialCommunityIcons.sawtooth_wave,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Clock",
            MaterialCommunityIcons.clock, Colors.red, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Random",
            Icons.noise_aware, Colors.red, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Control Track",
            Icons.functions, Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("Control Sources", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(
            widget.host,
            "Display",
            MaterialCommunityIcons.numeric,
            Colors.red,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Hold",
            MaterialCommunityIcons.hand, Colors.red, 30, widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Toggle",
            MaterialCommunityIcons.car_brake_hold,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Scale",
            MaterialCommunityIcons.view_grid,
            Colors.red,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Bend",
            MaterialCommunityIcons.view_grid,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Slew",
            MaterialCommunityIcons.view_grid,
            Colors.grey,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Knob",
            MaterialCommunityIcons.rotate_3d,
            Colors.red,
            30,
            widget.addPosition));

        category.add(RightClickCategory("Control Effects", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(
            widget.host,
            "And",
            MaterialCommunityIcons.gate_and,
            Colors.red,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Or",
            MaterialCommunityIcons.gate_or,
            Colors.red,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Not",
            MaterialCommunityIcons.gate_not,
            Colors.red,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Xor",
            MaterialCommunityIcons.gate_xor,
            Colors.red,
            30,
            widget.addPosition));

        category.add(RightClickCategory("Logic", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(
            widget.host, "Add", Icons.add, Colors.red, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Subtract",
            MaterialCommunityIcons.minus, Colors.red, 30, widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Multiply",
            MaterialCommunityIcons.multiplication,
            Colors.red,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Divide",
            MaterialCommunityIcons.division,
            Colors.red,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Modulo",
            MaterialCommunityIcons.percent,
            Colors.red,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Negative",
            MaterialCommunityIcons.minus, Colors.red, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Clamp",
            MaterialCommunityIcons.scale, Colors.red, 30, widget.addPosition));

        category.add(RightClickCategory("Operations", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(widget.host, "Equal",
            MaterialCommunityIcons.equal, Colors.red, 30, widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Not Equal",
            MaterialCommunityIcons.not_equal,
            Colors.red,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Less than",
            MaterialCommunityIcons.less_than,
            Colors.red,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Less/equal to",
            MaterialCommunityIcons.less_than_or_equal,
            Colors.red,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Greater than",
            MaterialCommunityIcons.greater_than,
            Colors.red,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Greater/equal to",
            MaterialCommunityIcons.greater_than_or_equal,
            Colors.red,
            30,
            widget.addPosition));

        category.add(RightClickCategory("Comparisons", 20, subCategory));
      }

      widgets.add(RightClickCategory("Control", 10, category));
    }

    {
      List<Widget> category = [];

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(widget.host, "Midi to Control",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Gain to Control",
            Icons.piano, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Control To Notes",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Notes to Control",
            Icons.functions, Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("Conversions", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(widget.host, "Audio Input",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Audio Output",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Midi Input",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Midi Output",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "VST Host",
            Icons.functions, Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("IO", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(widget.host, "LUA Script",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Faust Script",
            Icons.functions, Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "DSP Designer",
            Icons.functions, Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("Scripting", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(
            widget.host,
            "Time",
            MaterialCommunityIcons.clock,
            Colors.deepPurpleAccent,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Rate",
            MaterialCommunityIcons.multiplication,
            Colors.deepPurpleAccent,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(
            widget.host,
            "Reverse",
            MaterialCommunityIcons.minus,
            Colors.deepPurpleAccent,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Loop", Icons.loop,
            Colors.grey, 30, widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Seek/Shift/Offset",
            Icons.filter_tilt_shift, Colors.grey, 30, widget.addPosition));

        category.add(RightClickCategory("Time", 20, subCategory));
      }

      {
        List<Widget> subCategory = [];

        subCategory.add(RightClickElement(
            widget.host,
            "Control Variable",
            MaterialCommunityIcons.clock,
            Colors.deepPurpleAccent,
            30,
            widget.addPosition));
        subCategory.add(RightClickElement(widget.host, "Audio Plugin",
            MaterialCommunityIcons.power, Colors.blue, 30, widget.addPosition));

        category.add(RightClickCategory("Variables", 20, subCategory));
      }

      widgets.add(RightClickCategory("Utilities", 10, category));
    }

    {
      List<Widget> category = [];

      category.add(RightClickCategory("Sound Painter", 20, []));

      widgets.add(RightClickCategory("Expansions", 10, category));
    }

    List<Widget> filteredWidgets = [];

    if (searchText != "") {
      for (var category in widgets) {
        bool addedCategory = false;
        for (var element in category.elements) {
          bool addedSubCategory = false;
          if (element.runtimeType == RightClickCategory) {
            for (var element2 in (element as RightClickCategory).elements) {
              if ((element2 as RightClickElement)
                  .name
                  .toLowerCase()
                  .contains(searchText.toLowerCase())) {
                /*if (!addedCategory) {
                  filteredWidgets.add(category);
                }

                if (!addedSubCategory) {
                  filteredWidgets.add(element);
                }*/

                filteredWidgets.add(element2);
              }
            }
          }
        }
      }
    } else {
      filteredWidgets = widgets;
    }

    return MouseRegion(
        onEnter: (event) {
          widget.host.globals.patchingScaleEnabled = false;
        },
        onExit: (event) {
          widget.host.globals.patchingScaleEnabled = true;
        },
        child: Container(
          width: 300,
          child: Column(
            children: [
              /* Title */
              Container(
                height: 35,
                padding: const EdgeInsets.all(10.0),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Modules",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ),

              /* Search bar */
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
                child: Container(
                  height: 20,
                  child: TextField(
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                        fillColor: Color.fromARGB(255, 112, 35, 30),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.fromLTRB(10, 10, 0, 3)),
                    onChanged: (data) {
                      setState(() {
                        searchText = data;
                      });
                    },
                  ),
                  decoration: const BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                ),
              ),

              /* List */
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  controller: ScrollController(),
                  child: Column(
                    children: filteredWidgets,
                  ),
                ),
              ),
            ],
          ),
          decoration: BoxDecoration(
              color: MyTheme.grey20, border: Border.all(color: MyTheme.grey40)),
        ));
  }
}

class RightClickCategory extends StatefulWidget {
  final String name;
  final double indent;
  final List<Widget> elements;

  RightClickCategory(this.name, this.indent, this.elements);

  @override
  State<RightClickCategory> createState() => _RightClickCategoryState();
}

class _RightClickCategoryState extends State<RightClickCategory> {
  bool hovering = false;
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
            MouseRegion(
                onEnter: (event) {
                  setState(() {
                    hovering = true;
                  });
                },
                onExit: (event) {
                  setState(() {
                    hovering = false;
                  });
                },
                child: GestureDetector(
                    onTap: () {
                      setState(() {
                        expanded = !expanded;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.fromLTRB(widget.indent, 0, 0, 0),
                      height: 24,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(children: [
                          Icon(
                            expanded
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            //color: Colors.white,
                            color: MyTheme.textColorLight,
                            size: 20,
                          ),
                          Text(
                            widget.name,
                            style: const TextStyle(
                                //color: Colors.white,
                                color: MyTheme.textColorLight,
                                fontSize: 14,
                                fontWeight: FontWeight.w300),
                          )
                        ]),
                      ),
                      decoration: BoxDecoration(
                        color: hovering ? MyTheme.grey40 : MyTheme.grey20,
                      ),
                    )))
          ] +
          (expanded ? widget.elements : []),
    );
  }
}

class RightClickElement extends StatefulWidget {
  final String name;
  final double indent;
  final IconData icon;
  final Color color;
  String path = "logic/and.svg";
  final Offset addPosition;

  Host host;

  RightClickElement(this.host, this.name, this.icon, this.color, this.indent,
      this.addPosition);

  @override
  State<RightClickElement> createState() => _RightClickElementState();
}

class _RightClickElementState extends State<RightClickElement> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    //var iconPath = globals.contentPath + "/assets/icons/" + widget.path;
    //print(iconPath);

    return MouseRegion(
        onEnter: (event) {
          setState(() {
            hovering = true;
          });
        },
        onExit: (event) {
          setState(() {
            hovering = false;
          });
        },
        child: GestureDetector(
            onTap: () {
              if (widget.host.graph
                  .addModule(widget.name, widget.addPosition)) {
                gGridState?.refresh();
              } else {
                print("Couldn't add module");
              }
            },
            child: Container(
              padding: EdgeInsets.fromLTRB(widget.indent, 0, 0, 0),
              height: 22,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(children: [
                    Icon(
                      widget.icon,
                      color: widget.color,
                      size: 16,
                    ),
                    /*SvgPicture.file(
                  File(iconPath),
                  height: 16,
                  width: 16,
                  color: widget.color,
                  fit: BoxFit.fill,
                ),*/
                    Container(
                      width: 5,
                    ),
                    Text(
                      widget.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w300),
                    ),
                  ])),
              decoration: BoxDecoration(
                color: hovering ? MyTheme.grey40 : MyTheme.grey20,
              ),
            )));
  }
}
