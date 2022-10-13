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
    // This reference is provided as a quick way for your editor to
    // access the processor object that created it.
    Flutter_juceAudioProcessor& audioProcessor;
    
    juce::NSViewComponent flutterView;

    juce::AudioPluginFormatManager pluginFormatManager;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (Flutter_juceAudioProcessorEditor)
};
