/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin processor.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

#import "FlutterViewController.h"
#import "FlutterChannels.h"

#include <dlfcn.h>

std::vector<std::unique_ptr<AudioPlugin>> plugins;

extern "C" void plugin_process_block(int moduleId, float** audio_buffers, int channels, int samples) {
    for (auto& plugin : plugins) {
        if (plugin->getModuleId() == moduleId) {
            auto audio = juce::AudioBuffer<float>(audio_buffers, channels, samples);
            auto midi = juce::MidiBuffer();
            
            plugin->processBlock(audio, midi);
            
            return;
        }
    }
    
    puts("Couldn't find loaded plugin to process");
}

std::unique_ptr<AudioPlugin> createAudioPlugin(int moduleId, juce::AudioPluginFormatManager* manager, String name, double sampleRate, int blockSize) {
    for (auto format : manager->getFormats()) {
        auto locations = format->getDefaultLocationsToSearch();
        auto paths = format->searchPathsForPlugins(locations, false);

        for (auto path : paths) {

            if (path.contains(name)) {
                puts("Found plugin");

                OwnedArray<PluginDescription> descs;

                format->findAllTypesForFile(descs, path);

                for (auto desc : descs) {
                    if (desc->name.contains(name)) {
                        puts("Found instance to add");

                        juce::String error = "";

                        auto plugin = manager->createPluginInstance(*desc, sampleRate, blockSize, error);

                        if (plugin != nullptr) {
                            puts("Created plugin instance");
                            return std::unique_ptr<AudioPlugin>(new AudioPlugin(moduleId, name, std::move(plugin)));
                        } else {
                            puts("Failed to create plugin");
                            return nullptr;
                        }
                    }
                }
            }
        }
    }

    return nullptr;
}

//==============================================================================
Flutter_juceAudioProcessor::Flutter_juceAudioProcessor()
#ifndef JucePlugin_PreferredChannelConfigurations
     : AudioProcessor (BusesProperties()
                     #if ! JucePlugin_IsMidiEffect
                      #if ! JucePlugin_IsSynth
                       .withInput  ("Input",  juce::AudioChannelSet::stereo(), true)
                      #endif
                       .withOutput ("Output", juce::AudioChannelSet::stereo(), true)
                     #endif
                       ), pluginFormatManager()
#endif
{
    // FlutterEngine *engine = [[FlutterEngine alloc] initWithName:@"io.flutter" project:nil allowHeadlessExecution:YES];
    // [engine runWithEntrypoint:nil];
    // [flutterViewController setInitialRoute:@"myApp"];
    // auto temp = [[FlutterViewController alloc] initWithProject:nil];
    
	puts("Created audio processor");
    flutterViewController = [[[FlutterViewController alloc] initWithNibName:nil bundle:nil] retain];
    // flutterViewController = [[[FlutterViewController alloc] initWithProject:nil nibName:nil bundle:nil] retain];
    
    // [flutterViewController.engine runWithEntrypoint:@"main"];
        
    auto codec = [FlutterJSONMessageCodec alloc];
    
    audioPluginsChannel = [
        FlutterBasicMessageChannel
        messageChannelWithName:@"AudioPlugins"
        binaryMessenger:flutterViewController.engine.binaryMessenger
        codec:codec
    ];
    
    [audioPluginsChannel setMessageHandler:audioPluginsCallback];
    
    pluginFormatManager.addDefaultFormats();
    
    for (auto format : pluginFormatManager.getFormats()) {
        if (format->canScanForPlugins()) {
            auto locations = format->getDefaultLocationsToSearch();
            auto paths = format->searchPathsForPlugins(locations, false);

            for (auto path : paths) {
                std::cout << path << std::endl;
            }
        }
    }
    
    // [audioPluginsChannel sendMessage:@32];
    
    #ifdef __APPLE__
        auto libPath = "/Users/chasekanipe/Github/nodus/build/out/core/release/libtonevision_core.dylib";
        handle = dlopen(libPath, RTLD_LAZY);
    #endif

    #ifdef __MINGW32__
        EDITTHIS();
    #endif

    #ifdef __linux__
        auto libPath = "./lib/libtonevision_core.so";
        handle = dlopen(libPath, RTLD_LAZY | RTLD_DEEPBIND);
    #endif

    if (handle) {
        ffiCreateHost = (FFIHost* (*)()) dlsym(handle, "ffi_create_host");
        ffiDestroyHost = (void (*)(FFIHost*)) dlsym(handle, "ffi_destroy_host");
        ffiHostPrepare = (void (*)(FFIHost*, uint32_t, uint32_t)) dlsym(handle, "ffi_host_prepare");
        ffiHostProcess = (void (*)(FFIHost*, float**, uint32_t, uint32_t, Event*, uint32_t)) dlsym(handle, "ffi_host_process");

        host = ffiCreateHost();

    } else {
        fprintf(stderr, "Error loading library: %s\n", dlerror());
        puts("Faild to open tonevision core");
        exit(0);
    }

    events.reserve(64);
}

Flutter_juceAudioProcessor::~Flutter_juceAudioProcessor()
{
    [flutterViewController release];
    plugins.clear();
    // ffiDestroyHost(host);
    // dlclose(handle);
}

void Flutter_juceAudioProcessor::pluginsMessage(juce::String message) {
    auto json = juce::JSON::parse(message);
    
    if (json["message"] == "create") {
        juce::String name = json["name"];
        int moduleId = json["module_id"];
        
        for (auto& plugin : plugins) {
            if (plugin->getName() == name && plugin->getModuleId() == moduleId) {
                puts("Plugin already loaded");
                return;
            }
        }
                
        auto plugin = createAudioPlugin(moduleId, &pluginFormatManager, name, sampleRate, samplesPerBlock);
        
        if (plugin != nullptr) {
            std::cout << "Created plugin " << name << " for module id " << moduleId << std::endl;
            
            for (int i = 0; i < plugins.size(); i++) {
                if (plugins[i]->getModuleId() == moduleId) {
                    puts("Removing old plugin");
                    plugins.erase(plugins.begin() + i);
                    break;
                }
            }
            
            plugin->createGui();
            
            plugins.push_back(std::move(plugin));
        } else {
            std::cout << "Failed to create plugin " << name << std::endl;
        }
    } else if (json["message"] == "show") {
        int moduleId = json["module_id"];
        
        puts("Showing gui");
        
        for (auto& plugin : plugins) {
            if (plugin->getModuleId() == moduleId) {
                puts("Found gui to show");
                plugin->showGui();
                return;
            }
        }
        
        puts("Couldn't find plugin for module id");
        
    } else if (json["message"] == "list plugins") {
        puts("SHOULD SEND PLUGIN LIST HERE");
    } else {
        std::cout << "Recieved message: " << message << std::endl;
    }
}

//==============================================================================
const juce::String Flutter_juceAudioProcessor::getName() const
{
    return JucePlugin_Name;
}

bool Flutter_juceAudioProcessor::acceptsMidi() const
{
   #if JucePlugin_WantsMidiInput
    return true;
   #else
    return false;
   #endif
}

bool Flutter_juceAudioProcessor::producesMidi() const
{
   #if JucePlugin_ProducesMidiOutput
    return true;
   #else
    return false;
   #endif
}

bool Flutter_juceAudioProcessor::isMidiEffect() const
{
   #if JucePlugin_IsMidiEffect
    return true;
   #else
    return false;
   #endif
}

double Flutter_juceAudioProcessor::getTailLengthSeconds() const
{
    return 0.0;
}

int Flutter_juceAudioProcessor::getNumPrograms()
{
    return 1;   // NB: some hosts don't cope very well if you tell them there are 0 programs,
                // so this should be at least 1, even if you're not really implementing programs.
}

int Flutter_juceAudioProcessor::getCurrentProgram()
{
    return 0;
}

void Flutter_juceAudioProcessor::setCurrentProgram (int index)
{
}

const juce::String Flutter_juceAudioProcessor::getProgramName (int index)
{
    return {};
}

void Flutter_juceAudioProcessor::changeProgramName (int index, const juce::String& newName)
{
}

//==============================================================================
void Flutter_juceAudioProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    this->sampleRate = sampleRate;
    this->samplesPerBlock = samplesPerBlock;
    
    std::cout << "prepareToPlay(" << sampleRate << ", " << samplesPerBlock << ")" << std::endl;

    if (ffiHostPrepare != nullptr && host != nullptr) {
        ffiHostPrepare(host, (uint32_t) sampleRate, (uint32_t) samplesPerBlock);
    }
}

void Flutter_juceAudioProcessor::releaseResources()
{
    // When playback stops, you can use this as an opportunity to free up any
    // spare memory, etc.
}

#ifndef JucePlugin_PreferredChannelConfigurations
bool Flutter_juceAudioProcessor::isBusesLayoutSupported (const BusesLayout& layouts) const
{
  #if JucePlugin_IsMidiEffect
    juce::ignoreUnused (layouts);
    return true;
  #else
    // This is the place where you check if the layout is supported.
    // In this template code we only support mono or stereo.
    // Some plugin hosts, such as certain GarageBand versions, will only
    // load plugins that support stereo bus layouts.
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
     && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

    // This checks if the input layout matches the output layout
   #if ! JucePlugin_IsSynth
    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;
   #endif

    return true;
  #endif
}
#endif

void Flutter_juceAudioProcessor::processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;
    auto totalNumInputChannels  = getTotalNumInputChannels();
    auto totalNumOutputChannels = getTotalNumOutputChannels();

    // In case we have more outputs than inputs, this code clears any output
    // channels that didn't contain input data, (because these aren't
    // guaranteed to be empty - they may contain garbage).
    // This is here to avoid people getting screaming feedback
    // when they first compile a plugin, but obviously you don't need to keep
    // this code if your algorithm always overwrites all the output channels.
    for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
        buffer.clear (i, 0, buffer.getNumSamples());

    // This is the place where you'd normally do the guts of your plugin's
    // audio processing...
    // Make sure to reset the state if your inner loop is processing
    // the samples and the outer loop is handling the channels.
    // Alternatively, you can process the samples with the channels
    // interleaved by keeping the same state.
    for (int channel = 0; channel < totalNumInputChannels; ++channel)
    {
        auto* channelData = buffer.getWritePointer (channel);
        juce::ignoreUnused (channelData);
        // ..do something to the data...
    }

    events.clear();

    for (auto data : midiMessages) {
        auto message = data.getMessage();

        if (message.isNoteOn()) {
            // std::cout << message.getDescription() << std::endl;

            Event event;
            event.tag = EventTag::NoteOn;

            EventValue value;
            value.noteOn = NoteOn {
                note: Note {
                    id: (unsigned short) message.getNoteNumber(),
                    pitch: (float) juce::MidiMessage::getMidiNoteInHertz(message.getNoteNumber()),
                    pressure: ((float) message.getVelocity()) / 127,
                    timbre: 0
                },
                offset: (uint16_t) data.samplePosition,
            };
            event.value = value;

            events.push_back(event);
        } else if (message.isNoteOff()) {
            // std::cout << message.getDescription() << std::endl;

            auto event = Event {
                tag: EventTag::NoteOff,
            };

            event.value.noteOff = NoteOff {
                id: (unsigned short) message.getNoteNumber()
            };

            events.push_back(event);
        }
    }

    if (ffiHostProcess != nullptr && host != nullptr) {
        if (events.size() == 0) {
            ffiHostProcess(host, buffer.getArrayOfWritePointers(), buffer.getNumChannels(), buffer.getNumSamples(), nullptr, 0);
        } else {
            ffiHostProcess(host, buffer.getArrayOfWritePointers(), buffer.getNumChannels(), buffer.getNumSamples(), &*events.begin(), events.size());
        }
    }
    
    /*for (auto& plugin : plugins) {
        plugin->processBlock(buffer, midiMessages);
    }*/
}

//==============================================================================
bool Flutter_juceAudioProcessor::hasEditor() const
{
    return true; // (change this to false if you choose to not supply an editor)
}

juce::AudioProcessorEditor* Flutter_juceAudioProcessor::createEditor()
{
    return new Flutter_juceAudioProcessorEditor (*this);
}

//==============================================================================
void Flutter_juceAudioProcessor::getStateInformation (juce::MemoryBlock& destData)
{
    // You should use this method to store your parameters in the memory block.
    // You could do that either as raw data, or use the XML or ValueTree classes
    // as intermediaries to make it easy to save and load complex data.
}

void Flutter_juceAudioProcessor::setStateInformation (const void* data, int sizeInBytes)
{
    // You should use this method to restore your parameters from this memory block,
    // whose contents will have been created by the getStateInformation() call.
}

//==============================================================================
// This creates new instances of the plugin..
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new Flutter_juceAudioProcessor();
}
