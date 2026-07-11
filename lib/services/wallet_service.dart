// lib/services/wallet_service.dart
// خدمة المحفظة — تدير الكوبونات المستخدمة، التقييمات، وتتبع التوفير

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// حالة الكوبون في المحفظة
enum CouponStatus { ready, used, expired }

/// بيانات كوبون في المحفظة
class WalletCoupon {
  final String couponId;
  final String storeName;
  final String code;
  final String title;
  final String storeLogo;
  final CouponStatus status;
  final double? savedAmount;
  final DateTime addedAt;
  final DateTime? usedAt;

  WalletCoupon({
    required this.couponId,
    required this.storeName,
    required this.code,
    required this.title,
    required this.storeLogo,
    required this.status,
    this.savedAmount,
    required this.addedAt,
    this.usedAt,
  });

  Map<String, dynamic> toJson() => {
    'couponId': couponId,
    'storeName': storeName,
    'code': code,
    'title': title,
    'storeLogo': storeLogo,
    'status': status.index,
    'savedAmount': savedAmount,
    'addedAt': addedAt.toIso8601String(),
    'usedAt': usedAt?.toIso8601String(),
  };

  factory WalletCoupon.fromJson(Map<String, dynamic> json) => WalletCoupon(
    couponId: json['couponId'] ?? '',
    storeName: json['storeName'] ?? '',
    code: json['code'] ?? '',
    title: json['title'] ?? '',
    storeLogo: json['storeLogo'] ?? '',
    status: CouponStatus.values[json['status'] ?? 0],
    savedAmount: (json['savedAmount'] as num?)?.toDouble(),
    addedAt: DateTime.tryParse(json['addedAt'] ?? '') ?? DateTime.now(),
    usedAt: json['usedAt'] != null ? DateTime.tryParse(json['usedAt']) : null,
  );

  WalletCoupon copyWith({
    CouponStatus? status,
    double? savedAmount,
    DateTime? usedAt,
  }) => WalletCoupon(
    couponId: couponId,
    storeName: storeName,
    code: code,
    title: title,
    storeLogo: storeLogo,
    status: status ?? this.status,
    savedAmount: savedAmount ?? this.savedAmount,
    addedAt: addedAt,
    usedAt: usedAt ?? this.usedAt,
  );
}

/// تقييم كوبون
class CouponRating {
  final String couponId;
  final bool isPositive; // true = 👍, false = 👎
  final DateTime ratedAt;

  CouponRating({
    required this.couponId,
    required this.isPositive,
    required this.ratedAt,
  });

  Map<String, dynamic> toJson() => {
    'couponId': couponId,
    'isPositive': isPositive,
    'ratedAt': ratedAt.toIso8601String(),
  };

  factory CouponRating.fromJson(Map<String, dynamic> json) => CouponRating(
    couponId: json['couponId'] ?? '',
    isPositive: json['isPositive'] ?? true,
    ratedAt: DateTime.tryParse(json['ratedAt'] ?? '') ?? DateTime.now(),
  );
}

/// إحصائيات المتجر المفضل
class FavoriteStorePrefs {
  final String storeName;
  final bool notificationsEnabled;

  FavoriteStorePrefs({
    required this.storeName,
    this.notificationsEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'storeName': storeName,
    'notificationsEnabled': notificationsEnabled,
  };

  factory FavoriteStorePrefs.fromJson(Map<String, dynamic> json) => FavoriteStorePrefs(
    storeName: json['storeName'] ?? '',
    notificationsEnabled: json['notificationsEnabled'] ?? true,
  );
}

/// خدمة المحفظة الرئيسية
class WalletService {
  static const _walletKey = 'coupon_wallet';
  static const _ratingsKey = 'coupon_ratings';
  static const _ratingCountsKey = 'coupon_rating_counts';
  static const _favoriteStoresKey = 'favorite_stores_prefs';
  static const _usageStatsKey = 'usage_stats';
  static const _challengeKey = 'weekly_challenge';

  // ─── محفظة الكوبونات ──────────────────────────────────────────
  static Future<List<WalletCoupon>> getWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_walletKey);
      if (data == null) return [];
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => WalletCoupon.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveWallet(List<WalletCoupon> wallet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_walletKey, jsonEncode(wallet.map((e) => e.toJson()).toList()));
  }

  static Future<void> addToWallet(WalletCoupon coupon) async {
    final wallet = await getWallet();
    // لو موجود بالفعل، ما نضيفوش تاني
    if (wallet.any((c) => c.couponId == coupon.couponId)) return;
    wallet.insert(0, coupon);
    await _saveWallet(wallet);
  }

  static Future<void> markAsUsed(String couponId, double savedAmount) async {
    final wallet = await getWallet();
    final index = wallet.indexWhere((c) => c.couponId == couponId);
    if (index != -1) {
      wallet[index] = wallet[index].copyWith(
        status: CouponStatus.used,
        savedAmount: savedAmount,
        usedAt: DateTime.now(),
      );
      await _saveWallet(wallet);
      // تحديث إحصائيات الاستخدام
      await _updateUsageStats(wallet[index].storeName, savedAmount);
    }
  }

  static Future<void> removeFromWallet(String couponId) async {
    final wallet = await getWallet();
    wallet.removeWhere((c) => c.couponId == couponId);
    await _saveWallet(wallet);
  }

  static Future<bool> isInWallet(String couponId) async {
    final wallet = await getWallet();
    return wallet.any((c) => c.couponId == couponId);
  }

  // ─── تقييمات الكوبونات ────────────────────────────────────────
  static Future<Map<String, CouponRating>> getUserRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_ratingsKey);
      if (data == null) return {};
      final Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map((k, v) => MapEntry(k, CouponRating.fromJson(v)));
    } catch (_) {
      return {};
    }
  }

  static Future<void> rateCoupon(String couponId, bool isPositive) async {
    // حفظ تقييم المستخدم
    final ratings = await getUserRatings();
    final oldRating = ratings[couponId];
    ratings[couponId] = CouponRating(
      couponId: couponId,
      isPositive: isPositive,
      ratedAt: DateTime.now(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ratingsKey, jsonEncode(
      ratings.map((k, v) => MapEntry(k, v.toJson())),
    ));

    // تحديث العداد العام
    final counts = await getRatingCounts();
    final current = counts[couponId] ?? {'up': 0, 'down': 0};
    int up = current['up'] ?? 0;
    int down = current['down'] ?? 0;

    // لو كان فيه تقييم قديم، ارجعه
    if (oldRating != null) {
      if (oldRating.isPositive) {
        up = (up - 1).clamp(0, 999999);
      } else {
        down = (down - 1).clamp(0, 999999);
      }
    }

    // ضيف التقييم الجديد
    if (isPositive) {
      up++;
    } else {
      down++;
    }

    counts[couponId] = {'up': up, 'down': down};
    await prefs.setString(_ratingCountsKey, jsonEncode(counts));
  }

  static Future<Map<String, Map<String, int>>> getRatingCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_ratingCountsKey);
      if (data == null) return {};
      final Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map((k, v) => MapEntry(
        k,
        Map<String, int>.from((v as Map).map((k2, v2) => MapEntry(k2.toString(), (v2 as num).toInt()))),
      ));
    } catch (_) {
      return {};
    }
  }

  /// نسبة التقييمات الإيجابية (0.0 - 1.0) وعدد التقييمات
  static Future<Map<String, dynamic>> getCouponRatingInfo(String couponId) async {
    final counts = await getRatingCounts();
    final data = counts[couponId];
    if (data == null) return {'ratio': 0.0, 'total': 0, 'up': 0, 'down': 0};
    final up = data['up'] ?? 0;
    final down = data['down'] ?? 0;
    final total = up + down;
    return {
      'ratio': total > 0 ? up / total : 0.0,
      'total': total,
      'up': up,
      'down': down,
    };
  }

  // ─── المتاجر المفضلة ──────────────────────────────────────────
  static Future<List<FavoriteStorePrefs>> getFavoriteStores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_favoriteStoresKey);
      if (data == null) return [];
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => FavoriteStorePrefs.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> toggleFavoriteStore(String storeName) async {
    final stores = await getFavoriteStores();
    final index = stores.indexWhere((s) => s.storeName == storeName);
    if (index != -1) {
      stores.removeAt(index);
    } else {
      stores.add(FavoriteStorePrefs(storeName: storeName));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoriteStoresKey, jsonEncode(stores.map((e) => e.toJson()).toList()));
  }

  static Future<bool> isStoreFavorite(String storeName) async {
    final stores = await getFavoriteStores();
    return stores.any((s) => s.storeName == storeName);
  }

  // ─── إحصائيات الاستخدام ────────────────────────────────────────
  static Future<void> _updateUsageStats(String storeName, double savedAmount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_usageStatsKey);
      Map<String, dynamic> stats = data != null ? jsonDecode(data) : {};

      // إجمالي التوفير
      stats['totalSaved'] = ((stats['totalSaved'] as num?)?.toDouble() ?? 0.0) + savedAmount;

      // عدد الكوبونات المستخدمة
      stats['totalUsed'] = ((stats['totalUsed'] as num?)?.toInt() ?? 0) + 1;

      // التوفير حسب المتجر
      Map<String, dynamic> storeStats = Map<String, dynamic>.from(stats['byStore'] ?? {});
      final storeSaved = ((storeStats[storeName] as num?)?.toDouble() ?? 0.0) + savedAmount;
      storeStats[storeName] = storeSaved;
      stats['byStore'] = storeStats;

      // التوفير حسب الشهر
      final monthKey = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      Map<String, dynamic> monthStats = Map<String, dynamic>.from(stats['byMonth'] ?? {});
      monthStats[monthKey] = ((monthStats[monthKey] as num?)?.toDouble() ?? 0.0) + savedAmount;
      stats['byMonth'] = monthStats;

      await prefs.setString(_usageStatsKey, jsonEncode(stats));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getUsageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_usageStatsKey);
      if (data == null) {
        return {
          'totalSaved': 0.0,
          'totalUsed': 0,
          'byStore': <String, dynamic>{},
          'byMonth': <String, dynamic>{},
        };
      }
      return jsonDecode(data);
    } catch (_) {
      return {
        'totalSaved': 0.0,
        'totalUsed': 0,
        'byStore': <String, dynamic>{},
        'byMonth': <String, dynamic>{},
      };
    }
  }

  // ─── تحدي التوفير الأسبوعي ─────────────────────────────────────
  static Future<Map<String, dynamic>> getWeeklyChallenge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_challengeKey);
      if (data == null) return _generateNewChallenge();
      
      final challenge = jsonDecode(data) as Map<String, dynamic>;
      // تحقق هل التحدي لسه ساري
      final expiresAt = DateTime.tryParse(challenge['expiresAt'] ?? '');
      if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
        return _generateNewChallenge();
      }
      return challenge;
    } catch (_) {
      return _generateNewChallenge();
    }
  }

  static Map<String, dynamic> _generateNewChallenge() {
    final challenges = [
      {'title': 'تحدي المئة', 'target': 100.0, 'emoji': '💯'},
      {'title': 'توفير ذكي', 'target': 200.0, 'emoji': '🧠'},
      {'title': 'صياد الخصومات', 'target': 150.0, 'emoji': '🎯'},
      {'title': 'بطل التوفير', 'target': 300.0, 'emoji': '🏆'},
      {'title': 'تسوق بذكاء', 'target': 250.0, 'emoji': '🛒'},
    ];
    
    final now = DateTime.now();
    // التحدي ينتهي نهاية الأسبوع (الجمعة)
    final daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
    final expiresAt = DateTime(now.year, now.month, now.day + (daysUntilFriday == 0 ? 7 : daysUntilFriday), 23, 59, 59);
    
    final index = now.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay % challenges.length;
    final challenge = challenges[index];
    
    final result = {
      'title': challenge['title'],
      'target': challenge['target'],
      'emoji': challenge['emoji'],
      'current': 0.0,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': now.toIso8601String(),
    };
    
    // حفظ التحدي الجديد
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_challengeKey, jsonEncode(result));
    });
    
    return result;
  }

  static Future<void> updateChallengeProgress(double amount) async {
    final challenge = await getWeeklyChallenge();
    challenge['current'] = ((challenge['current'] as num?)?.toDouble() ?? 0.0) + amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_challengeKey, jsonEncode(challenge));
  }
}
