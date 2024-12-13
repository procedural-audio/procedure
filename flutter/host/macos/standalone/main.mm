// #include "JuceHeader.h"

#include <Metal/Metal.h>
#include <QuartzCore/QuartzCore.h>

#undef Point
#undef Component

#include <juce_gui_basics/juce_gui_basics.h>

#include "FlutterEmbedder.h"
#include "NodusProcessor.h"
#include "NodusEditor.h"

class FlutterComponent : public juce::Component
{
public:
    FlutterComponent(const juce::String& icuDataPath,
                     const juce::String& assetsPath,
                     const juce::String& dartEntrypoint = "main")
        : icuDataPathUTF8(icuDataPath.toUTF8()),
          assetsPathUTF8(assetsPath.toUTF8()),
          dartEntrypointUTF8(dartEntrypoint.toUTF8())
    {
        setOpaque(true);
    }

    ~FlutterComponent() override
    {
        if (engine != nullptr)
        {
            FlutterEngineShutdown(engine);
            engine = nullptr;
        }
    }

    void addToDesktop()
    {
        // Ensure the component has a peer. The peer is created when the component is added to a window.
        if (getPeer() == nullptr)
            juce::Component::addToDesktop(0);

        // On macOS, getNativeHandle() returns an NSView*.
        nativeView = (void*)getPeer()->getNativeHandle();
        jassert(nativeView != nullptr);

        initFlutterEngine();
    }

    void paint(juce::Graphics& g) override
    {
        g.fillAll(juce::Colours::black);
    }

    void resized() override
    {
        if (engine != nullptr)
        {
            FlutterWindowMetricsEvent metrics = {};
            metrics.struct_size = sizeof(metrics);
            metrics.width = (size_t) getWidth();
            metrics.height = (size_t) getHeight();
            metrics.pixel_ratio = 1.0; // Adjust if you have a HiDPI display

            FlutterEngineSendWindowMetricsEvent(engine, &metrics);
        }
    }

private:
    void initFlutterEngine()
    {
        if (engine != nullptr)
            return; // Already initialized

        // Create a Metal device and command queue
        id<MTLDevice> mtlDevice = MTLCreateSystemDefaultDevice();
        id<MTLCommandQueue> commandQueue = [mtlDevice newCommandQueue];

        FlutterRendererConfig rendererConfig = {};
        rendererConfig.type = kMetal;
        rendererConfig.metal.struct_size = sizeof(FlutterMetalRendererConfig);
        rendererConfig.metal.device = (const void*)mtlDevice; // id<MTLDevice>
        rendererConfig.metal.present_command_queue = (const void*)commandQueue; // id<MTLCommandQueue>

        // When not using a custom compositor, Flutter needs callbacks to get surfaces.
        // Since we're just embedding a single view, we can provide basic callbacks.
        // However, in recent versions of the embedder API, these are only needed
        // if you're not using a compositor. For a minimal example, assume we do not have one:
        rendererConfig.metal.get_next_drawable_callback = [](void* user_data,
                                                             const FlutterFrameInfo* frame_info) -> FlutterMetalTexture {
            // Flutter requests a texture to render into. We must return a FlutterMetalTexture.
            // In a real application, you'd create or re-use a CAMetalLayer drawable's texture here.
            // This code is incomplete and must be filled in with real logic.

            // For demonstration, pretend we have a CAMetalLayer and get its next drawable:
            FlutterMetalTexture emptyTexture = {};
            emptyTexture.struct_size = sizeof(FlutterMetalTexture);

            // The embedder expects a valid texture. You must set:
            // emptyTexture.texture = <id<MTLTexture>>;
            // emptyTexture.texture_id = some_int64_id;
            // emptyTexture.destruction_callback = ...;
            // For now, we just return something invalid, as implementing a full Metal pipeline is non-trivial.
            // You must integrate with a CAMetalLayer and present actual textures.
            return emptyTexture;
        };

        rendererConfig.metal.present_drawable_callback = [](void* user_data, const FlutterMetalTexture* texture) -> bool {
            // Present the texture. Typically, you'd take the texture_id or user_data and present the drawable.
            return true;
        };

        // No external textures in this example
        rendererConfig.metal.external_texture_frame_callback = nullptr;

        FlutterProjectArgs projectArgs = {};
        projectArgs.struct_size = sizeof(FlutterProjectArgs);
        projectArgs.assets_path = assetsPathUTF8.toRawUTF8();
        projectArgs.icu_data_path = icuDataPathUTF8.toRawUTF8();
        projectArgs.custom_dart_entrypoint = dartEntrypointUTF8.toRawUTF8();

        // Attach to the view. On macOS, engine expects the NSView pointer via FlutterEngineRun
        // using FlutterProjectArgs. We have to specify the 'embedder has platform task runner' or
        // we rely on default. For simplicity, skip custom task runners.

        // Run the engine:
        FlutterEngineResult result = FlutterEngineRun(
            FLUTTER_ENGINE_VERSION, &rendererConfig,
            &projectArgs, this, &engine);

        jassert(result == kSuccess);

        resized(); // Send initial sizing info
    }

    FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
    void* nativeView = nullptr;

    juce::String icuDataPathUTF8;
    juce::String assetsPathUTF8;
    juce::String dartEntrypointUTF8;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(FlutterComponent)
};

class GuiAppApplication final : public juce::JUCEApplication, public juce::AudioIODeviceCallback, public juce::MidiInputCallback {
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
            // setUsingNativeTitleBar(false);
            // setTitleBarHeight(0);

            auto flutterComp = new FlutterComponent("/Users/chasekanipe/Github/nodus/flutter/build/framework/Versions/A/Resources/icudtl.dat",
                                                    "/Users/chasekanipe/Github/nodus/build/out/flutter/flutter_assets",
                                                    "main");
            setContentOwned(flutterComp, true);
            flutterComp->addToDesktop();

            // setContentOwned(new NodusEditor(processor), true);
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

    class SettingsWindow : public juce::DocumentWindow
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