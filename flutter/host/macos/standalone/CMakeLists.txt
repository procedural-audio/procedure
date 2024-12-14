juce_add_gui_app(NodusStandalone
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
    FORMATS Standalone VST3 AUv3              # The formats to build. Other valid formats are: AAX Unity VST AU AUv3
    PRODUCT_NAME "NodusStandalone")                       # The name of the final executable, which can differ from the target name

juce_generate_juce_header(NodusStandalone)

target_sources(NodusStandalone
    PRIVATE
        main.mm
        ../common/NodusProcessor.mm
        ../common/AudioPlugin.cpp
)

set_target_properties(NodusStandalone PROPERTIES
    MACOSX_RPATH ON
    BUILD_RPATH "@executable_path/../Frameworks"
    INSTALL_RPATH "@executable_path/../Frameworks"
)

target_compile_definitions(NodusStandalone
    PUBLIC
        JUCE_WEB_BROWSER=0  # If you remove this, add `NEEDS_WEB_BROWSER TRUE` to the `juce_add_plugin` call
        JUCE_USE_CURL=0     # If you remove this, add `NEEDS_CURL TRUE` to the `juce_add_plugin` call
        JUCE_VST3_CAN_REPLACE_VST2=0

        JUCE_PLUGINHOST_LV2=1
        JUCE_PLUGINHOST_VST3=1
        JUCE_PLUGINHOST_AUv2=1
)

target_link_libraries(NodusStandalone
    PRIVATE
        juce::juce_audio_utils
    PUBLIC
        juce::juce_recommended_config_flags
        juce::juce_recommended_lto_flags
        juce::juce_recommended_warning_flags)

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_include_directories(NodusStandalone
        PRIVATE
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/FlutterMacOS.framework/Headers
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/App.framework/Headers
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/Pods_Runner.framework/Headers
    )

    target_link_directories(NodusStandalone
        PUBLIC
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/App.framework
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/FlutterMacOS.framework/
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/FlutterMacOS.framework/Versions/A/
    )

    set_target_properties(NodusStandalone PROPERTIES LINK_FLAGS "-Wl,-F/Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/")
    target_link_libraries(NodusStandalone PUBLIC "-framework FlutterMacOS")

    find_library(FLUTTER_LIB FlutterMacOS "/Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/")
    find_library(APP_LIB App "/Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Debug/")

    target_link_libraries(NodusStandalone PRIVATE ${FLUTTER_LIB})
    target_link_libraries(NodusStandalone PRIVATE ${APP_LIB})
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_include_directories(NodusStandalone
        PRIVATE
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/FlutterMacOS.framework/Headers
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/App.framework/Headers
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/Pods_Runner.framework/Headers
    )

    target_link_directories(NodusStandalone
        PUBLIC
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/App.framework
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/FlutterMacOS.framework/
            /Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/FlutterMacOS.framework/Versions/A/
    )

    set_target_properties(NodusStandalone PROPERTIES LINK_FLAGS "-Wl,-F/Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/")
    target_link_libraries(NodusStandalone PUBLIC "-framework FlutterMacOS")

    find_library(FLUTTER_LIB FlutterMacOS "/Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/")
    find_library(APP_LIB App "/Users/chasekanipe/Github/nodus/build/out/flutter/macos/Build/Products/Release/")

    target_link_libraries(NodusStandalone PRIVATE ${FLUTTER_LIB})
    target_link_libraries(NodusStandalone PRIVATE ${APP_LIB})
endif()
