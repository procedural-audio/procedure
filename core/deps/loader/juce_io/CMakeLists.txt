cmake_minimum_required(VERSION 3.15)
project(NewPluginTemplate VERSION 0.0.1)

set (BaseTargetName JucePluginLoader)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../juce ${CMAKE_CURRENT_BINARY_DIR}/../juce)

add_library(${BaseTargetName} STATIC)

target_sources(${BaseTargetName} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/lib.cpp
)

target_include_directories(${BaseTargetName} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../juce/modules/juce_audio_basics
    ${CMAKE_CURRENT_SOURCE_DIR}/../juce/modules/juce_audio_devices
    ${CMAKE_CURRENT_SOURCE_DIR}/../juce/modules/juce_audio_processors
    #${CMAKE_CURRENT_SOURCE_DIR}/../juce/modules/juce_audio_utils
    ${CMAKE_CURRENT_SOURCE_DIR}/../juce/modules/juce_core
    ${CMAKE_CURRENT_SOURCE_DIR}/../juce/modules/juce_events
)    

#target_include_directories(${BaseTargetName} PRIVATE /usr/include/gtk-3.0)
#target_link_libraries(${BaseTargetName} PRIVATE gdk-3)

target_link_libraries(${BaseTargetName}
    PRIVATE
        juce::juce_audio_basics
        juce::juce_audio_devices
        juce::juce_audio_processors
        juce::juce_core
        juce::juce_events
        #juce::juce_audio_utils
    PUBLIC
        juce::juce_recommended_config_flags
        juce::juce_recommended_lto_flags
        juce::juce_recommended_warning_flags)

target_compile_definitions(${BaseTargetName}
    PUBLIC
        JUCE_WEB_BROWSER=0
        JUCE_PLUGINHOST_LV2=1
        JUCE_PLUGINHOST_VST3=1
        JUCE_PLUGINHOST_AUv2=1
)

# set_target_properties(${BaseTargetName} PROPERTIES XCODE_SCHEME_DISABLE_MAIN_THREAD_CHECKER=1)
# set_target_properties(${BaseTargetName} PROPERTIES XCODE_SCHEME_ARGUMENTS "")

# We're linking the modules privately, but we need to export
# their compile flags
#target_compile_definitions(${BaseTargetName}
#    PUBLIC
#        JUCE_WEB_BROWSER=0
#        JUCE_USE_CURL=0
        #JUCE_VST3_CAN_REPLACE_VST2=0
#        JucePlugin_Build_Standalone=1
#        JUCE_STANDALONE_APPLICATION=JucePlugin_Build_Standalone
#    INTERFACE
#        $<TARGET_PROPERTY:my_plugin_modules,COMPILE_DEFINITIONS>)

# We also need to export the include directories for the modules
#target_include_directories(${BaseTargetName}
#    INTERFACE
#        $<TARGET_PROPERTY:my_plugin_modules,INCLUDE_DIRECTORIES>)

#target_link_libraries(${BaseTargetName} PUBLIC
#        #"-Wl,--whole-archive rust/debug/libmetasampler_core.a -Wl,--no-whole-archive"
#        "-Wl,--export-dynamic -Wl,--whole-archive rust/release/libmetasampler_core.a -Wl,--no-whole-archive"
#        metasampler_core
#)

#juce_generate_juce_header(${BaseTargetName})
