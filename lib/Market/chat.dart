import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  void sendMessage({String? text, File? imageFile}) {
    if ((text == null || text.trim().isEmpty) && imageFile == null) return;
    setState(() {
      messages.add({
        "text": text,
        "image": imageFile,
        "isMe": true,
        "time": TimeOfDay.now().format(context),
      });
    });
    _controller.clear();
  }

  Future<void> pickImage(bool fromCamera) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1024,
      );

      if (pickedFile != null) {
        sendMessage(imageFile: File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  void showAttachmentMenu(BuildContext context) {
    showMenu(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.white,
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width * 0.05,
        MediaQuery.of(context).size.height - 150,
        MediaQuery.of(context).size.width * 0.05,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      items: [
        PopupMenuItem(
          value: 'gallery',
          child: Row(
            children: [
              Icon(Icons.photo, color: Colors.blue),
              const SizedBox(width: 10),
              const Text("Upload from Gallery"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'camera',
          child: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.green),
              const SizedBox(width: 10),
              const Text("Take a Picture"),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'gallery') pickImage(false);
      if (value == 'camera') pickImage(true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final sentBubbleColor = isDarkMode ? Colors.blue.shade700 : Colors.blue;
    final receivedBubbleColor = isDarkMode ? Colors.grey.shade700 : Colors.grey[300];

    double maxBubbleWidth = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 1,
        title: Text(
          "Message",
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              reverse: false,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                bool isMe = message["isMe"];
                String? text = message["text"];
                File? imageFile = message["image"];
                String time = message["time"];

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? sentBubbleColor : receivedBubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: Radius.circular(isMe ? 15 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: const Offset(1, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageFile != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              imageFile,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (text != null && text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Text(
                              text,
                              style: TextStyle(
                                color: isMe ? Colors.white : isDarkMode ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: isMe
                                  ? Colors.white70
                                  : isDarkMode
                                  ? Colors.white60
                                  : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.blue, size: 28),
                    onPressed: () => showAttachmentMenu(context),
                  ),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: null,
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: "Send a message",
                          hintStyle: TextStyle(color: isDarkMode ? Colors.white60 : Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: isDarkMode ? Colors.white38 : Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: isDarkMode ? Colors.white38 : Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.blue, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => sendMessage(text: _controller.text.trim()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
