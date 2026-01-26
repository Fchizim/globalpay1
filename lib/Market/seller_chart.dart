import 'package:flutter/material.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Map<String, dynamic>> chats = [
    {
      "name": "Alice Johnson",
      "message": "Hey, are you coming today? Let me know what time works for you.",
      "avatar": "assets/images/png/gold.jpg",
      "unread": true,
      "time": "2:30 PM",
    },
    {
      "name": "Bob Smith",
      "message": "Thanks for your help yesterday, really appreciate it!",
      "avatar": "assets/images/png/gold.jpg",
      "unread": false,
      "time": "1:15 PM",
    },
    {
      "name": "Charlie Davis",
      "message": "Let's catch up tomorrow. I have some news to share.",
      "avatar": "assets/images/png/gold.jpg",
      "unread": true,
      "time": "12:05 PM",
    },
    {
      "name": "Diana Prince",
      "message": "See you soon!",
      "avatar": "assets/images/png/gold.jpg",
      "unread": false,
      "time": "Yesterday",
    },
  ];

  void _deleteChat(int index) {
    setState(() {
      chats.removeAt(index);
    });
  }

  void _openChat(Map<String, dynamic> chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationPage(chat: chat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        elevation: 1,
        title: const Text(
          "Messages",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];

          return Dismissible(
            key: UniqueKey(),
            background: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              color: Colors.redAccent,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            secondaryBackground: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerRight,
              color: Colors.blueAccent,
              child: const Icon(Icons.archive, color: Colors.white),
            ),
            onDismissed: (direction) {
              _deleteChat(index);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${chat['name']} chat removed")));
            },
            child: InkWell(
              onTap: () => _openChat(chat),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: AssetImage(chat['avatar']),
                          backgroundColor: Colors.grey.shade300,
                        ),
                        if (chat['unread'])
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chat['message'],
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      chat['time'],
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        isDarkMode ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
class ChatConversationPage extends StatefulWidget {
  final Map<String, dynamic> chat;
  const ChatConversationPage({super.key, required this.chat});

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    messages.add({
      "sender": "other",
      "message": widget.chat['message'],
      "time": widget.chat['time'],
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      messages.add({
        "sender": "me",
        "message": _controller.text.trim(),
        "time": TimeOfDay.now().format(context),
      });
      _controller.clear();
    });

    // Scroll to bottom after a small delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage(widget.chat['avatar']),
            ),
            const SizedBox(width: 10),
            Text(widget.chat['name'],
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['sender'] == "me";
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                            maxWidth:
                            MediaQuery.of(context).size.width * 0.7),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.deepOrange
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['message'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                        child: Text(
                          msg['time'],
                          style: TextStyle(
                              fontSize: 10,
                              color: isDarkMode
                                  ? Colors.white54
                                  : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepOrange),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
