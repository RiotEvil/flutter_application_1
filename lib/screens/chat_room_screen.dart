import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../chat/chat_models.dart';
import '../chat/firestore_chat_service.dart';
import '../core/access_guard.dart';
import '../core/cloud_file_storage.dart';
import '../core/constants.dart';
import '../core/subscription_texts.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.currentUserName,
    required this.roomTitle,
    required this.isTeamMode,
    this.orgId,
  });

  final String roomId;
  final String currentUserId;
  final String currentUserName;
  final String roomTitle;
  final bool isTeamMode;
  final String? orgId;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  FirestoreChatService? _chatService;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (Firebase.apps.isNotEmpty) {
      _chatService = FirestoreChatService(
        orgId: widget.orgId,
        isTeamScoped: widget.isTeamMode,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await _chatService?.sendMessage(
        roomId: widget.roomId,
        text: text,
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
      );
      _messageController.clear();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _sendPickedImage() async {
    if (_sending || _chatService == null) return;
    if (!AccessGuard.canUseChatAttachments()) {
      await AccessGuard.showUpgradePrompt(
        context,
        title: SubscriptionTexts.chatAttachmentsProTitle(context),
        message: SubscriptionTexts.chatAttachmentsProMessage(context),
        requiredPlan: AppPlan.pro,
      );
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;

      await _uploadAndSendAttachment(
        fileName: picked.name,
        isImage: true,
        bytes: await picked.readAsBytes(),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatUploadFailed(e.toString()))),
      );
    }
  }

  Future<void> _sendPickedFile() async {
    if (_sending || _chatService == null) return;
    if (!AccessGuard.canUseChatAttachments()) {
      await AccessGuard.showUpgradePrompt(
        context,
        title: SubscriptionTexts.fileSharingProTitle(context),
        message: SubscriptionTexts.fileSharingProMessage(context),
        requiredPlan: AppPlan.pro,
      );
      return;
    }
    try {
      final picked = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: false,
      );
      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.first;
      await _uploadAndSendAttachment(
        fileName: file.name,
        isImage: false,
        bytes: file.bytes,
        filePath: file.path,
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatUploadFailed(e.toString()))),
      );
    }
  }

  Future<void> _uploadAndSendAttachment({
    required String fileName,
    required bool isImage,
    Uint8List? bytes,
    String? filePath,
  }) async {
    if (_chatService == null) return;
    setState(() => _sending = true);
    try {
      final url = await CloudFileStorage.uploadChatAttachment(
        roomId: widget.roomId,
        senderId: widget.currentUserId,
        fileName: fileName,
        isImage: isImage,
        bytes: bytes,
        filePath: filePath,
      );

      await _chatService!.sendMessage(
        roomId: widget.roomId,
        text: _messageController.text.trim(),
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        type: isImage ? 'image' : 'file',
        attachmentUrl: url,
        attachmentName: fileName,
      );

      _messageController.clear();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _openAttachment(String url) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.chatFileOpenFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.roomTitle)),
      body: Column(
        children: [
          if (_chatService == null)
            Expanded(child: Center(child: Text(l10n.chatOpenAfterFirebase)))
          else
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _chatService!.watchMessages(widget.roomId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(l10n.chatConnectionError));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;
                  if (messages.isEmpty) {
                    return Center(child: Text(l10n.chatNoMessages));
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine = message.senderId == widget.currentUserId;

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 320),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMine)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    message.senderName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              if (message.text.trim().isNotEmpty)
                                Text(
                                  message.text,
                                  style: TextStyle(
                                    color: isMine ? Colors.black : Colors.white,
                                  ),
                                ),
                              if (message.hasAttachment) ...[
                                const SizedBox(height: 8),
                                if (message.isImageAttachment)
                                  GestureDetector(
                                    onTap: () =>
                                        _openAttachment(message.attachmentUrl!),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 180,
                                        height: 140,
                                        child: Image.network(
                                          message.attachmentUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  InkWell(
                                    onTap: () =>
                                        _openAttachment(message.attachmentUrl!),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.attach_file, size: 18),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            message.attachmentName ??
                                                l10n.chatAttachmentFile,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              decoration:
                                                  TextDecoration.underline,
                                              color: isMine
                                                  ? Colors.black
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: l10n.chatMessageHint,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.chatAttachPhoto,
                    onPressed: _sending ? null : _sendPickedImage,
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                  IconButton(
                    tooltip: l10n.chatAttachFile,
                    onPressed: _sending ? null : _sendPickedFile,
                    icon: const Icon(Icons.attach_file),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
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
