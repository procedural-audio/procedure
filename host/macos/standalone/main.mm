#include "NodusProcessor.h"
#include "NodusEditor.h"
#include "JuceHeader.h"

class GuiAppApplication  : public juce::JUCEApplication, public juce::AudioIODeviceCallback, public juce::MidiInputCallback {
public:
    GuiAppApplication() {

    }

    const juce::String getApplicationName() override       { return "Procedural Audio Workstation"; }
    const juce::String getApplicationVersion() override    { return "0.0.0"; }
    bool moreThanOneInstanceAllowed() override             { return true; }

    void initialise (const juce::String& commandLine) override
    {
        puts("Called initialise");
        juce::ignoreUnused (commandLine);

        manager.initialise(2, 2, nullptr, true);
        manager.addAudioCallback(this);
        manager.addMidiInputDeviceCallback("", this);

        collector.ensureStorageAllocated(2048);
        midiBuffer.ensureSize(2048);

        mainWindow.reset (new MainWindow (getApplicationName(), processor));
        settingsWindow.reset (new SettingsWindow(manager));
    }

    void shutdown() override
    {
        manager.removeAudioCallback(this);
        manager.removeMidiInputDeviceCallback("", this);
        mainWindow = nullptr;
        settingsWindow = nullptr;
    }

    void systemRequestedQuit() override
    {
        quit();
    }

    void anotherInstanceStarted (const juce::String& commandLine) override
    {
        juce::ignoreUnused (commandLine);
    }

    void audioDeviceAboutToStart(AudioIODevice *device) {
        puts("Audio device about to start");
        processor.prepareToPlay(device->getCurrentSampleRate(), device->getCurrentBufferSizeSamples());
    }

    void audioDeviceIOCallback(const float **inputChannelData, int numInputChannels, float **outputChannelData, int numOutputChannels, int numSamples) {
        auto audioBuffer = juce::AudioBuffer<float>(outputChannelData, numOutputChannels, numSamples);
        midiBuffer.clear();
        collector.removeNextBlockOfMessages(midiBuffer, numSamples);
        processor.processBlock(audioBuffer, midiBuffer);
    }

    void audioDeviceStopped() {
        puts("Audio device stopped");
    }

    void handleIncomingMidiMessage(juce::MidiInput *source, const juce::MidiMessage &message) {
        collector.addMessageToQueue(message);
    }

    class MainWindow : public juce::DocumentWindow
    {
    public:
        explicit MainWindow (juce::String name, NodusProcessor& processor)
            : DocumentWindow (name,
                              juce::Desktop::getInstance().getDefaultLookAndFeel()
                                                          .findColour (ResizableWindow::backgroundColourId),
                              DocumentWindow::allButtons)
        {
            setUsingNativeTitleBar (true);
            setContentOwned(new NodusEditor(processor), true);
            setBackgroundColour(juce::Colour::fromRGB(90, 90, 90));

           #if JUCE_IOS || JUCE_ANDROID
            setFullScreen (true);
           #else
            setResizable (true, true);
            centreWithSize(1200, 900);
           #endif

            setVisible (true);
        }

        void closeButtonPressed() override
        {
            JUCEApplication::getInstance()->systemRequestedQuit();
        }

    private:
        JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (MainWindow)
    };

    class SettingsWindow    : public juce::DocumentWindow
    {
    public:
        explicit SettingsWindow (juce::AudioDeviceManager& manager)
            : DocumentWindow ("Audio/Midi Settings",
                                juce::Desktop::getInstance().getDefaultLookAndFeel()
                                    .findColour (ResizableWindow::backgroundColourId),
                                        DocumentWindow::allButtons)
        {
            setUsingNativeTitleBar (true);
            setContentOwned(new juce::AudioDeviceSelectorComponent(manager, 2, 2, 2, 2, true, true, true, true), true);
            setVisible (true);
            centreWithSize(400, 600);
        }

        void closeButtonPressed() override
        {
            setVisible(false);
        }

    private:
        JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (SettingsWindow)
    };

private:
    NodusProcessor processor;
    std::unique_ptr<MainWindow> mainWindow;
    std::unique_ptr<SettingsWindow> settingsWindow;
    juce::AudioDeviceManager manager;

    juce::MidiMessageCollector collector;
    juce::MidiBuffer midiBuffer;
};

START_JUCE_APPLICATION (GuiAppApplication)