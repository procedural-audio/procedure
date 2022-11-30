/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>
#include "NodusProcessor.h"

//==============================================================================
/**
*/
class NodusEditor  : public juce::AudioProcessorEditor
{
public:
    NodusEditor (NodusProcessor&);
    ~NodusEditor() override;

    //==============================================================================
    void paint (juce::Graphics&) override;
    void resized() override;

private:
    NodusProcessor& audioProcessor;
    juce::NSViewComponent flutterView;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (NodusEditor)
};
