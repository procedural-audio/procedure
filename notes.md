### Overview

Here are two example apps to create Flutter based AudioUnit/VST plugins. We'll build both of those and then try them in a DAW that supports them like Ableton Live. We would expect both plugins to display their own Flutter app. `flutter_juce` will display a blue hellow world app that increments by 1 when the plus button is clicked. `flutter_juce_red` should display a red app that increments by 2. However, with both plugins installed, they'll both display the app for `flutter_juce` in blue. When `flutter_juce` is deleted and your DAW restarted, then the `flutter_juce_red` will display it's own red app.

### How To Build for MacOSX

In the `flutter_juce` folder from the terminal, run:

`flutter build macos --debug`

Open the `flutter_juce.xcodeproj` located in `flutter_juce/juce/Builds/MacOSX/flutter_juce.xcodeproj`.

Build the AU (AudioUnit) target. This will install your AudioUnit plugin to `~/Library/Audio/Plug-Ins/Components`. 

Launch your DAW, and make sure AudioUnit plugins are enabled. Add the plugin to an audio track, and you should see the flutter Hello World application in blue.

Repeat the above steps for `flutter_juce_red`. 



