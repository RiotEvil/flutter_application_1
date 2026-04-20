import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constants.dart';

class CloudTenantPaths {
  CloudTenantPaths._();

  static String? currentOrgId() {
    final settingsBox = Hive.box(HiveBoxes.settings);
    final orgId = settingsBox.get('orgId')?.toString();
    if (orgId == null || orgId.isEmpty) {
      return null;
    }
    return orgId;
  }

  static DocumentReference<Map<String, dynamic>> organizationDoc(
    FirebaseFirestore firestore,
    String orgId,
  ) {
    return firestore.collection('organizations').doc(orgId);
  }

  static CollectionReference<Map<String, dynamic>> orgCollection(
    FirebaseFirestore firestore,
    String orgId,
    String collection,
  ) {
    return organizationDoc(firestore, orgId).collection(collection);
  }

  static CollectionReference<Map<String, dynamic>> orders(
    FirebaseFirestore firestore,
    String orgId,
  ) {
    return orgCollection(firestore, orgId, 'orders');
  }

  static CollectionReference<Map<String, dynamic>> clients(
    FirebaseFirestore firestore,
    String orgId,
  ) {
    return orgCollection(firestore, orgId, 'clients');
  }

  static CollectionReference<Map<String, dynamic>> inventory(
    FirebaseFirestore firestore,
    String orgId,
  ) {
    return orgCollection(firestore, orgId, 'inventory');
  }

  static CollectionReference<Map<String, dynamic>> services(
    FirebaseFirestore firestore,
    String orgId,
  ) {
    return orgCollection(firestore, orgId, 'services');
  }

  static CollectionReference<Map<String, dynamic>> internalChatRooms(
    FirebaseFirestore firestore,
    String orgId,
  ) {
    return orgCollection(firestore, orgId, 'chat_rooms');
  }

  static CollectionReference<Map<String, dynamic>> externalChatRooms(
    FirebaseFirestore firestore,
  ) {
    return firestore.collection('chat_rooms');
  }
}
