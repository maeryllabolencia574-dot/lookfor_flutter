import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutterlookfor/services/api_service.dart';
import '../services/api_client.dart';
import '../widgets/app_drawer.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/notification_bell_button.dart';

class LookForUser {
  final int id;
  final String email;
  final String fullName;
  final String roleLabel;
  final String? studentNo;

  const LookForUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roleLabel,
    this.studentNo,
  });

  factory LookForUser.fromJson(Map<String, dynamic> json) {
    return LookForUser(
      id: _readInt(json['id']),
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString().trim() ?? '',
      roleLabel: json['role_label']?.toString() ?? 'User',
      studentNo: json['student_no']?.toString(),
    );
  }

  static int _readInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  String get displayName => fullName.isNotEmpty ? fullName : email;
}

class ChatMessage {
  final int id;
  final int senderId;
  final int recipientId;
  final String content;
  final DateTime? createdAt;
  final String status;
  final String? imagePath;
  final File? localImage;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    this.createdAt,
    required this.status,
    this.imagePath,
    this.localImage,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _readInt(json['id']),
      senderId: _readInt(json['sender_id']),
      recipientId: _readInt(json['recipient_id']),
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      status: json['status']?.toString() ?? '',
      imagePath: _readImagePath(json),
    );
  }

  static int _readInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  static String? _readImagePath(Map<String, dynamic> json) {
    final value =
        json['image_path'] ??
        json['image_url'] ??
        json['attachment_path'] ??
        json['attachment_url'] ??
        json['photo_path'] ??
        json['photo_url'];
    final path = value?.toString().trim();
    return path == null || path.isEmpty ? null : path;
  }

  bool get hasImage => imagePath != null || localImage != null;
  String get previewText {
    final text = content.trim();
    if (text.isNotEmpty) return text;
    return hasImage ? '[Photo]' : 'No message';
  }
}

class ConversationPreview {
  final LookForUser user;
  final ChatMessage lastMessage;

  const ConversationPreview({required this.user, required this.lastMessage});
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  String _currentUserName = 'Current User';
  String _currentUserRole = 'Student';
  int? _currentUserId;

  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;
  String? _searchMessage;
  List<ConversationPreview> _conversationPreviews = [];
  List<LookForUser> _userResults = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  int _readInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = await apiClient.getCurrentUser();
      if (!mounted) return;

      final fullName = userData['full_name']?.toString().trim() ?? '';
      setState(() {
        _currentUserId = _readInt(userData['id']);
        _currentUserName = fullName.isNotEmpty
            ? fullName
            : userData['email']?.toString() ?? 'Current User';
        _currentUserRole = userData['role_label']?.toString() ?? 'Student';
        _isLoading = false;
      });

      await _loadExistingConversations();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load messages.';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () {
        final trimmed = query.trim();
        if (trimmed.length < 2) {
          _loadExistingConversations();
        } else {
          _searchUsersAndConversations(trimmed);
        }
      },
    );
  }

  Future<void> _loadExistingConversations() async {
    final currentId = _currentUserId;
    if (currentId == null) return;

    setState(() {
      _isSearching = true;
      _searchMessage = null;
    });

    try {
      final results = await apiClient.searchUsers('');
      final users = results
          .whereType<Map<String, dynamic>>()
          .map(LookForUser.fromJson)
          .where((user) => user.id != 0 && user.id != currentId)
          .toList();

      final previews = <ConversationPreview>[];
      for (final user in users) {
        try {
          final history = await apiClient.getChatHistory(user.id);
          final messages = history
              .whereType<Map<String, dynamic>>()
              .map(ChatMessage.fromJson)
              .where(
                (message) =>
                    message.content.trim().isNotEmpty || message.hasImage,
              )
              .toList();

          if (messages.isNotEmpty) {
            previews.add(
              ConversationPreview(user: user, lastMessage: messages.last),
            );
          }
        } on ApiException {
          // Keep the conversation list usable even if one preview fails.
        }
      }

      previews.sort((a, b) {
        final left = a.lastMessage.createdAt;
        final right = b.lastMessage.createdAt;
        if (left == null && right == null) return 0;
        if (left == null) return 1;
        if (right == null) return -1;
        return right.compareTo(left);
      });

      if (!mounted) return;
      setState(() {
        _conversationPreviews = previews;
        _userResults = [];
        _searchMessage = previews.isEmpty
            ? 'No conversations yet. Search a student, office, or admin to start chatting.'
            : null;
        _isSearching = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _conversationPreviews = [];
        _userResults = [];
        _searchMessage = e.message;
        _isSearching = false;
      });
    }
  }

  Future<void> _searchUsersAndConversations(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _conversationPreviews = [];
        _userResults = [];
        _searchMessage = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchMessage = null;
    });

    try {
      final results = await apiClient.searchUsers(trimmed);
      final currentId = _currentUserId;
      final users = results
          .whereType<Map<String, dynamic>>()
          .map(LookForUser.fromJson)
          .where((user) => user.id != 0 && user.id != currentId)
          .toList();

      final previews = <ConversationPreview>[];
      for (final user in users.take(12)) {
        try {
          final history = await apiClient.getChatHistory(user.id);
          final messages = history
              .whereType<Map<String, dynamic>>()
              .map(ChatMessage.fromJson)
              .where(
                (message) =>
                    message.content.trim().isNotEmpty || message.hasImage,
              )
              .toList();
          if (messages.isNotEmpty) {
            previews.add(
              ConversationPreview(user: user, lastMessage: messages.last),
            );
          }
        } on ApiException {
          // Keep search usable even if one preview fails to load.
        }
      }

      final previewUserIds = previews.map((preview) => preview.user.id).toSet();
      final people = users
          .where((user) => !previewUserIds.contains(user.id))
          .toList(growable: false);

      previews.sort((a, b) {
        final left = a.lastMessage.createdAt;
        final right = b.lastMessage.createdAt;
        if (left == null && right == null) return 0;
        if (left == null) return 1;
        if (right == null) return -1;
        return right.compareTo(left);
      });

      if (!mounted) return;
      setState(() {
        _conversationPreviews = previews;
        _userResults = people;
        _searchMessage = users.isEmpty ? 'No users found.' : null;
        _isSearching = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _conversationPreviews = [];
        _userResults = [];
        _searchMessage = e.message;
        _isSearching = false;
      });
    }
  }

  Future<void> _openChat(LookForUser user) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatConversationScreen(user: user, currentUserId: currentUserId),
      ),
    );

    if (!mounted) return;
    final query = _searchController.text.trim();
    if (query.length >= 2) {
      _searchUsersAndConversations(query);
    }
  }

  Future<void> _showComposeSheet() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    final sentTo = await showModalBottomSheet<LookForUser>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ComposeMessageSheet(currentUserId: currentUserId),
    );

    if (!mounted || sentTo == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message sent to ${sentTo.displayName}.')),
    );
    _openChat(sentTo);
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF0066CC),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationCard(ConversationPreview preview) {
    final lastMessage = preview.lastMessage;
    final isMe = lastMessage.senderId == _currentUserId;
    final timestamp = _formatPreviewTime(lastMessage.createdAt);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openChat(preview.user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0x220066CC),
              child: Icon(Icons.person, color: Color(0xFF0066CC)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview.user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (timestamp.isNotEmpty)
                        Text(
                          timestamp,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${isMe ? 'You: ' : ''}${lastMessage.previewText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(LookForUser user) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openChat(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0x220066CC),
              child: Icon(Icons.person, color: Color(0xFF0066CC)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.studentNo?.isNotEmpty == true
                        ? '${user.roleLabel} - ${user.studentNo}'
                        : user.roleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF0066CC)),
          ],
        ),
      ),
    );
  }

  String _formatPreviewTime(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final now = DateTime.now();
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return DateFormat(sameDay ? 'h:mm a' : 'MMM d').format(local);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      drawer: AppDrawer(
        currentPage: 'Messages',
        userName: _currentUserName,
        userRole: _currentUserRole,
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Look',
              style: GoogleFonts.greatVibes(
                fontSize: 30,
                color: const Color(0xFF0066CC),
              ),
            ),
            Text(
              'For',
              style: GoogleFonts.greatVibes(
                fontSize: 30,
                color: const Color(0xFFFFCC00),
              ),
            ),
          ],
        ),
        actions: [
          const NotificationBellButton(),
          IconButton(
            icon: const CircleAvatar(child: Icon(Icons.person)),
            onPressed: () => showLogoutDialog(context, {
              'name': _currentUserName,
              'role': _currentUserRole,
            }),
          ),
        ],
      ),
      body: _errorMessage != null
          ? _ErrorState(message: _errorMessage!, onRetry: _loadCurrentUser)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: _inputDecoration('Search users or admins...')
                        .copyWith(
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                  ),
                ),
                Expanded(
                  child: _conversationPreviews.isEmpty && _userResults.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Text(
                              _searchMessage ??
                                  'Search for a student, office, or admin to preview conversations.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 90),
                          children: [
                            if (_conversationPreviews.isNotEmpty)
                              _sectionLabel('Conversations'),
                            for (final preview in _conversationPreviews)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: _buildConversationCard(preview),
                              ),
                            if (_userResults.isNotEmpty)
                              _sectionLabel('People'),
                            for (final user in _userResults)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: _buildUserCard(user),
                              ),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showComposeSheet,
        icon: const Icon(Icons.edit),
        label: const Text('Compose'),
        backgroundColor: const Color(0xFFFFCC00),
        foregroundColor: Colors.black,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: const Color(0xFFF2F5F9),
  );
}

class _ComposeMessageSheet extends StatefulWidget {
  final int currentUserId;

  const _ComposeMessageSheet({required this.currentUserId});

  @override
  State<_ComposeMessageSheet> createState() => _ComposeMessageSheetState();
}

class _ComposeMessageSheetState extends State<_ComposeMessageSheet> {
  final TextEditingController _recipientSearch = TextEditingController();
  final TextEditingController _message = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Timer? _recipientDebounce;

  LookForUser? _selectedUser;
  List<LookForUser> _results = [];
  File? _image;
  bool _isSearching = false;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _recipientDebounce?.cancel();
    _recipientSearch.dispose();
    _message.dispose();
    super.dispose();
  }

  void _searchRecipients(String query) {
    _recipientDebounce?.cancel();
    _recipientDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _loadRecipients(query),
    );
  }

  Future<void> _loadRecipients(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _results = [];
        _errorMessage = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _selectedUser = null;
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await apiClient.searchUsers(trimmed);
      if (!mounted) return;
      setState(() {
        _results = results
            .whereType<Map<String, dynamic>>()
            .map(LookForUser.fromJson)
            .where((user) => user.id != 0 && user.id != widget.currentUserId)
            .toList();
        _isSearching = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _errorMessage = e.message;
        _isSearching = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _image = File(picked.path));
  }

  Future<void> _send() async {
    final user = _selectedUser;
    final content = _message.text.trim();
    final image = _image;

    if (user == null) {
      setState(() => _errorMessage = 'Choose a recipient first.');
      return;
    }
    if (content.isEmpty && image == null) {
      setState(() => _errorMessage = 'Type a message or attach a photo.');
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await apiClient.sendMessage(
        user.id,
        content.isEmpty ? '[Photo]' : content,
        //images: images != null ? [image] : null,
      );
      if (!mounted) return;
      Navigator.pop(context, user);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Compose Message',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _recipientSearch,
              onChanged: _searchRecipients,
              decoration: InputDecoration(
                hintText: 'Search recipient or admin',
                prefixIcon: const Icon(Icons.person_search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF2F5F9),
              ),
            ),
            if (_selectedUser != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Chip(
                  avatar: const Icon(Icons.person, size: 18),
                  label: Text(_selectedUser!.displayName),
                  onDeleted: () => setState(() => _selectedUser = null),
                ),
              ),
            if (_results.isNotEmpty && _selectedUser == null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (_, index) {
                    final user = _results[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user.displayName),
                      subtitle: Text(user.roleLabel),
                      onTap: () {
                        setState(() {
                          _selectedUser = user;
                          _recipientSearch.text = user.displayName;
                          _results = [];
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Type your message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFFF2F5F9),
              ),
            ),
            const SizedBox(height: 12),
            if (_image != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _image!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton.filled(
                      tooltip: 'Remove photo',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _image = null),
                    ),
                  ),
                ],
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isSending ? null : _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Photo'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isSending ? null : _send,
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatConversationScreen extends StatefulWidget {
  final LookForUser user;
  final int currentUserId;

  const ChatConversationScreen({
    super.key,
    required this.user,
    required this.currentUserId,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _chat = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final List<ChatMessage> _history = [];

  File? _draftImage;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _chat.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await apiClient.getChatHistory(widget.user.id);
      unawaited(_markChatRead());
      if (!mounted) return;

      setState(() {
        _history
          ..clear()
          ..addAll(
            results
                .whereType<Map<String, dynamic>>()
                .map(ChatMessage.fromJson)
                .where(
                  (message) =>
                      message.content.trim().isNotEmpty || message.hasImage,
                ),
          );
        _isLoading = false;
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _markChatRead() async {
    try {
      await apiClient.markChatAsRead(widget.user.id);
    } on ApiException {
      // Message history should remain readable even if read receipts fail.
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _draftImage = File(picked.path));
  }

  Future<void> _send() async {
    final content = _chat.text.trim();
    final image = _draftImage;
    if ((content.isEmpty && image == null) || _isSending) return;

    setState(() => _isSending = true);

    try {
      await apiClient.sendMessage(
        widget.user.id,
        content.isEmpty ? '[Photo]' : content,
        //image: image,
      );
      if (!mounted) return;

      setState(() {
        _history.add(
          ChatMessage(
            id: 0,
            senderId: widget.currentUserId,
            recipientId: widget.user.id,
            content: content.isEmpty ? '[Photo]' : content,
            createdAt: DateTime.now(),
            status: 'sent',
            localImage: image,
          ),
        );
        _chat.clear();
        _draftImage = null;
        _isSending = false;
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final now = DateTime.now();
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return DateFormat(sameDay ? 'h:mm a' : 'MMM d, h:mm a').format(local);
  }

  Widget _messageImage(ChatMessage message) {
    final localImage = message.localImage;
    if (localImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(localImage, width: 220, fit: BoxFit.cover),
      );
    }

    final imagePath = message.imagePath;
    if (imagePath == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        apiClient.getImageUrl(imagePath),
        width: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 220,
          height: 120,
          color: Colors.grey.shade300,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image),
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage message) {
    final isMe = message.senderId == widget.currentUserId;
    final hasText = message.content.trim().isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFFFCC00) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (message.hasImage) _messageImage(message),
              if (message.hasImage && hasText) const SizedBox(height: 8),
              if (hasText) Text(message.content),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _draftImagePreview() {
    final image = _draftImage;
    if (image == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              image,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton.filled(
              tooltip: 'Remove photo',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _draftImage = null),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.user.displayName)),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _ErrorState(message: _errorMessage!, onRetry: _loadHistory)
                : _history.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (_, i) => _buildBubble(_history[i]),
                  ),
          ),
          _draftImagePreview(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Attach photo',
                    icon: const Icon(Icons.image, color: Color(0xFF0066CC)),
                    onPressed: _isSending ? null : _pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _chat,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF2F5F9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _isSending ? null : _send,
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
