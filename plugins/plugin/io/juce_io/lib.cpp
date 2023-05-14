#include "juce_audio_basics.h"
#include "juce_audio_devices.h"
#include "juce_core.h"
#include "juce_events.h"
#include "juce_audio_processors.h"

#include <assert.h>
#include <chrono>
#include <iostream>

using namespace juce;

enum class NoteTag: uint32_t {
    NoteOn,
    NoteOff,
    Pitch,
    Pressure,
    Other
};

struct NoteOn {
    float pitch;
    float pressure;
};

struct NoteOff {
};

struct Pitch {
    float freq;
};

struct Pressure {
    float pressure;
};

struct Other {
    char* s;
    size_t size;
    float value;
};

union NoteValue {
    NoteOn noteOn;
    NoteOff noteOff;
    Pitch pitch;
    Pressure pressure;
    Other other;
};

struct NoteMessage {
    uint64_t id;
    size_t offset;
    NoteTag tag;
    NoteValue value;
};

int pitchToNum(float pitch) {
    return (int) (round(log2(pitch / 440.0) * 12.0) + 69.0);
}

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
        setVisible(false);
    }

    void closeButtonPressed() {
        setVisible(false);
    }
};

void* pluginInitialiseCallback(void* data);

class MyAudioPlugin {
public:
    MyAudioPlugin(juce::PluginDescription desc, juce::AudioPluginFormatManager* manager) : description(desc), manager(manager) {
        midiBuffer.ensureSize(128);
        playing.reserve(64);
    }

    ~MyAudioPlugin() {

    }

    void initialise() {
        juce::String error = "";

        auto messageManager = juce::MessageManager::getInstance();
        if (messageManager->isThisTheMessageThread()) {
            puts("Creating plugin instance");
            std::cout << " > Name: " << description.name << std::endl;
            std::cout << " > Category: " << description.category << std::endl;
            std::cout << " > Manufacturer: " << description.manufacturerName << std::endl;

            auto instance = manager->createPluginInstance(description, 44100, 256, error);
            puts("Enabling all buses");
            instance->enableAllBuses();
            puts("Setting instance");
            setInstance(std::move(instance));

            juce::MessageManager::callAsync([this] {
                puts("Creating new window");
                auto w = std::unique_ptr<AudioPluginWindow>(new AudioPluginWindow());
                window.swap(w);
            });

            /*puts("Set using native title bar");
            w->setUsingNativeTitleBar(true);
            puts("Setting content owned");
            w->setContentOwned(plugin->createEditor(), true);
            puts("Setting resizable");
            w->setResizable(true, true);
            // w->centreWithSize(w->getWidth(), w->getHeight());
            puts("Setting visible");
            w->setVisible(true);

            puts("Swapping window");
            window.swap(w);*/
        } else {
            puts("Error: Initialised from not the message thread");
            exit(0);
        }
    }

    static MyAudioPlugin* create(juce::AudioPluginFormatManager* manager, juce::String name) {
        for (auto format : manager->getFormats()) {
            std::cout << "Found format with name " << format->getName() << std::endl;

            auto locations = format->getDefaultLocationsToSearch();
            auto paths = format->searchPathsForPlugins(locations, false);

            for (auto path : paths) {
                if (path.contains(name)) {
                    OwnedArray<PluginDescription> descs;
                    format->findAllTypesForFile(descs, path); // THIS CAUSES KONTAKT CRASH ???
                    // TODO: ^^^ Call this from message thread (not main thread)

                    for (auto desc : descs) {
                        if (desc->name.contains(name)) {
                            if (manager->doesPluginStillExist(*desc)) {
                                puts("Creating plugin instance");
                                auto plugin = new MyAudioPlugin(*desc, manager);
                                auto messageManager = juce::MessageManager::getInstance();
                                messageManager->callFunctionOnMessageThread(pluginInitialiseCallback, (void *) plugin);
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

        puts("Error: Failed to create plugin");
        return nullptr;
    }

    void showGui() {
        if (window == nullptr) {
            puts("Error: Showing GUI before it was created");
            return;
        }

        if (window->getContentComponent() == nullptr) {
            puts("Creating window content");
            juce::MessageManager::callAsync([this] {
                window->setContentOwned(plugin->createEditor(), true);
                window->setUsingNativeTitleBar(true);
                window->setInterceptsMouseClicks(true, true);
                window->setMouseClickGrabsKeyboardFocus(true);
                window->setResizable(true, true);
            });
        }

        juce::MessageManager::callAsync([this] {
            puts("Setting window visibility to true");
            window->setVisible(true);
            window->grabKeyboardFocus();
        });

        /*if (window == nullptr) {
            juce::MessageManager::callAsync([this] {
                puts("Creating GUI window");
                auto w = std::unique_ptr<AudioPluginWindow>(new AudioPluginWindow());

                puts("Set using native title bar");
                w->setUsingNativeTitleBar(true);
                w->setContentOwned(plugin->createEditor(), true);
                w->setResizable(true, true);
                // w->centreWithSize(w->getWidth(), w->getHeight());
                // puts("Set visible");
                // w->setVisible(true);

                puts("Swapping window");
                window.swap(w);
            });
        } else {
            puts("Showing GUI async");
            juce::MessageManager::callAsync([this] {
                puts("Showing GUI callback");
                // window->centreWithSize(window->getWidth(), window->getHeight());
                window->setVisible(true);
            });
        }*/
    }

    void setInstance(std::unique_ptr<juce::AudioPluginInstance> instance) {
        plugin = std::move(instance);
    }

    void prepare(uint32_t sampleRate, size_t blockSize) {
        if (plugin != nullptr) {
            plugin->prepareToPlay((double) sampleRate, blockSize);
        }
    }

    void process(float **buffer, size_t channels, size_t samples, NoteMessage *notes, size_t noteCount) {
        auto audioBuffer = AudioBuffer<float>(buffer, channels, samples);
        midiBuffer.clear();

        for (int i = 0; i < noteCount; i++) {
            NoteMessage message = notes[i];

            if (message.tag == NoteTag::NoteOn) {
                auto event = message.value.noteOn;
                auto newMessage = juce::MidiMessage::noteOn(0, pitchToNum(event.pitch), event.pressure * 127);
                midiBuffer.addEvent(newMessage, message.offset);
                playing.push_back(message);
            }

            if (message.tag == NoteTag::NoteOff) {
                int num = 0;
                int index = 0;

                for (int j = 0; j < playing.size(); j++) {
                    if (playing[j].id == message.id) {
                        num = pitchToNum(playing[j].value.noteOn.pitch);
                        index = j;
                        break;
                    }
                }

                if (num > 0) {
                    auto event = message.value.noteOff;
                    auto newMessage = juce::MidiMessage::noteOff(0, num);

                    playing.erase(playing.begin() + index);
                    midiBuffer.addEvent(newMessage, message.offset);
                } else {
                    puts("Failed to find noteOn event");
                }
            }
        }

        if (plugin != nullptr) {
            plugin->processBlock(audioBuffer, midiBuffer);
        }
    }

private:
    juce::PluginDescription description;
    juce::AudioPluginFormatManager* manager;
    std::unique_ptr<juce::AudioPluginInstance> plugin;
    std::unique_ptr<AudioPluginWindow> window = nullptr;
    juce::MidiBuffer midiBuffer = juce::MidiBuffer();
    std::vector<NoteMessage> playing;
};

void* pluginInitialiseCallback(void* data) {
    MyAudioPlugin* plugin = (MyAudioPlugin*) data;

    auto messageManager = juce::MessageManager::getInstance();
    if (messageManager->isThisTheMessageThread()) {
        plugin->initialise();
    } else {
        puts("Error: This is not the message thread");
        exit(0);
    }
}

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
    return MyAudioPlugin::create(manager, juce::String(name));
}

extern "C" void destroy_audio_plugin(MyAudioPlugin* plugin) {
    // juce::MessageManager::callAsync([plugin] {
        delete plugin;
    // });
}

extern "C" void audio_plugin_prepare(MyAudioPlugin* plugin, uint32_t sampleRate, size_t blockSize) {
    if (plugin != nullptr) {
        plugin->prepare(sampleRate, blockSize);
    }
}

extern "C" void audio_plugin_process(MyAudioPlugin* plugin, float **buffer, size_t channels, size_t samples, NoteMessage *notes, size_t noteCount) {
    if (plugin != nullptr) {
        plugin->process(buffer, channels, samples, notes, noteCount);
    }
}

extern "C" void audio_plugin_show_gui(MyAudioPlugin* plugin) {
    if (plugin != nullptr) {
        plugin->showGui();
    } else {
        puts("Plugin is nullptr, couldn't show gui");
    }
}
