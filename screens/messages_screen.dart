import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_drawer.dart';


// ---------------- MOCK DATA ----------------
const List<String> registeredUsers = [
  "Admin",
  "Security_Office",
  "Student_Affairs",
  "John Doe",
  
];

// mock user info
const String name = "Maeryll Abolencia";
const String role = "Student";

const List<Map<String, String>> notifications = [
  {
    "title": "New Message",
    "message": "You have a new message from Admin.",
    "time": "2 mins ago"
  },
  {
    "title": "System Update",
    "message": "LookFor app has been updated to version 1.2.",
    "time": "1 hour ago"
  },
];

// ---------------- MODEL ----------------
class LookForMessage {
  final String to;
  final String subject;
  final String content;
  final String date;
  final bool isNew;
  final String? imagePath;

  LookForMessage({
    required this.to,
    required this.subject,
    required this.content,
    required this.date,
    this.isNew = true,
    this.imagePath,
  });
}

// ---------------- MAIN SCREEN ----------------
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<LookForMessage> myMessages = [
    LookForMessage(
      to: "Admin",
      subject: "Lost ID Card",
      content: "I lost my ID card and need a replacement. Did someone turn it in?",
      date: "3/20/2026",
    ),
  ];

  late List<LookForMessage> filteredMessages;

  @override
  void initState() {
    super.initState();
    filteredMessages = myMessages;
  }

  void _filterMessages(String query) {
    setState(() {
      filteredMessages = myMessages.where((msg) {
        return msg.to.toLowerCase().contains(query.toLowerCase()) ||
            msg.subject.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // ---------------- MESSAGE CARD ----------------
  Widget _buildMessageCard(LookForMessage message) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatConversationScreen(message: message),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF0066CC).withOpacity(0.12),
              child: const Icon(Icons.person, color: Color(0xFF0066CC)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.to,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.date,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                if (message.isNew)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFCC00),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentPage: "Messages"),
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Look",
                style: GoogleFonts.greatVibes(
                    fontSize: 30,
                    color: Color(0xFF0066CC))),
            Text("For",
                style: GoogleFonts.greatVibes(
                    fontSize: 30,
                    color: Color(0xFFFFCC00))),
          ],
        ),
        actions: [
          _notificationMenu(),
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFDDDDDD),
              child: Icon(Icons.person,
                  color: Color(0xFF003366), size: 20),
            ),
            onPressed: () => _showProfileMenu(context),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMessages,
              decoration: _inputDecoration("Search messages or users...").copyWith(
                prefixIcon: const Icon(
                  Icons.search,
                  color:Color(0xFF0066CC),
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
                    itemBuilder: (_, i) =>
                        _buildMessageCard(filteredMessages[i]),
                  ),
          ),
        ],
      ),

      // ✅ FIXED COMPOSE BUTTON (same design)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFFFFCC00),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () => _showComposeModal(context),
          icon: const Icon(Icons.edit, size: 18, color: Colors.black),
          label: const Text(
            "Compose",
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }

 // ---------------- PROFILE MENU ----------------
  void _showProfileMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(role, style: const TextStyle(color: Colors.green)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Log out"),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );

   },
            ),
          ]),
        ),
      ),
    );
  }

  // ---------------- NOTIFICATION MENU ----------------
  Widget _notificationMenu() {
    return PopupMenuButton<int>(
      offset: const Offset(0, 45),
      icon: Stack(children: [
        const Icon(Icons.notifications_none),
        if (notifications.isNotEmpty)
          Positioned(
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text(
                notifications.length.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ]),

itemBuilder: (_) => notifications
          .map((notif) => PopupMenuItem<int>(
                enabled: false,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(notif["title"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(notif["message"]!, style: const TextStyle(fontSize: 12)),
                  Text(notif["time"]!, style: const TextStyle(fontSize: 10)),
                ]),
              ))
          .toList(),
    );
  }

  // ---------------- COMPOSE MODAL ----------------
  void _showComposeModal(BuildContext context) {
    final toController = TextEditingController();
    final messageController = TextEditingController();
    bool hasImage = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Compose Message",
            style: TextStyle(color: Color(0xFF0066CC)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label("To *"),
                Autocomplete<String>(
                  optionsBuilder: (value) => registeredUsers.where(
                    (s) =>
                        s.toLowerCase().contains(value.text.toLowerCase()),
                  ),
                  onSelected: (s) => toController.text = s,
                  fieldViewBuilder: (_, ctrl, node, __) => TextField(
                    controller: ctrl,
                    focusNode: node,
                    decoration: _inputDecoration("Recipient"),
                  ),
                ),
                const SizedBox(height: 14),
                _label("Message *"),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: _inputDecoration("Type here..."),
                ),
                const SizedBox(height: 14),
                _label("Attachment"),
                GestureDetector(
                  onTap: () => setModalState(() => hasImage = true),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hasImage
                          ? Colors.green.withOpacity(0.08)
                          : const Color(0xFFF2F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasImage
                            ? Colors.green
                            : Colors.blue.shade100,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasImage
                              ? Icons.check_circle
                              : Icons.upload_file,
                          color: hasImage
                              ? Colors.green
                              : const Color(0xFF0066CC),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasImage ? "Image Attached" : "Upload Image",
                          style: TextStyle(
                            fontSize: 13,
                            color: hasImage
                                ? Colors.green
                                : Colors.grey.shade600,
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
                      imagePath: hasImage ? "image.png" : null,
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text(
                "Send",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );

  InputDecoration _inputDecoration(String hint) {
    const blueBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(
        color: Color(0xFF0066CC),
        width: 1,
      ),
    );

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF2F5F9),
      enabledBorder: blueBorder,
      focusedBorder: blueBorder.copyWith(
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      border: blueBorder,
    );
  }
}

// ---------------- CHAT SCREEN ----------------
class ChatConversationScreen extends StatefulWidget {
  final LookForMessage message;
  const ChatConversationScreen({super.key, required this.message});

  @override
  State<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, dynamic>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _chatHistory.add({
      "text": widget.message.content,
      "isMe": true,
      "image": widget.message.imagePath,
    });
  }

  void _sendMessage({String? image}) {
    if (_chatController.text.isEmpty && image == null) return;
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
      appBar: AppBar(title: Text(widget.message.to)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length,
              itemBuilder: (_, i) {
                final chat = _chatHistory[i];
                return Align(
                  alignment: chat["isMe"]
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: chat["isMe"]
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (chat["image"] != null)
                        Container(
                          height: 140,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.image, size: 50),
                        ),
                      _bubble(chat["text"], chat["isMe"]),
                    ],
                  ),
                );
              },
            ),
          ),
          _inputArea(),
        ],
      ),
    );
  }

  Widget _bubble(String text, bool isMe) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFFCC00) : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Text(text),
      );

  Widget _inputArea() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image, color: Color(0xFF0066CC)),
              onPressed: () => _sendMessage(image: "img.png"),
            ),
            Expanded(
              child: TextField(
                controller: _chatController,
                decoration: const InputDecoration(
                  hintText: "Message...",
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF0066CC)),
              onPressed: _sendMessage,
            ),
          ],
        ),
      );


}

// ---------------- LOGIN PLACEHOLDER ----------------
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Login Screen")),
    );
  }
}
