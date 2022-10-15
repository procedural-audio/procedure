/*
  ==============================================================================

    AudioPlugin.cpp
    Created: 14 Oct 2022 2:16:14pm
    Author:  Chase Kanipe

  ==============================================================================
*/

#include <iostream>
#include <JuceHeader.h>

#include "AudioPlugin.h"

AudioPlugin::AudioPlugin(int moduleId, juce::String name, std::unique_ptr<juce::AudioPluginInstance> p) {
    this->name = name;
    this->moduleId = moduleId;
    plugin.swap(p);
}

void AudioPlugin::createGui() {
    if (window != nullptr) {
        puts("GUI already exists");
        showGui();
        return;
    }
    
    puts("Creating gui");

    auto w = std::unique_ptr<AudioPluginWindow>(new AudioPluginWindow("Audio plugin", this));

    puts("Created plugin");

    w->setUsingNativeTitleBar(true);
    puts("created title bar");
    w->setContentOwned(plugin->createEditor(), true);
    puts("created content owned");

    w->centreWithSize(w->getWidth(), w->getHeight());
    puts("center with size");
    w->setVisible(true);
    puts("set visible");

    window.swap(w);
}

void AudioPlugin::showGui() {
    window->setVisible(true);
}

void AudioPlugin::hideGui() {
    window->setVisible(false);
}

void AudioPlugin::processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) {
    plugin->processBlock(buffer, midiMessages);
}
