#include "NodusProcessor.h"
#include "NodusEditor.h"

// #import "FlutterViewController.h"

#include "AudioPlugin.h"

NodusEditor::NodusEditor (NodusProcessor& p)
    : AudioProcessorEditor (&p), audioProcessor (p)
{
    setSize (800, 600);
    setResizable(true, true);
    setResizeLimits(400, 300, 2000, 1000);
    
    addAndMakeVisible(flutterView);
    // flutterView.setView(audioProcessor.flutterViewController.view);
}

NodusEditor::~NodusEditor()
{
}

void NodusEditor::paint (juce::Graphics& g)
{
    g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));
}

void NodusEditor::resized()
{
    flutterView.setBounds(getLocalBounds());
}
