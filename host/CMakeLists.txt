cmake_minimum_required(VERSION 3.15)
set (CMAKE_CXX_STANDARD 14)

project(AUDIO_PLUGIN_EXAMPLE VERSION 0.0.1)

add_subdirectory(juce)

juce_add_plugin(Nodus
    # VERSION ...                               # Set this if the plugin version is different to the project version
    # ICON_BIG ...                              # ICON_* arguments specify a path to an image file to use as an icon for the Standalone
    # ICON_SMALL ...
    # COMPANY_NAME ...                          # Specify the name of the plugin's author
    # IS_SYNTH TRUE/FALSE                       # Is this a synth or an effect?
    # NEEDS_MIDI_INPUT TRUE/FALSE               # Does the plugin need midi input?
    # NEEDS_MIDI_OUTPUT TRUE/FALSE              # Does the plugin need midi output?
    # IS_MIDI_EFFECT TRUE/FALSE                 # Is this plugin a MIDI effect?
    # EDITOR_WANTS_KEYBOARD_FOCUS TRUE/FALSE    # Does the editor need keyboard focus?
    # COPY_PLUGIN_AFTER_BUILD TRUE/FALSE        # Should the plugin be installed to a default location after building?
    PLUGIN_MANUFACTURER_CODE Juce               # A four-character manufacturer id with at least one upper-case character
    PLUGIN_CODE Dem0                            # A unique four-character plugin id with exactly one upper-case character
                                                # GarageBand 10.3 requires the first letter to be upper-case, and the remaining letters to be lower-case
    FORMATS Standalone # VST3 AUv3              # The formats to build. Other valid formats are: AAX Unity VST AU AUv3
    PRODUCT_NAME "Nodus")                       # The name of the final executable, which can differ from the target name

juce_generate_juce_header(Nodus)

target_sources(Nodus
    PRIVATE
        src/PluginEditor.mm
        src/PluginProcessor.mm
        src/AudioPlugin.cpp)


target_compile_definitions(Nodus
    PUBLIC
        # JUCE_WEB_BROWSER and JUCE_USE_CURL would be on by default, but you might not need them.
        JUCE_WEB_BROWSER=0  # If you remove this, add `NEEDS_WEB_BROWSER TRUE` to the `juce_add_plugin` call
        JUCE_USE_CURL=0     # If you remove this, add `NEEDS_CURL TRUE` to the `juce_add_plugin` call
        JUCE_VST3_CAN_REPLACE_VST2=0

        JUCE_PLUGINHOST_LV2=1
        JUCE_PLUGINHOST_VST3=1
        JUCE_PLUGINHOST_AUv2=1
)

target_link_libraries(Nodus
    PRIVATE
        juce::juce_audio_utils
    PUBLIC
        juce::juce_recommended_config_flags
        juce::juce_recommended_lto_flags
        juce::juce_recommended_warning_flags)

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_include_directories(Nodus
        PRIVATE
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/FlutterMacOS.framework/Headers
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/App.framework/Headers
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/Pods_Runner.framework/Headers
    )

    target_link_directories(Nodus
        PUBLIC
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/App.framework
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/FlutterMacOS.framework/
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/FlutterMacOS.framework/Versions/A/
    )

    set_target_properties(Nodus PROPERTIES LINK_FLAGS "-Wl,-F/Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/")
    target_link_libraries(Nodus PUBLIC "-framework FlutterMacOS")
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_include_directories(Nodus
        PRIVATE
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/FlutterMacOS.framework/Headers
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/App.framework/Headers
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/Pods_Runner.framework/Headers
    )

    target_link_directories(Nodus
        PUBLIC
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/App.framework
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/FlutterMacOS.framework/
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/FlutterMacOS.framework/Versions/A/
    )

    set_target_properties(Nodus PROPERTIES LINK_FLAGS "-Wl,-F/Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/")
    target_link_libraries(Nodus PUBLIC "-framework FlutterMacOS")
endif()

if(WIN32)
    #Windows specific code
elseif(APPLE)
    find_library(FLUTTER_LIB FlutterMacOS "/Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/")
    find_library(APP_LIB App "/Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/")
    target_link_libraries(Nodus PRIVATE ${FLUTTER_LIB})
    target_link_libraries(Nodus PRIVATE ${APP_LIB})
endif()