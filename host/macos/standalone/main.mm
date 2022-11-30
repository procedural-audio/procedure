// #include "MainComponent.h"
// #include "PluginEditor.h"

// #import "FlutterViewController.h"
// #import "FlutterChannels.h"
#include "NodusProcessor.h"
#include "NodusEditor.h"
#include "JuceHeader.h"

//==============================================================================
class GuiAppApplication  : public juce::JUCEApplication
{
public:
    //==============================================================================
    GuiAppApplication() {}

    const juce::String getApplicationName() override       { return "Application Name"; }
    const juce::String getApplicationVersion() override    { return "Version String Here"; }
    bool moreThanOneInstanceAllowed() override             { return true; }

    //==============================================================================
    void initialise (const juce::String& commandLine) override
    {
        juce::ignoreUnused (commandLine);
        mainWindow.reset (new MainWindow (getApplicationName()));
    }

    void shutdown() override
    {
        mainWindow = nullptr;
    }

    //==============================================================================
    void systemRequestedQuit() override
    {
        quit();
    }

    void anotherInstanceStarted (const juce::String& commandLine) override
    {
        juce::ignoreUnused (commandLine);
    }

    //==============================================================================

    class MainWindow    : public juce::DocumentWindow
    {
    public:
        explicit MainWindow (juce::String name)
            : DocumentWindow (name,
                              juce::Desktop::getInstance().getDefaultLookAndFeel()
                                                          .findColour (ResizableWindow::backgroundColourId),
                              DocumentWindow::allButtons)
        {
            setUsingNativeTitleBar (true);
            // setContentOwned (new Flutter_juceAudioProcessorEditor(), true);
            setContentOwned(new NodusEditor(processor), true);

           #if JUCE_IOS || JUCE_ANDROID
            setFullScreen (true);
           #else
            setResizable (true, true);
            // centreWithSize (getWidth(), getHeight());
            centreWithSize(1200, 900);
           #endif

            setVisible (true);
        }

        void closeButtonPressed() override
        {
            // This is called when the user tries to close this window. Here, we'll just
            // ask the app to quit when this happens, but you can change this to do
            // whatever you need.
            JUCEApplication::getInstance()->systemRequestedQuit();
        }

    private:
        NodusProcessor processor;
        JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (MainWindow)
    };

private:
    std::unique_ptr<MainWindow> mainWindow;
};

//==============================================================================
// This macro generates the main() routine that launches the app.
START_JUCE_APPLICATION (GuiAppApplication)