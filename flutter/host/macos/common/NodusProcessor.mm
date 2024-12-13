#include "NodusProcessor.h"
#include "NodusEditor.h"

#import "FlutterViewController.h"
#import "FlutterChannels.h"

#include <dlfcn.h>

NodusProcessor::NodusProcessor()
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
    puts("Created processor");

    auto libPath = "/Users/chasekanipe/Github/nodus/build/out/core/release/libtonevision_core.dylib";
    handle = dlopen(libPath, RTLD_LAZY);

    /*#ifdef __MINGW32__
        EDITTHIS();
    #endif

    #ifdef __linux__
        auto libPath = "./lib/libtonevision_core.so";
        handle = dlopen(libPath, RTLD_LAZY | RTLD_DEEPBIND);
    #endif*/

    if (handle) {
        ffiCreateHost = (FFIHost* (*)()) dlsym(handle, "ffi_create_host");
        ffiDestroyHost = (void (*)(FFIHost*)) dlsym(handle, "ffi_destroy_host");
        ffiHostPrepare = (void (*)(FFIHost*, uint32_t, uint32_t)) dlsym(handle, "ffi_host_prepare");
        ffiHostProcess = (void (*)(FFIHost*, float**, uint32_t, uint32_t, NoteMessage*, uint32_t)) dlsym(handle, "ffi_host_process");

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
    
    std::cout << "About to processor stuff" << std::endl;
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

    puts("Done creating processor");
}

NodusProcessor::~NodusProcessor()
{
    [flutterViewController release];
    // ffiDestroyHost(host);
    // dlclose(handle);
}

void NodusProcessor::pluginsMessage(juce::String message) {
    /*auto json = juce::JSON::parse(message);
    
    if (json["message"] == "create") {
        juce::String name = json["name"];
        int moduleId = json["module_id"];
        
        for (auto& plugin : plugins) {
            if (plugin->getName() == name && plugin->getModuleId() == moduleId) {
                puts("Plugin already loaded");
                return;
            }
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
    } else if (json["message"] == "get process") {
        std::string s1 = "process addr ";
        std::string s2 = s1.append(std::to_string((long) &plugin_process_block));
        NSString *s3 = [NSString stringWithCString:s2.c_str() encoding:[NSString defaultCStringEncoding]];
        [audioPluginsChannel sendMessage:s3];
    } else {
        std::cout << "Recieved message: " << message << std::endl;
    }*/
}

/*void NodusProcessor::addAudioPlugin(int moduleId, juce::String name) {
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
}*/

const juce::String NodusProcessor::getName() const
{
    return "Nodus";
}

bool NodusProcessor::acceptsMidi() const
{
   #if JucePlugin_WantsMidiInput
    return true;
   #else
    return false;
   #endif
}

bool NodusProcessor::producesMidi() const
{
   #if JucePlugin_ProducesMidiOutput
    return true;
   #else
    return false;
   #endif
}

bool NodusProcessor::isMidiEffect() const
{
   #if JucePlugin_IsMidiEffect
    return true;
   #else
    return false;
   #endif
}

double NodusProcessor::getTailLengthSeconds() const
{
    return 0.0;
}

int NodusProcessor::getNumPrograms()
{
    return 1;   // NB: some hosts don't cope very well if you tell them there are 0 programs,
                // so this should be at least 1, even if you're not really implementing programs.
}

int NodusProcessor::getCurrentProgram()
{
    return 0;
}

void NodusProcessor::setCurrentProgram (int index)
{
}

const juce::String NodusProcessor::getProgramName (int index)
{
    return {};
}

void NodusProcessor::changeProgramName (int index, const juce::String& newName)
{
}

//==============================================================================
void NodusProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    std::cout << "prepareToPlay(" << sampleRate << ", " << samplesPerBlock << ")" << std::endl;

    if (ffiHostPrepare != nullptr && core != nullptr) {
        ffiHostPrepare(core, (uint32_t) sampleRate, (uint32_t) samplesPerBlock);
    }
    
    /*for (auto& plugin : plugins) {
        std::cout << "Preparing plugin " << plugin->getName() << std::endl;
        plugin->prepareToPlay(sampleRate, samplesPerBlock);
    }*/
}

void NodusProcessor::releaseResources()
{
}

#ifndef JucePlugin_PreferredChannelConfigurations
bool NodusProcessor::isBusesLayoutSupported (const BusesLayout& layouts) const
{
  #if JucePlugin_IsMidiEffect
    juce::ignoreUnused (layouts);
    return true;
  #else
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

void NodusProcessor::processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;
    auto totalNumInputChannels  = getTotalNumInputChannels();
    auto totalNumOutputChannels = getTotalNumOutputChannels();

    for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
        buffer.clear (i, 0, buffer.getNumSamples());

    for (int channel = 0; channel < totalNumInputChannels; ++channel)
    {
        auto* channelData = buffer.getWritePointer (channel);
        juce::ignoreUnused (channelData);
    }

    events.clear();

    for (auto data : midiMessages) {
        auto message = data.getMessage();

        if (message.isNoteOn()) {
            // std::cout << message.getDescription() << std::endl;

            NoteMessage event;
            event.id = (unsigned short) message.getNoteNumber();
            event.offset =  (size_t) data.samplePosition;
            event.tag = NoteTag::NoteOn;

            NoteValue value;
            value.noteOn = NoteOn {
                pitch: (float) juce::MidiMessage::getMidiNoteInHertz(message.getNoteNumber()),
                pressure: ((float) message.getVelocity()) / 127,
            };

            event.value = value;

            events.push_back(event);
        } else if (message.isNoteOff()) {
            // std::cout << message.getDescription() << std::endl;

            auto event = NoteMessage {
                id: (unsigned short) message.getNoteNumber(),
                offset: (size_t) data.samplePosition,
                tag: NoteTag::NoteOff,
            };

            event.value.noteOff = NoteOff {};
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

bool NodusProcessor::hasEditor() const
{
    return true;
}

juce::AudioProcessorEditor* NodusProcessor::createEditor()
{
    return new NodusEditor (*this);
}

void NodusProcessor::getStateInformation (juce::MemoryBlock& destData)
{
}

void NodusProcessor::setStateInformation (const void* data, int sizeInBytes)
{
}

juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new NodusProcessor();
}
