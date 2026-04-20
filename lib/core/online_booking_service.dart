import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/client.dart';
import '../models/order.dart' as app_models;
import 'app_data_service.dart';
import 'constants.dart';

class OnlineBookingService {
  OnlineBookingService._();

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  static String? _activeUid;

  static bool get _ready =>
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  static Future<void> start() async {
    if (!_ready) {
      debugPrint('[OnlineBookingService] Firebase not ready, skipping start');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    if (_activeUid == uid && _sub != null) {
      debugPrint('[OnlineBookingService] Already listening for uid: $uid');
      return;
    }

    debugPrint('[OnlineBookingService] Starting for uid: $uid');
    await stop();
    _activeUid = uid;

    _sub = FirebaseFirestore.instance
        .collection('booking_requests')
        .where('masterUid', isEqualTo: uid)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint(
              '[OnlineBookingService] Got snapshot with ${snapshot.docChanges.length} changes',
            );
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.removed) {
                continue;
              }
              unawaited(_importRequestIfNeeded(change.doc));
            }
          },
          onError: (Object error) {
            debugPrint('[OnlineBookingService] Subscription error: $error');
          },
        );
  }

  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _activeUid = null;
  }

  static Future<void> _importRequestIfNeeded(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      final data = doc.data();
      if (data == null) {
        return;
      }
      final status = (data['status']?.toString() ?? 'pending').toLowerCase();
      final imported = data['importedToApp'] == true;
      if (imported || status != 'accepted') {
        return;
      }

      final clientsBox = Hive.box(HiveBoxes.clients);
      final ordersBox = Hive.box(HiveBoxes.orders);

      final clientName = data['clientName']?.toString().trim() ?? '';
      if (clientName.isEmpty) {
        return;
      }

      final clientPhone = data['clientPhone']?.toString().trim();
      final normalizedIncomingPhone = _normalizePhone(clientPhone);
      final car = data['car']?.toString().trim() ?? '';
      final service = data['service']?.toString().trim() ?? '';
      final note = data['note']?.toString().trim();

      MapEntry<dynamic, dynamic>? existingClientEntry;
      for (final entry in clientsBox.toMap().entries) {
        final value = entry.value;
        if (value is! Map) {
          continue;
        }
        final existingPhone = _normalizePhone(value['phone']?.toString());
        final samePhone =
            normalizedIncomingPhone.isNotEmpty &&
            existingPhone == normalizedIncomingPhone;
        final sameName =
            (value['name']?.toString().trim().toLowerCase() ?? '') ==
            clientName.toLowerCase();
        if (samePhone || sameName) {
          existingClientEntry = entry;
          break;
        }
      }

      String clientId;
      if (existingClientEntry != null && existingClientEntry.value is Map) {
        final current = Map<String, dynamic>.from(
          existingClientEntry.value as Map,
        );
        clientId = current['id']?.toString().isNotEmpty == true
            ? current['id'].toString()
            : DateTime.now().microsecondsSinceEpoch.toString();
        final currentCars =
            (current['cars'] as List?)?.map((e) => e.toString()).toList() ??
            <String>[];
        if (car.isNotEmpty && !currentCars.contains(car)) {
          currentCars.add(car);
        }
        current['id'] = clientId;
        current['name'] =
            (current['name']?.toString().trim().isNotEmpty ?? false)
            ? current['name']
            : clientName;
        if ((current['phone']?.toString().trim().isEmpty ?? true) &&
            normalizedIncomingPhone.isNotEmpty) {
          current['phone'] = normalizedIncomingPhone;
        }
        current['cars'] = currentCars;
        current['createdAt'] ??= DateTime.now().millisecondsSinceEpoch;
        await clientsBox.put(existingClientEntry.key, current);
        await AppDataService.syncClientToCloud(current);
      } else {
        clientId = DateTime.now().microsecondsSinceEpoch.toString();
        final client = Client(
          id: clientId,
          name: clientName,
          phone: normalizedIncomingPhone.isNotEmpty
              ? normalizedIncomingPhone
              : clientPhone,
          cars: car.isNotEmpty ? [car] : const [],
          notes: note != null && note.isNotEmpty ? note : null,
          createdAt: DateTime.now(),
        );
        final clientMap = client.toMap();
        await clientsBox.add(clientMap);
        await AppDataService.syncClientToCloud(clientMap);
      }

      final orderId = doc.id;
      final existsOrder = ordersBox.values.cast<dynamic>().any((value) {
        if (value is! Map) {
          return false;
        }
        return value['id']?.toString() == orderId;
      });

      if (!existsOrder) {
        final scheduledDate = _parseScheduledDate(
          data['preferredDate']?.toString(),
          data['preferredTime']?.toString(),
        );
        final scheduledTime = _normalizedTime(
          data['preferredTime']?.toString(),
        );
        final order = app_models.Order(
          id: orderId,
          clientId: clientId,
          car: car,
          client: clientName,
          service: service,
          duration: 0,
          price: 0,
          status: OrderStatus.scheduled,
          timestamp: DateTime.now(),
          scheduledDate: scheduledDate,
          scheduledTime: scheduledTime,
          notes: _buildOrderNotes(note, source: 'online-booking'),
        );
        final orderMap = order.toMap();
        await ordersBox.add(orderMap);
        await AppDataService.syncOrderToCloud(orderMap);
      }

      await doc.reference.update({
        'importedToApp': true,
        'importedAt': FieldValue.serverTimestamp(),
        'importedOrderId': orderId,
        'importedClientId': clientId,
      });
    } catch (e) {
      debugPrint(
        '[OnlineBookingService] Failed to import request ${doc.id}: $e',
      );
    }
  }

  static DateTime _parseScheduledDate(String? date, String? time) {
    final now = DateTime.now();
    if (date == null || date.isEmpty) {
      return now;
    }
    final parts = date.split('-');
    if (parts.length != 3) {
      return now;
    }
    final year = int.tryParse(parts[0]) ?? now.year;
    final month = int.tryParse(parts[1]) ?? now.month;
    final day = int.tryParse(parts[2]) ?? now.day;
    final timeParts = (time ?? '').split(':');
    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    return DateTime(year, month, day, hour, minute);
  }

  static String _normalizedTime(String? time) {
    if (time == null || time.isEmpty) {
      return '00:00';
    }
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static String _normalizePhone(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }

    var digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('00')) {
      digits = '+${digits.substring(2)}';
    }
    if (!digits.startsWith('+') && digits.isNotEmpty) {
      digits = '+$digits';
    }
    return digits;
  }

  static String? _buildOrderNotes(String? note, {required String source}) {
    final normalized = note?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Source: $source';
    }
    return 'Source: $source\n$normalized';
  }
}
