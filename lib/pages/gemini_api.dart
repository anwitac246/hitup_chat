import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat with Gemini API',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const GeminiApiChat(),
    );
  }
}

class GeminiApiChat extends StatefulWidget {
  const GeminiApiChat({Key? key}) : super(key: key);

  @override
  State<GeminiApiChat> createState() => _GeminiApiChatState();
}

class _GeminiApiChatState extends State<GeminiApiChat> {
  late GenerativeModel geminiModel;
  late ChatSession chatSession;
  final FocusNode _textFieldFocus = FocusNode();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> chatMessages = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not found in .env file.');
      }

      geminiModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.4,
          topK: 32,
          topP: 1,
          maxOutputTokens: 4096,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
        ],
      );

      chatSession = await geminiModel.startChat();

      setState(() {
        _isInitialized = true;
      });

      print("Chat session initialized successfully.");
    } catch (e) {
      setState(() {
        _isInitialized = false;
      });
      print("Error initializing chat session: ${e.toString()}");
      _showError('Initialization Error: ${e.toString()}');
    }
  }

  Future<void> _sendChatMessage(String message) async {
    if (!_isInitialized) {
      print("Chat session is not initialized yet.");
      return;
    }

    if (message.isEmpty) {
      print("Message is empty");
      return;
    }

    setState(() {
      chatMessages.add({"text": message, "isFromUser": true});
    });

    try {
      print("Sending message: $message");

      final response = await chatSession.sendMessage(Content.text(message));

      if (response.text != null) {
        setState(() {
          chatMessages.add({"text": response.text, "isFromUser": false});
        });
        _scrollDown();
      } else {
        _showError('No response from Gemini API');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
      print("Error occurred while sending message: ${e.toString()}");
    } finally {
      _textController.clear();
      _textFieldFocus.requestFocus();
    }
  }

  Future<void> _showError(String message) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: SingleChildScrollView(child: SelectableText(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _scrollDown() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Gemini Chat', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.pink,
      ),
      body: Column(
        children: [
          if (!_isInitialized)
            const Center(child: CircularProgressIndicator()),
          if (_isInitialized)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: chatMessages.length,
                itemBuilder: (context, index) {
                  final message = chatMessages[index];
                  return MessageWidget(
                    text: message["text"],
                    isFromUser: message["isFromUser"],
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _textFieldFocus,
                    onSubmitted: (value) => _sendChatMessage(value),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(15),
                      hintText: 'Enter a prompt...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                    
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.pink),
                  onPressed: () => _sendChatMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageWidget extends StatelessWidget {
  final String text;
  final bool isFromUser;

  const MessageWidget({
    Key? key,
    required this.text,
    required this.isFromUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isFromUser ? Colors.pink : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isFromUser ? 12 : 0),
            bottomRight: Radius.circular(isFromUser ? 0 : 12),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isFromUser ? Colors.black : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
