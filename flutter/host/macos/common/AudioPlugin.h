/*
  ==============================================================================

    plugin.h
    Created: 12 Oct 2022 7:46:31pm
    Author:  Chase Kanipe

  ==============================================================================
*/

#pragma once

#include <iostream>
#include <JuceHeader.h>

using namespace juce;

class AudioPluginWindow;

class AudioPlugin {
public:
    AudioPlugin(int moduleId, juce::String name, std::unique_ptr<juce::AudioPluginInstance> p);

    void createGui();
    void showGui();
    void hideGui();
    void processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages);
    void prepareToPlay (double sampleRate, int samplesPerBlock);
    int getModuleId() {
        return moduleId;
    }
    
    juce::String getName() {
        return name;
    }

private:
    std::unique_ptr<juce::AudioPluginInstance> plugin;
    std::unique_ptr<AudioPluginWindow> window;
    int moduleId;
    juce::String name;
};

class AudioPluginWindow : public juce::DocumentWindow {
public:
    AudioPluginWindow(juce::String name, AudioPlugin* plugin) : juce::DocumentWindow(name, juce::Colours::grey, juce::DocumentWindow::closeButton) {
        this->plugin = plugin;
    }
    
    void closeButtonPressed() override {
        plugin->hideGui();
    }
    
private:
    AudioPlugin* plugin;
};
