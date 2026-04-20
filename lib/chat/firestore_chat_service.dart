import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/cloud_tenant_paths.dart';
import 'chat_models.dart';

class FirestoreChatService {
  FirestoreChatService({
    FirebaseFirestore? firestore,
    this.orgId,
    this.isTeamScoped = false,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String? orgId;
  final bool isTeamScoped;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      isTeamScoped && orgId != null && orgId!.isNotEmpty
      ? CloudTenantPaths.internalChatRooms(_firestore, orgId!)
      : CloudTenantPaths.externalChatRooms(_firestore);

  Stream<List<ChatRoomPreview>> watchRoomsForUser(String userId) {
    return _rooms
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs
              .map(ChatRoomPreview.fromSnapshot)
              .toList();
          rooms.sort((a, b) {
            final aTs = a.lastMessageAt;
            final bTs = b.lastMessageAt;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });
          return rooms;
        });
  }

  Stream<List<ChatMessage>> watchMessages(String roomId, {int limit = 100}) {
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ChatMessage.fromSnapshot).toList(),
        );
  }

  Future<String> createOrGetDirectRoom({
    required String currentUserId,
    required String currentUserName,
    required String peerUserId,
    required String peerUserName,
  }) async {
    final sortedIds = [currentUserId, peerUserId]..sort();
    final roomId = sortedIds.join('__');

    final roomRef = _rooms.doc(roomId);
    // Do not read the room before writing: external chat rules may block
    // reading non-existing docs, while create/update is allowed for participants.
    await roomRef.set({
      'participantIds': sortedIds,
      'participantNames': [currentUserName, peerUserName],
      'orgId': orgId,
      'scope': isTeamScoped ? 'internal' : 'external',
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return roomId;
  }

  Future<void> sendMessage({
    required String roomId,
    required String text,
    required String senderId,
    required String senderName,
    String type = 'text',
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentMimeType,
  }) async {
    final normalized = text.trim();
    final hasAttachment =
        (attachmentUrl ?? '').trim().isNotEmpty && type != 'text';
    if (normalized.isEmpty && !hasAttachment) return;

    final previewText = hasAttachment
        ? (type == 'image' ? '[Photo]' : '[File]')
        : normalized;

    final roomRef = _rooms.doc(roomId);
    final messageRef = roomRef.collection('messages').doc();

    final batch = _firestore.batch();
    batch.set(messageRef, {
      'text': normalized,
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'attachmentMimeType': attachmentMimeType,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(roomRef, {
      'orgId': orgId,
      'scope': isTeamScoped ? 'internal' : 'external',
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': previewText,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }
}
