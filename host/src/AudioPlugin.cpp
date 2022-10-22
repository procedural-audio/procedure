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
    
    puts("Creating plugin gui");

    auto w = std::unique_ptr<AudioPluginWindow>(new AudioPluginWindow("Audio plugin", this));

    w->setUsingNativeTitleBar(true);
    w->setContentOwned(plugin->createEditor(), true);

    w->centreWithSize(w->getWidth(), w->getHeight());
    w->setVisible(true);

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

void AudioPlugin::prepareToPlay (double sampleRate, int samplesPerBlock) {
    plugin->prepareToPlay(sampleRate, samplesPerBlock);
}
