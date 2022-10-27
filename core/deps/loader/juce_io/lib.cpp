#include "juce_audio_basics.h"
#include "juce_audio_devices.h"
#include "juce_core.h"
#include "juce_events.h"
#include "juce_audio_processors.h"

#include <assert.h>
#include <chrono>
#include <iostream>

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

        try {
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
        } catch (...) {
            puts("Exception in GUI creation");
        }
    }

private:
    std::unique_ptr<juce::AudioPluginInstance> plugin;
    std::unique_ptr<DocumentWindow> window;
};

extern "C" juce::AudioPluginFormatManager* create_audio_plugin_manager() {
    puts("Creating plugin format manager");

    auto manager = new juce::AudioPluginFormatManager();

    manager->addDefaultFormats();

    for (auto format : manager->getFormats()) {
        puts("Found format");
        if (format->canScanForPlugins()) {
            auto locations = format->getDefaultLocationsToSearch();
            auto paths = format->searchPathsForPlugins(locations, false);

            for (auto path : paths) {
                std::cout << path << std::endl;
            }
        }
    }

    return manager;
}

extern "C" void destroy_audio_plugin_manager(juce::AudioPluginFormatManager* manager) {
    delete manager;
}

extern "C" MyAudioPlugin* create_audio_plugin(juce::AudioPluginFormatManager* manager, char* name) {
    for (auto format : manager->getFormats()) {
        std::cout << "Found format with name " << format->getName() << std::endl;

        auto locations = format->getDefaultLocationsToSearch();
        auto paths = format->searchPathsForPlugins(locations, false);

        for (auto path : paths) {

            if (path.contains(name)) {
                puts("Found hardcoded plugin");

                OwnedArray<PluginDescription> descs;

                format->findAllTypesForFile(descs, path);

                for (auto desc : descs) {
                    if (desc->name.contains(name)) {
                        puts("Found instance to add");

                        juce::String error = "";

                        auto plugin = manager->createPluginInstance(*desc, 44100, 256, error);

                        if (plugin != nullptr) {
                            puts("Created plugin instance");
                            return new MyAudioPlugin(std::move(plugin));
                        } else {
                            puts("Failed to create plugin");
                            return nullptr;
                        }
                    }
                }

                break;
            }
        }
    }

    return nullptr;
}

extern "C" void audio_plugin_show_gui(MyAudioPlugin* plugin) {
    if (plugin != nullptr) {
        plugin->createGui();
    } else {
        puts("Plugin is nullptr, couldn't show gui");
    }
}