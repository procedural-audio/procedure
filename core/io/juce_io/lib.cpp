#include "juce_audio_basics.h"
#include "juce_audio_devices.h"
#include "juce_core.h"
#include "juce_events.h"
#include "juce_audio_processors.h"

#include <assert.h>
#include <chrono>
#include <iostream>

using namespace juce;

extern "C" void io_manager_callback(const float**, int, float**, int, int);

class IOManager : public AudioIODeviceCallback, public MidiInputCallback {
public:
    IOManager() {
        deviceManager.initialise(2, 2, nullptr, true);
        deviceManager.addAudioCallback(this);
        deviceManager.addMidiInputDeviceCallback("", this);
        collector.ensureStorageAllocated(512);
    }

    ~IOManager() {
        deviceManager.removeAudioCallback(this);
        deviceManager.removeMidiInputDeviceCallback("", this);
    }

    void audioDeviceAboutToStart(AudioIODevice *device) {
        puts("Audio device about to start");
    }

    void audioDeviceIOCallback(const float **inputChannelData, int numInputChannels, float **outputChannelData, int numOutputChannels, int numSamples) {
        io_manager_callback(inputChannelData, numInputChannels, outputChannelData, numOutputChannels, numSamples);
    }

    void audioDeviceStopped() {
        puts("Audio device stopped");
    }

    void handleIncomingMidiMessage(juce::MidiInput *source, const juce::MidiMessage &message) {
        collector.addMessageToQueue(message);
    }

    void setManager(void* m) {
        this->manager = m;
    }

private:
    void* manager;

    juce::MidiMessageCollector collector;
    juce::AudioDeviceManager deviceManager;
};

extern "C" IOManager* create_io_manager() {
    return new IOManager();
}

extern "C" void destroy_io_manager(IOManager* manager) {
    delete manager;
}

extern "C" void io_manager_set_manager(IOManager* manager, void* m) {
    manager->setManager(m);
}

class AudioPluginWindow : public DocumentWindow {
public:
    AudioPluginWindow() : DocumentWindow("Audio Plugin", Colours::grey, DocumentWindow::closeButton) {

    }

    ~AudioPluginWindow() {

    }

    void closeButtonPressed() {
        setVisible(false);
    }
};

class MyAudioPlugin {
public:
    MyAudioPlugin(std::unique_ptr<juce::AudioPluginInstance> p) {
        plugin.swap(p);
    }

    ~MyAudioPlugin() {

    }

    void createGui() {
        puts("Creating gui");

        juce::MessageManager::callAsync([this] {
            puts("Crate gui callback");

            auto w = std::unique_ptr<AudioPluginWindow>(new AudioPluginWindow());

            puts("Created plugin");

            w->setUsingNativeTitleBar(true);
            w->setContentOwned(plugin->createEditor(), true);
            w->centreWithSize(w->getWidth(), w->getHeight());
            w->setVisible(true);

            window.swap(w);
        });
    }

    void setInstance(std::unique_ptr<juce::AudioPluginInstance> instance) {
        this->plugin = std::move(instance);
    }

    void prepare(uint32_t sampleRate, size_t blockSize) {
        plugin->prepareToPlay((double) sampleRate, blockSize);
    }

    void process(juce::AudioBuffer<float>& audioBuffer, juce::MidiBuffer& midiBuffer) {
        puts("Processing in plugin");
        plugin->processBlock(audioBuffer, midiBuffer);
    }

private:
    std::unique_ptr<juce::AudioPluginInstance> plugin;
    std::unique_ptr<AudioPluginWindow> window;
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
                OwnedArray<PluginDescription> descs;
                format->findAllTypesForFile(descs, path); // THIS CAUSES KONTAKT CRASH ???

                for (auto desc : descs) {
                    if (desc->name.contains(name)) {
                        juce::String error = "";
                        if (manager->doesPluginStillExist(*desc)) {
                            puts("Creating plugin instance");
                            auto instance = manager->createPluginInstance(*desc, 44100, 256, error);
                            auto plugin = new MyAudioPlugin(std::move(instance));
                            return plugin;
                        } else {
                            puts("Can't create plugin instance");
                            return nullptr;
                        }
                    }
                }
            }
        }
    }

    return nullptr;
}

extern "C" void destroy_audio_plugin(MyAudioPlugin* plugin) {
    delete plugin;
}

extern "C" void audio_plugin_prepare(MyAudioPlugin* plugin, uint32_t sampleRate, size_t blockSize) {
    if (plugin != nullptr) {
        plugin->prepare(sampleRate, blockSize);
    }
}

extern "C" void audio_plugin_process(MyAudioPlugin* plugin, float **buffer, size_t channels, size_t samples) {
    if (plugin != nullptr) {
        auto audioBuffer = AudioBuffer<float>(buffer, channels, samples);
        auto midiBuffer = MidiBuffer();
        printf("Sample is %f\n", buffer[0][0]);
        plugin->process(audioBuffer, midiBuffer);
    }
}

extern "C" void audio_plugin_show_gui(MyAudioPlugin* plugin) {
    if (plugin != nullptr) {
        plugin->createGui();
    } else {
        puts("Plugin is nullptr, couldn't show gui");
    }
}