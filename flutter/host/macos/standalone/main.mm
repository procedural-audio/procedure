// #include "JuceHeader.h"

#include <Metal/Metal.h>
#include <QuartzCore/QuartzCore.h>
#import <AppKit/AppKit.h>

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
        if (getPeer() == nullptr)
            juce::Component::addToDesktop(0);

        nativeView = (void*)getPeer()->getNativeHandle();
        jassert(nativeView != nullptr);

        // Set up CAMetalLayer on the nativeView
        NSView* nsView = (NSView*)nativeView;
        nsView.wantsLayer = YES;
        metalLayer = [CAMetalLayer layer];
        metalLayer.device = MTLCreateSystemDefaultDevice();
        metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
        metalLayer.contentsScale = (CGFloat)getDesktopScaleFactor(); 
        metalLayer.drawableSize = CGSizeMake((CGFloat)getWidth() * metalLayer.contentsScale,
                                             (CGFloat)getHeight() * metalLayer.contentsScale);
        [nsView setLayer:metalLayer];
        [nsView setWantsLayer:YES];

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
            metrics.width = (size_t)getWidth();
            metrics.height = (size_t)getHeight();
            metrics.pixel_ratio = (double)getDesktopScaleFactor();

            FlutterEngineSendWindowMetricsEvent(engine, &metrics);

            std::cout << "Resized to " << metrics.width << "x" << metrics.height << " @ " << metrics.pixel_ratio << "x" << std::endl;

            if (metalLayer)
            {
                metalLayer.contentsScale = (CGFloat)getDesktopScaleFactor();
                metalLayer.drawableSize = CGSizeMake((CGFloat)getWidth() * metalLayer.contentsScale,
                                                     (CGFloat)getHeight() * metalLayer.contentsScale);
            CGFloat scale = (CGFloat)getDesktopScaleFactor();
            metalLayer.contentsScale = scale;
            metalLayer.drawableSize = CGSizeMake((CGFloat)getWidth() * scale,
                                             (CGFloat)getHeight() * scale);
            }
        }
    }

private:
    static FlutterMetalTexture getNextDrawableTextureCallback(void* user_data, const FlutterFrameInfo* frame_info) {
        std::cout << "getNextDrawableTextureCallback" << std::endl;
        FlutterComponent* comp = (FlutterComponent*)user_data;
        FlutterMetalTexture texture_desc = {};
        texture_desc.struct_size = sizeof(FlutterMetalTexture);

        if (!comp->metalLayer)
        {
            // If there's no metalLayer, return an empty texture (engine won't draw)
            return texture_desc;
        }

        id<CAMetalDrawable> drawable = [comp->metalLayer nextDrawable];
        if (!drawable)
        {
            std::cout << "No drawable available this frame" << std::endl;
            // No drawable available this frame
            return texture_desc;
        }

        // Retain the drawable so we can release it in the destruction callback
        CFRetain((__bridge CFTypeRef)(drawable));

        texture_desc.texture_id = 1; // Some arbitrary ID
        texture_desc.texture = (__bridge const void*)drawable.texture;
        texture_desc.user_data = (__bridge void*)drawable;
        texture_desc.destruction_callback = [](void* user_data) {
            // Release the drawable when Flutter is done with it
            if (user_data) CFRelease(user_data);
        };

        return texture_desc;
    }

    void initFlutterEngine()
    {
        if (engine != nullptr)
            return; // Already initialized

        id<MTLDevice> mtlDevice = metalLayer.device;
        id<MTLCommandQueue> commandQueue = [mtlDevice newCommandQueue];

        FlutterRendererConfig rendererConfig = {};
        rendererConfig.type = kMetal;
        rendererConfig.metal.struct_size = sizeof(FlutterMetalRendererConfig);
        rendererConfig.metal.device = (const void*)mtlDevice;
        rendererConfig.metal.present_command_queue = (const void*)commandQueue;

        rendererConfig.metal.get_next_drawable_callback = getNextDrawableTextureCallback;
        rendererConfig.metal.present_drawable_callback = [](void* user_data, const FlutterMetalTexture* texture) -> bool {
            // Present is optional when using a custom compositor, but here we just return true.
            // In a more complete example, you'd handle presenting the drawable if needed.
            return true;
        };
        rendererConfig.metal.external_texture_frame_callback = nullptr;

        FlutterProjectArgs projectArgs = {};
        projectArgs.struct_size = sizeof(FlutterProjectArgs);
        projectArgs.assets_path = assetsPathUTF8.toRawUTF8();
        projectArgs.icu_data_path = icuDataPathUTF8.toRawUTF8();
        projectArgs.custom_dart_entrypoint = dartEntrypointUTF8.toRawUTF8();

        // Pass "this" as user_data so we can access metalLayer in get_next_drawable_callback
        FlutterEngineResult result = FlutterEngineRun(FLUTTER_ENGINE_VERSION,
                                                      &rendererConfig,
                                                      &projectArgs,
                                                      this,
                                                      &engine);

        jassert(result == kSuccess);
        resized(); // Update initial size
    }

    FLUTTER_API_SYMBOL(FlutterEngine) engine = nullptr;
    void* nativeView = nullptr;
    CAMetalLayer* metalLayer = nullptr;

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