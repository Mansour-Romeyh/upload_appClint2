// lib/services/remote_config_service.dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final _rc = FirebaseRemoteConfig.instance;
  
  /// القيمة الافتراضية false — الوضع العادي
  static bool get isReviewMode {
    try {
      final val = _rc.getBool('review_mode');
      print('[RemoteConfig] isReviewMode: $val');
      return val;
    } catch (e) {
      print('[RemoteConfig] isReviewMode error fallback: $e');
      return false;
    }
  }

  static Future<void> initialize() async {
    try {
      print('[RemoteConfig] Initializing...');
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(seconds: 5), // Change to 5 seconds for testing
      ));

      await _rc.setDefaults({'review_mode': false});

      print('[RemoteConfig] Fetching and activating...');
      final activated = await _rc.fetchAndActivate();
      print('[RemoteConfig] Fetch & activate result: $activated, current review_mode: ${isReviewMode}');
    } catch (e, stack) {
      print('[RemoteConfig] Initialization failed: $e');
      print(stack);
    }
  }

  static Future<void> refresh() async {
    try {
      print('[RemoteConfig] Refreshing...');
      await _rc.fetchAndActivate();
      print('[RemoteConfig] Refresh done. review_mode: ${isReviewMode}');
    } catch (e) {
      print('[RemoteConfig] Refresh failed: $e');
    }
  }
}
