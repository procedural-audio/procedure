/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/

#include "NodusProcessor.h"
#include "NodusEditor.h"

#import "FlutterViewController.h"

#include "AudioPlugin.h"

//==============================================================================
NodusEditor::NodusEditor (NodusProcessor& p)
    : AudioProcessorEditor (&p), audioProcessor (p)
{
	puts("Created editor");
    
    setResizable(true, true);
    setResizeLimits(400, 300, 2000, 1000);
    
    addAndMakeVisible(flutterView);
    flutterView.setView(audioProcessor.flutterViewController.view);

    setSize (800, 600);
}

NodusEditor::~NodusEditor()
{
}

//==============================================================================
void NodusEditor::paint (juce::Graphics& g)
{
    // (Our component is opaque, so we must completely fill the background with a solid colour)
    g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));
}

void NodusEditor::resized()
{
    flutterView.setBounds(getLocalBounds());
    // This is generally where you'll want to lay out the positions of any
    // subcomponents in your editor..
}
