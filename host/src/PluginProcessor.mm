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

extern "C" void plugin_process_block(uint32_t moduleId, float** audio_buffers, uint32_t channels, uint32_t samples, Event* events, uint32_t events_count) {
    auto audio = juce::AudioBuffer<float>(audio_buffers, channels, samples);
    auto midi = juce::MidiBuffer();

    for (int i = 0; i < events_count; i++) {
        Event event = events[i];
        puts("Added event to plugin process");

        if (event.tag == EventTag::NoteOn) {
            auto message = juce::MidiMessage::noteOn(0, event.value.noteOn.note.id, (uint8_t) 127 * event.value.noteOn.note.pressure);
            midi.addEvent(message, 0);
        } else if (event.tag == EventTag::NoteOff) {
            auto message = juce::MidiMessage::noteOff(0, event.value.noteOff.id);
            midi.addEvent(message, 0);
        }
    }

    /*auto message = data.getMessage();

    if (message.isNoteOn()) {
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
        auto event = Event {
            tag: EventTag::NoteOff,
        };

        event.value.noteOff = NoteOff {
            id: (unsigned short) message.getNoteNumber()
        };

        events.push_back(event);
    }*/

    for (auto& plugin : plugins) {
        if (plugin->getModuleId() == moduleId) {
            // auto audio2 = juce::AudioBuffer<float>(channels, samples);
            // audio2.copyFrom(0, 0, audio_buffers[0], samples);
            // audio2.copyFrom(1, 0, audio_buffers[1], samples);

            float input = audio.getArrayOfReadPointers()[0][0];

            plugin->processBlock(audio, midi);

            // audio.copyFrom(0, 0, audio2, 0, 0, samples);
            // audio.copyFrom(1, 0, audio2, 1, 0, samples);

            float output = audio.getArrayOfReadPointers()[0][0];

            // std::cout << "Processed " << channels << " channels with " << samples << " samples. " << input << " -> " << output << std::endl;

            return;
        }
    }
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

        core = ffiCreateHost();
    } else {
        fprintf(stderr, "Error loading library: %s\n", dlerror());
        puts("Faild to open tonevision core");
        exit(0);
    }

    events.reserve(64);
    
    // FlutterEngine *engine = [[FlutterEngine alloc] initWithName:@"io.flutter" project:nil allowHeadlessExecution:YES];
    // [engine runWithEntrypoint:nil];
    // [flutterViewController setInitialRoute:@"myApp"];
    // auto temp = [[FlutterViewController alloc] initWithProject:nil];
    
    // Old initializer
    // flutterViewController = [[[FlutterViewController alloc] initWithNibName:nil bundle:nil] retain];
    
    // Build arguments
    std::string s1 = "core: ";
    std::string s2 = s1.append(std::to_string((long) core));
    NSString *s3 = [NSString stringWithCString:s2.c_str() encoding:[NSString defaultCStringEncoding]];

    std::string s4 = "host: ";
    std::string s5 = s1.append(std::to_string((long) this));
    NSString *s6 = [NSString stringWithCString:s2.c_str() encoding:[NSString defaultCStringEncoding]];

    NSArray<NSString*>* args = @[s3, s6];
    FlutterDartProject* project = [[[FlutterDartProject alloc] initWithPrecompiledDartBundle:nil] retain];
    project.dartEntrypointArguments = args;
    flutterViewController = [[[FlutterViewController alloc] initWithProject:project] retain];
        
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
        
        addAudioPlugin(moduleId, name);
        
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
    } else if (json["message"] == "get process") {
        std::string s1 = "process addr ";
        std::string s2 = s1.append(std::to_string((long) &plugin_process_block));
        NSString *s3 = [NSString stringWithCString:s2.c_str() encoding:[NSString defaultCStringEncoding]];
        [audioPluginsChannel sendMessage:s3];
    } else {
        std::cout << "Recieved message: " << message << std::endl;
    }
}

void Flutter_juceAudioProcessor::addAudioPlugin(int moduleId, juce::String name) {
    for (auto format : pluginFormatManager.getFormats()) {
        auto locations = format->getDefaultLocationsToSearch();
        auto paths = format->searchPathsForPlugins(locations, false);

        for (auto path : paths) {

            if (path.contains(name)) {
                OwnedArray<PluginDescription> descs;

                format->findAllTypesForFile(descs, path);

                for (auto desc : descs) {
                    if (desc->name.contains(name)) {
                        juce::String error = "";
                        
                        desc->numInputChannels = 2;
                        desc->numOutputChannels = 2;
                        
                        pluginFormatManager.createPluginInstanceAsync(
                            *desc,
                            getSampleRate(),
                            getBlockSize(),
                            [this, moduleId, name] (std::unique_ptr<AudioPluginInstance> instance, const juce::String& error) {
                                std::cout << "Created plugin " << instance->getName() << " for module id " << moduleId << std::endl;

                                instance->enableAllBuses();
                                instance->prepareToPlay(getSampleRate(), getBlockSize());

                                // instance->processBlock(juce::AudioBuffer<float>(2, getBlockSize()), juce::MidiBuffer());

                                std::cout << "Bus count is " << instance->getBusCount(true) << std::endl;
                                std::cout << "Bus 0 channel count is " << instance->getChannelCountOfBus(true, 0) << std::endl;
                                
                                std::unique_ptr<AudioPlugin> plugin = std::unique_ptr<AudioPlugin>(new AudioPlugin(moduleId, name, std::move(instance)));
                                
                                plugin->createGui();

                                for (int i = 0; i < plugins.size(); i++) {
                                    if (plugins[i]->getModuleId() == moduleId) {
                                        puts("Swapping old plugin");
                                        plugins[i] = std::move(plugin);
                                        return;
                                    }
                                }
                                
                                plugins.push_back(std::move(plugin));
                        });
                    }
                }
            }
        }
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
    std::cout << "prepareToPlay(" << sampleRate << ", " << samplesPerBlock << ")" << std::endl;

    if (ffiHostPrepare != nullptr && core != nullptr) {
        ffiHostPrepare(core, (uint32_t) sampleRate, (uint32_t) samplesPerBlock);
    }
    
    for (auto& plugin : plugins) {
        std::cout << "Preparing plugin " << plugin->getName() << std::endl;
        plugin->prepareToPlay(sampleRate, samplesPerBlock);
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

    if (ffiHostProcess != nullptr && core != nullptr) {
        if (events.size() == 0) {
            ffiHostProcess(core, buffer.getArrayOfWritePointers(), buffer.getNumChannels(), buffer.getNumSamples(), nullptr, 0);
        } else {
            ffiHostProcess(core, buffer.getArrayOfWritePointers(), buffer.getNumChannels(), buffer.getNumSamples(), &*events.begin(), events.size());
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
