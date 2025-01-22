import 'dart:io';

import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:metasampler/bindings/api/graph.dart';
import 'package:metasampler/plugins.dart';
import 'package:metasampler/settings.dart';
import 'package:metasampler/views/presets.dart';

import 'package:metasampler/bindings/frb_generated.dart';
import 'package:metasampler/bindings/api.dart';

String openAiKey =
    "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";

const String systemTemplate = """
You are a helpful AI assistant embedded inside a music production tool
called the Procedural Audio Workstation, a modular synthesizer that
enables users to create generative music by connecting modules or nodes backed
by the cmajor language for DSP signal processing code. You can help users
by providing information and answering questions, but your primary job is
to assist users in generating cmajor code that functions as a node in the
modular environment.
""";

// Types of messages supported by the chat
enum MessageType { user, ai, system }

// Chat message
class Message {
  Message(this.text, this.type);

  MessageType type;
  String text;

  bool get isUser => type == MessageType.user;
  bool get isAi => type == MessageType.ai;

  static Message user(String text) => Message(text, MessageType.user);
  static Message ai(String text) => Message(text, MessageType.ai);
  static Message system(String text) => Message(text, MessageType.system);

  ChatMessage toChatMessage() {
    switch (type) {
      case MessageType.user:
        return ChatMessage.humanText(text);
      case MessageType.ai:
        return ChatMessage.ai(text);
      case MessageType.system:
        return ChatMessage.system(text);
    }
  }
}

// Chat window
class ChatWindow extends StatefulWidget {
  const ChatWindow({Key? key}) : super(key: key);

  @override
  State<ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<ChatWindow> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [Message.system(systemTemplate)];
  final ChatOpenAI _llm = ChatOpenAI(apiKey: openAiKey);
  bool _isLoading = false;

  String humanTemplate = "{text}";

  void sendMessage() async {
    if (_controller.text.isEmpty) return;

    // Construct a message
    _messages.add(Message.user(_controller.text));
    _controller.clear();
    setState(() => _isLoading = true);

    // Send the prompt
    var messages = _messages.map((e) => e.toChatMessage()).toList();
    var prompt = PromptValue.chat(messages);
    var response = await _llm.invoke(prompt);

    if (response.finishReason == FinishReason.stop) {
      _messages.add(Message.ai(response.outputAsString));
    } else {
      print("Error in response: ${response.metadata}");
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length - 1,
            itemBuilder: (context, index) {
              final message = _messages[index + 1];
              return ListTile(
                title: Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                      borderRadius: message.isUser
                          ? BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            )
                          : BorderRadius.only(
                              topRight: Radius.circular(20),
                              topLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                    ),
                    child: Text(
                      message.text,
                      style: message.isUser
                          ? Theme.of(context).textTheme.bodyMedium
                          : Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // user input
        Padding(
          padding: const EdgeInsets.only(
            bottom: 32,
            top: 16.0,
            left: 16.0,
            right: 16,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: Theme.of(context).textTheme.titleSmall,
                    decoration: InputDecoration(
                      hintText: 'Write your message',
                      hintStyle: Theme.of(context)
                          .textTheme
                          .titleSmall!
                          .copyWith(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
                _isLoading
                    ? Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: IconButton(
                          icon: Icon(Icons.send),
                          onPressed: sendMessage,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
