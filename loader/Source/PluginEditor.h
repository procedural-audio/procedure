/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>
#include "PluginProcessor.h"

//==============================================================================
/**
*/
class Flutter_juceAudioProcessorEditor  : public juce::AudioProcessorEditor
{
public:
    Flutter_juceAudioProcessorEditor (Flutter_juceAudioProcessor&);
    ~Flutter_juceAudioProcessorEditor() override;

    //==============================================================================
    void paint (juce::Graphics&) override;
    void resized() override;

private:
    Flutter_juceAudioProcessor& audioProcessor;
    juce::NSViewComponent flutterView;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (Flutter_juceAudioProcessorEditor)
};
