/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin processor.

  ==============================================================================
*/

#pragma once

#include "FlutterEngine.h"
#include <JuceHeader.h>

#include "nodus.h"
#include "AudioPlugin.h"

#import "FlutterChannels.h"

struct FFIHost {};

//==============================================================================

class Flutter_juceAudioProcessor  : public juce::AudioProcessor
{
public:
    //==============================================================================
    Flutter_juceAudioProcessor();
    ~Flutter_juceAudioProcessor() override;

    //==============================================================================
    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;

   #ifndef JucePlugin_PreferredChannelConfigurations
    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;
   #endif

    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    //==============================================================================
    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;

    //==============================================================================
    const juce::String getName() const override;

    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;

    //==============================================================================
    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram (int index) override;
    const juce::String getProgramName (int index) override;
    void changeProgramName (int index, const juce::String& newName) override;

    //==============================================================================
    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;
    
    void pluginsMessage(juce::String message);

public:
    FlutterViewController* flutterViewController { nullptr };
    
    FlutterBasicMessageChannel* audioPluginsChannel;
    
private:
    FFIHost* host = nullptr;
    
    std::vector<Event> events;

    void * handle = nullptr;

    FFIHost* (*ffiCreateHost)() = nullptr;
    void (*ffiDestroyHost)(FFIHost*) = nullptr;
    void (*ffiHostPrepare)(FFIHost*, uint32_t, uint32_t) = nullptr;
    void (*ffiHostProcess)(FFIHost*, float**, uint32_t, uint32_t, Event*, uint32_t) = nullptr;
    
    void (^audioPluginsCallback)(id _Nullable, FlutterReply  _Nonnull) = ^(id _Nullable encoded, FlutterReply _Nonnull callback) {
        if (encoded) {
            NSString *message = encoded;
            pluginsMessage(juce::String([message UTF8String]));
        } else {
            puts("Got null message");
        }
    };
    
    double sampleRate = 0;
    int samplesPerBlock = 0;
    
    
    juce::AudioPluginFormatManager pluginFormatManager;
    
    //==============================================================================
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (Flutter_juceAudioProcessor)
};
