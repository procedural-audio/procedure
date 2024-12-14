#pragma once

#include <FlutterMacOS.h>

#undef Component
#undef Point

#include <JuceHeader.h>

#include "NodusProcessor.h"

class NodusEditor  : public juce::AudioProcessorEditor
{
public:
    NodusEditor (NodusProcessor& p)
        : AudioProcessorEditor (&p), audioProcessor (p)
    {
        initializeFlutter();
        addAndMakeVisible(nsViewComp);
    }

    ~NodusEditor() override
    {
        shutdownFlutter();
    }

    void paint(juce::Graphics& g) override
    {
        g.fillAll(juce::Colours::black);
    }

    void resized() override
    {
        nsViewComp.setBounds(getLocalBounds());
    }

private:
    NodusProcessor& audioProcessor;

    juce::NSViewComponent nsViewComp;

    FlutterEngine* engine = nullptr;
    FlutterViewController* flutterViewController = nullptr;
    FlutterDartProject* flutterProject = nullptr;

    juce::String icuDataPathUTF8 = "/Users/chasekanipe/Github/nodus/flutter/build/framework/Versions/A/Resources/icudtl.dat";
    juce::String assetsPathUTF8 = "/Users/chasekanipe/Github/nodus/build/out/flutter/flutter_assets";
    juce::String dartEntrypointUTF8 = "main";

    void initializeFlutter()
    {
        // Determine paths to Flutter assets and ICU data. 
        // Typically, these would be in your app’s resource bundle.
        NSString* bundlePath = [[NSBundle mainBundle] resourcePath];
        NSString* icuDataPath = [bundlePath stringByAppendingPathComponent:@"icudtl.dat"];
        NSString* assetsPath = [bundlePath stringByAppendingPathComponent:@"flutter_assets"];
        NSString* appAotPath = [bundlePath stringByAppendingPathComponent:@"app.so"]; // if using AOT snapshots; may not be needed if using JIT
        
        // Create a FlutterDartProject. Check FlutterDartProject.h for initialization methods.
        // The API for FlutterDartProject may vary depending on the Flutter version.
        flutterProject = [[FlutterDartProject alloc] init];
        if ([flutterProject respondsToSelector:@selector(setAssetsPath:)])
            [flutterProject setAssetsPath:assetsPath];
        if ([flutterProject respondsToSelector:@selector(setICUDataPath:)])
            [flutterProject setICUDataPath:icuDataPath];
        // If there's an API for setting the AOT snapshot or Dart entrypoint, do it here.
        // e.g. [flutterProject setVMData:appAotPath]; // Pseudocode, depends on Flutter version.

        // Create the Flutter engine. The name is an identifier; it can be anything unique.
        engine = [[FlutterEngine alloc] initWithName:@"com.example.flutter_engine"
                                            project:flutterProject
                            allowHeadlessExecution:NO];
        if (!engine)
        {
            DBG("Failed to create Flutter engine");
            return;
        }

        // Create a FlutterViewController associated with this engine
        flutterViewController = [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
        if (!flutterViewController) {
            DBG("Failed to create FlutterViewController");
            return;
        }

        // Assign the view controller to the engine BEFORE running the engine
        engine.viewController = flutterViewController;

        // Run the engine with the main Dart entrypoint.
        BOOL engineRan = [engine runWithEntrypoint:nil]; // nil defaults to `main()` in Dart.
        if (!engineRan)
        {
            DBG("Flutter engine failed to run");
            return;
        }

        // Get the Flutter NSView and embed it in the JUCE NSViewComponent.
        NSView* flutterNSView = flutterViewController.view;
        if (!flutterNSView)
        {
            DBG("No Flutter view available");
            return;
        }

        nsViewComp.setView(flutterNSView);
    }

    void shutdownFlutter()
    {
        // Shut down the engine. This stops the Dart isolate and cleans up resources.
        if (engine)
        {
            [engine shutDownEngine];
            engine = nil;
        }

        flutterViewController = nil;
        flutterProject = nil;
    }

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (NodusEditor)
};
