#include "NodusEditor.h"
#include "NodusProcessor.h"

// #import "FlutterViewController.h"

#include "AudioPlugin.h"

/*NodusEditor::NodusEditor (NodusProcessor& p) : AudioProcessorEditor (&p), audioProcessor (p)
{
    setOpaque(true);
    setSize(800, 600);
    
    // Create and host the NSView inside a NSViewComponent
    nativeView = [ [MetalView alloc] initWithFrame:NSMakeRect(0,0,(CGFloat)getWidth(),(CGFloat)getHeight())];
    nsViewComp.setView (nativeView);
    addAndMakeVisible(nsViewComp);

    initializeFlutter();
}*/
/*
NodusEditor::~NodusEditor()
{
    if (flutterEngine != nullptr)
    {
        FlutterEngineShutdown(flutterEngine);
    }

}

void NodusEditor::paint (juce::Graphics& g)
{
    g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));
}

void NodusEditor::resized()
{
    if (flutterEngine)
    {
        FlutterWindowMetricsEvent metrics = {};
        metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
        metrics.width = static_cast<size_t>(getWidth());
        metrics.height = static_cast<size_t>(getHeight());
        metrics.pixel_ratio = juce::Desktop::getInstance().getDisplays().getMainDisplay().scale;
        FlutterEngineSendWindowMetricsEvent(flutterEngine, &metrics);
    }
}
*/