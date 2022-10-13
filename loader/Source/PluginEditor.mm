/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

#import "FlutterViewController.h"

#include "plugin.h"

//==============================================================================
Flutter_juceAudioProcessorEditor::Flutter_juceAudioProcessorEditor (Flutter_juceAudioProcessor& p)
    : AudioProcessorEditor (&p), audioProcessor (p), pluginFormatManager()
{
	puts("Created editor");
    
    setResizable(true, true);
    setResizeLimits(400, 300, 2000, 1000);
    
    addAndMakeVisible(flutterView);
    flutterView.setView(audioProcessor.flutterViewController.view);

    setSize (800, 600);
    
    puts("Adding default formats");
    pluginFormatManager.addDefaultFormats();
    
    for (auto format : pluginFormatManager.getFormats()) {
        puts("Found format");
        if (format->canScanForPlugins()) {
            auto locations = format->getDefaultLocationsToSearch();
            auto paths = format->searchPathsForPlugins(locations, false);

            for (auto path : paths) {
                std::cout << path << std::endl;
            }
        }
    }
    
    auto plugin = createAudioPlugin(&pluginFormatManager, "Diva");
    
    if (plugin != nullptr) {
        plugin->createGui();
    } else {
        puts("Failed to load plugin");
    }
}

Flutter_juceAudioProcessorEditor::~Flutter_juceAudioProcessorEditor()
{
}

//==============================================================================
void Flutter_juceAudioProcessorEditor::paint (juce::Graphics& g)
{
    // (Our component is opaque, so we must completely fill the background with a solid colour)
    g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));
}

void Flutter_juceAudioProcessorEditor::resized()
{
    flutterView.setBounds(getLocalBounds());
    // This is generally where you'll want to lay out the positions of any
    // subcomponents in your editor..
}
