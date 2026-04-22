import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ForceUpdateResult {
  final bool required;
  final String? storeUrl;

  const ForceUpdateResult({required this.required, this.storeUrl});
}

class ForceUpdateService {
  ForceUpdateService._();

  /// Checks Firestore `app_config/versions` for the minimum required version.
  /// Returns [ForceUpdateResult.required] = true if the current build is outdated.
  /// Always returns false on web (web always serves the latest build).
  static Future<ForceUpdateResult> check() async {
    if (kIsWeb) return const ForceUpdateResult(required: false);
    if (Firebase.apps.isEmpty) return const ForceUpdateResult(required: false);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('versions')
          .get();

      if (!snap.exists) return const ForceUpdateResult(required: false);

      final data = snap.data()!;

      String? minVersion;
      String? storeUrl;

      if (defaultTargetPlatform == TargetPlatform.android) {
        minVersion = data['minAndroid']?.toString();
        storeUrl = data['androidUrl']?.toString();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        minVersion = data['minIos']?.toString();
        storeUrl = data['iosUrl']?.toString();
      } else {
        // Windows / desktop — no store URL, still honour minVersion if present
        minVersion = data['minVersion']?.toString();
        storeUrl = data['downloadUrl']?.toString();
      }

      if (minVersion == null || minVersion.isEmpty) {
        return const ForceUpdateResult(required: false);
      }

      final info = await PackageInfo.fromPlatform();
      if (_isOlderThan(info.version, minVersion)) {
        return ForceUpdateResult(required: true, storeUrl: storeUrl);
      }
    } catch (e) {
      debugPrint('[ForceUpdate] check error: $e');
    }

    return const ForceUpdateResult(required: false);
  }

  /// Returns true if [version] is strictly older than [minimum].
  static bool _isOlderThan(String version, String minimum) {
    final v = _parse(version);
    final m = _parse(minimum);
    for (int i = 0; i < 3; i++) {
      if (v[i] < m[i]) return true;
      if (v[i] > m[i]) return false;
    }
    return false; // equal — not outdated
  }

  static List<int> _parse(String v) {
    final parts = v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (parts.length < 3) { parts.add(0); }
    return parts.sublist(0, 3);
  }
}
