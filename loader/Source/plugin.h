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

private:
    std::unique_ptr<juce::AudioPluginInstance> plugin;
    std::unique_ptr<DocumentWindow> window;
};

MyAudioPlugin* createAudioPlugin(juce::AudioPluginFormatManager* manager, String name) {
    for (auto format : manager->getFormats()) {
        auto locations = format->getDefaultLocationsToSearch();
        auto paths = format->searchPathsForPlugins(locations, false);

        for (auto path : paths) {

            if (path.contains("Diva")) {
                puts("Found diva plugin");

                OwnedArray<PluginDescription> descs;

                format->findAllTypesForFile(descs, path);

                for (auto desc : descs) {
                    if (desc->name.contains(name)) {
                        puts("Found instance to add");

                        juce::String error = "";

                        auto plugin = manager->createPluginInstance(*desc, 44100, 256, error);

                        if (plugin != nullptr) {
                            puts("Created diva plugin instance");
                            return new MyAudioPlugin(std::move(plugin));
                        } else {
                            puts("Failed to create plugin");
                            return nullptr;
                        }
                    }
                }
            }
        }
    }

    return nullptr;
}
