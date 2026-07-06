import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coupon.dart';
import '../models/api_models.dart';

class ApiService {
  static const String baseUrl = 'https://couponey.net';

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ─── Full bundle /api/home ────────────────────────────────────────
  static Future<HomeBundle> fetchHome() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/home'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) return HomeBundle.fromJson(jsonDecode(res.body));
    throw Exception('fetchHome failed (${res.statusCode})');
  }

  // ─── /api/site ────────────────────────────────────────────────────
  static Future<SiteInfo> fetchSite() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/site'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return SiteInfo.fromJson(data is Map ? (data['data'] ?? data) : {});
    }
    throw Exception('fetchSite failed (${res.statusCode})');
  }

  // ─── /api/hero (also used for footer) ────────────────────────────
  static Future<HeroData> fetchHero() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/hero'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return HeroData.fromJson(data is Map ? (data['data'] ?? data) : {});
    }
    throw Exception('fetchHero failed (${res.statusCode})');
  }

  // ─── /api/offers ─────────────────────────────────────────────────
  static Future<List<Store>> fetchOffers() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/offers'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? data['offers'] ?? []);
      return (list as List).map((e) => Store.fromJson(e)).toList();
    }
    throw Exception('fetchOffers failed (${res.statusCode})');
  }

  // ─── /api/stores ─────────────────────────────────────────────────
  static Future<List<Store>> fetchStores() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/stores'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? data['stores'] ?? []);
      return (list as List).map((e) => Store.fromJson(e)).toList();
    }
    throw Exception('fetchStores failed (${res.statusCode})');
  }

  // ─── /api/stores/for-filters ─────────────────────────────────────
  static Future<List<String>> fetchStoresForFilters() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/stores/for-filters'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['data'] ?? []);
      return (list as List)
          .map((e) => e['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    throw Exception('fetchStoresForFilters failed (${res.statusCode})');
  }

  // ─── /api/labels ─────────────────────────────────────────────────
  static Future<AppLabels> fetchLabels() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/labels'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return AppLabels.fromJson(data is Map ? (data['data'] ?? data) : {});
    }
    throw Exception('fetchLabels failed (${res.statusCode})');
  }

  // ─── /api/coupons/{type} ─────────────────────────────────────────
  static Future<List<Coupon>> fetchCoupons({String type = 'latest'}) async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/coupons/$type'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list =
          data is List ? data : (data['data'] ?? data['coupons'] ?? []);
      return (list as List).map((e) => Coupon.fromJson(e)).toList();
    }
    throw Exception('fetchCoupons($type) failed (${res.statusCode})');
  }

  // ─── كل الكوبونات من الـ 3 endpoints ────────────────────────────
  static Future<List<Coupon>> fetchAllCoupons() async {
    final results = await Future.wait([
      fetchCoupons(type: 'latest').catchError((_) => <Coupon>[]),
      fetchCoupons(type: 'most-used').catchError((_) => <Coupon>[]),
      fetchCoupons(type: 'high-discount').catchError((_) => <Coupon>[]),
    ]);
    final all = <Coupon>[];
    final seen = <String>{};
    for (final list in results) {
      for (final c in list) {
        if (seen.add(c.id)) all.add(c);
      }
    }
    return all;
  }

  // ─── /api/app-download ───────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchAppDownload() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/app-download'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data is Map<String, dynamic> ? data : {};
    }
    return {};
  }

  // ─── /api/footer ─────────────────────────────────────────────────
  static Future<FooterData> fetchFooter() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/footer'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return FooterData.fromJson(data is Map ? (data['data'] ?? data) : {});
    }
    throw Exception('fetchFooter failed (${res.statusCode})');
  }

  // ─── Newsletter Subscribe ─────────────────────────────────────────
  // ✅ الـ API بتستخدم form-data (multipart) مش JSON
  static Future<bool> subscribeNewsletter(String email) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/newsletter/subscribe'),
    );
    request.headers['Accept'] = 'application/json';
    request.fields['email'] = email;

    final streamed = await request.send().timeout(const Duration(seconds: 10));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) return true;

    try {
      final data = jsonDecode(res.body);
      final msg = data['message']?.toString() ?? '';
      throw Exception(
          msg.isNotEmpty ? msg : 'فشل الاشتراك (${res.statusCode})');
    } catch (_) {
      throw Exception('فشل الاشتراك (${res.statusCode})');
    }
  }
}
