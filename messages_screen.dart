import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. Mock Data for Autocomplete
const List<String> registeredUsers = [
  "Admin",
  "Security_Office",
  "Student_Affairs",
  "John Doe",
];

class LookForMessage {
  final String to;
  final String subject;
  final String content;
  final String date;
  final bool isNew;
  final String? imagePath; // Added to support images

  LookForMessage({
    required this.to,
    required this.subject,
    required this.content,
    required this.date,
    this.isNew = true,
    this.imagePath,
  });
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<LookForMessage> myMessages = [
    LookForMessage(
      to: "Admin",
      subject: "Welcome to LookFor",
      content: "Thank you for joining!",
      date: "3/20/2026",
    ),
  ];
  List<LookForMessage> filteredMessages = [];

  @override
  void initState() {
    super.initState();
    filteredMessages = myMessages;
  }

  void _filterMessages(String query) {
    setState(() {
      filteredMessages = myMessages
          .where(
            (msg) =>
                msg.to.toLowerCase().contains(query.toLowerCase()) ||
                msg.subject.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  // --- BUILDER FOR MESSAGE CARDS ---
  Widget _buildMessageCard(BuildContext context, LookForMessage message) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatConversationScreen(message: message),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0066CC).withOpacity(0.1),
          child: const Icon(Icons.person, color: Color(0xFF0066CC)),
        ),
        title: Text(
          message.to,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          message.subject,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message.date,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            if (message.isNew)
              Container(
                margin: EdgeInsets.only(top: 5),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCC00),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(
            color: Color(0xFF0066CC),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
              ),
              onPressed: () => _showComposeModal(context),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                "Compose",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMessages,
              decoration: _inputDecoration("Search messages or users...")
                  .copyWith(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF0066CC),
                    ),
                  ),
            ),
          ),
          Expanded(
            child: filteredMessages.isEmpty
                ? const Center(child: Text("No messages found."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredMessages.length,
                    itemBuilder: (context, index) =>
                        _buildMessageCard(context, filteredMessages[index]),
                  ),
          ),
        ],
      ),
    );
  }

  // --- COMPOSE MODAL WITH IMAGE STATE ---
  void _showComposeModal(BuildContext context) {
    final toController = TextEditingController();
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    bool hasImage = false; // Local state for the modal

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Use StatefulBuilder to update "Upload" UI
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Compose",
            style: TextStyle(color: Color(0xFF0066CC)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label("To *"),
                Autocomplete<String>(
                  optionsBuilder: (val) => registeredUsers.where(
                    (s) => s.toLowerCase().contains(val.text.toLowerCase()),
                  ),
                  onSelected: (s) => toController.text = s,
                  fieldViewBuilder: (ctx, ctrl, node, submit) => TextField(
                    controller: ctrl,
                    focusNode: node,
                    decoration: _inputDecoration("Receiver name"),
                  ),
                ),
                const SizedBox(height: 15),
                _label("Message *"),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: _inputDecoration("Type message..."),
                ),
                const SizedBox(height: 15),
                _label("Attachments"),
                InkWell(
                  onTap: () {
                    setModalState(
                      () => hasImage = true,
                    ); // Simulate picking an image
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Image selected!")),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: hasImage
                          ? Colors.green.shade50
                          : const Color(0xFFF2F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasImage ? Colors.green : Colors.blue.shade100,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          hasImage
                              ? Icons.check_circle
                              : Icons.cloud_upload_outlined,
                          color: hasImage
                              ? Colors.green
                              : const Color(0xFF0066CC),
                        ),
                        Text(
                          hasImage ? "Image Attached" : "Upload Image",
                          style: TextStyle(
                            color: hasImage ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCC00),
              ),
              onPressed: () {
                setState(() {
                  myMessages.insert(
                    0,
                    LookForMessage(
                      to: toController.text,
                      subject: "New Message",
                      content: messageController.text,
                      date: "Today",
                      imagePath: hasImage ? "attached_image.png" : null,
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text("Send", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF2F5F9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
  );
}

// --- UPDATED CONVERSATION SCREEN ---
class ChatConversationScreen extends StatefulWidget {
  final LookForMessage message;
  const ChatConversationScreen({super.key, required this.message});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, dynamic>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    // Add original content
    _chatHistory.add({
      "text": widget.message.content,
      "isMe": true,
      "image": widget.message.imagePath,
    });
  }

  void _sendMessage({String? image}) {
    setState(() {
      _chatHistory.add({
        "text": _chatController.text,
        "isMe": true,
        "image": image,
      });
      _chatController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat with ${widget.message.to}")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final chat = _chatHistory[index];
                return Column(
                  crossAxisAlignment: chat["isMe"]
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (chat["image"] != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        height: 150,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.image,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    _bubble(chat["text"], chat["isMe"]),
                  ],
                );
              },
            ),
          ),
          _inputArea(),
        ],
      ),
    );
  }

  Widget _bubble(String text, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFFCC00) : Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(text),
    );
  }

  Widget _inputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Color(0xFF0066CC)),
            onPressed: () => _sendMessage(image: "new_upload.png"),
          ),
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: const InputDecoration(hintText: "Message..."),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(),
          ),
        ],
      ),
    );
  }
}
