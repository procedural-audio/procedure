#pragma once

#include <JuceHeader.h>

#include "nodus.h"

// #include <Metal/Metal.h>
// #import <AppKit/AppKit.h>

// #import "FlutterChannels.h"

struct FFIHost {};

class NodusProcessor  : public juce::AudioProcessor
{
public:
    NodusProcessor();
    ~NodusProcessor() override;

    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;

   #ifndef JucePlugin_PreferredChannelConfigurations
    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;
   #endif

    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;

    const juce::String getName() const override;

    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;

    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram (int index) override;
    const juce::String getProgramName (int index) override;
    void changeProgramName (int index, const juce::String& newName) override;

    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;
    
    void pluginsMessage(juce::String message);
    void addAudioPlugin(int moduleId, juce::String name);
    
    // FlutterBasicMessageChannel* audioPluginsChannel;

private:
    FFIHost* core = nullptr;
    std::vector<NoteMessage> events;

    void * handle = nullptr;

    void (*preparePatch) (double, uint32_t) = nullptr;
    void (*processPatch) (float *const *, uint32_t, uint32_t, uint8_t*, uint32_t) = nullptr;

    FFIHost* (*ffiCreateHost)() = nullptr;
    void (*ffiDestroyHost)(FFIHost*) = nullptr;
    void (*ffiHostPrepare)(FFIHost*, uint32_t, uint32_t) = nullptr;
    void (*ffiHostProcess)(FFIHost*, float**, uint32_t, uint32_t, NoteMessage*, uint32_t) = nullptr;
    
    /*void (^audioPluginsCallback)(id _Nullable, FlutterReply  _Nonnull) = ^(id _Nullable encoded, FlutterReply _Nonnull callback) {
        if (encoded) {
            NSString *message = encoded;
            pluginsMessage(juce::String([message UTF8String]));
        } else {
            puts("Got null message");
        }
    };*/

    juce::AudioPluginFormatManager pluginFormatManager;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (NodusProcessor)
};
