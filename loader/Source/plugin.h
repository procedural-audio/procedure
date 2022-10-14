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

class MyAudioPlugin {
public:
    MyAudioPlugin(std::unique_ptr<juce::AudioPluginInstance> p) {
        plugin.swap(p);
    }

    ~MyAudioPlugin() {

    }

    void createGui() {
        if (window != nullptr) {
            puts("GUI already exists");
        }
        
        puts("Creating gui");

        auto w = std::unique_ptr<DocumentWindow>(new DocumentWindow("Audio plugin", Colours::grey, DocumentWindow::allButtons));

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
    
    void hide() {
        window.reset();
    }
    
    void processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages) {
        plugin->processBlock(buffer, midiMessages);
    }

private:
    std::unique_ptr<juce::AudioPluginInstance> plugin;
    std::unique_ptr<DocumentWindow> window;
};
