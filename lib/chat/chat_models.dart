import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomPreview {
  final String id;
  final List<String> participantIds;
  final List<String> participantNames;
  final String lastMessage;
  final DateTime? lastMessageAt;

  const ChatRoomPreview({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  factory ChatRoomPreview.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return ChatRoomPreview(
      id: doc.id,
      participantIds:
          (data['participantIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      participantNames:
          (data['participantNames'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastMessage: data['lastMessage']?.toString() ?? '',
      lastMessageAt: _asDateTime(data['lastMessageAt']),
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime? createdAt;
  final String type;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentMimeType;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    this.type = 'text',
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentMimeType,
  });

  factory ChatMessage.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return ChatMessage(
      id: doc.id,
      text: data['text']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? '',
      createdAt: _asDateTime(data['createdAt']),
      type: data['type']?.toString() ?? 'text',
      attachmentUrl: data['attachmentUrl']?.toString(),
      attachmentName: data['attachmentName']?.toString(),
      attachmentMimeType: data['attachmentMimeType']?.toString(),
    );
  }

  bool get hasAttachment =>
      (attachmentUrl ?? '').trim().isNotEmpty && type != 'text';

  bool get isImageAttachment => hasAttachment && type == 'image';
}

DateTime? _asDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
