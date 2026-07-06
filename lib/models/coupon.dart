// lib/models/coupon.dart

String _normalizeUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http')) return trimmed;
  if (trimmed.startsWith('assets/')) return trimmed;
  if (trimmed.startsWith('/')) return 'https://couponey.net$trimmed';
  return 'https://couponey.net/$trimmed';
}

class Coupon {
  final String id;
  final String storeId;
  final String storeName;
  final String storeLogo;
  final String storeImage;
  final String title;
  final String code;
  final String expiryText;
  final String badge;
  final String storeUrl;
  final int discountPercent;
  final String discountRaw;
  final String category;
  final String country;

  Coupon({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.storeLogo,
    required this.storeImage,
    required this.title,
    required this.code,
    required this.expiryText,
    required this.badge,
    required this.storeUrl,
    required this.discountPercent,
    required this.category,
    this.country = '',
    required this.discountRaw,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    final store = json['store'] as Map<String, dynamic>?;

    final storeLogo = _normalizeUrl(store?['logo_url']?.toString() ?? '');
    final couponImage = _normalizeUrl(
        json['card_image']?.toString() ?? json['image_url']?.toString() ?? '');
    final storeUrl = _normalizeUrl(
        store?['url']?.toString() ?? json['link']?.toString() ?? '');
    final discountRaw = (json['discount'] ?? '').toString();

    final discountPercent = int.tryParse(
          discountRaw.replaceAll('%', '').trim(),
        ) ??
        0;
    return Coupon(
      id: (json['id'] ?? '').toString(),
      storeId: (json['store_id'] ?? store?['id'] ?? '').toString(),
      storeName: store?['name']?.toString() ?? '',
      storeLogo: storeLogo,
      storeImage: couponImage.isNotEmpty ? couponImage : storeLogo,
      title: json['title']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      expiryText: json['duration_label']?.toString() ?? 'غير محدد',
      badge: json['badge']?.toString() ?? 'مميز',
      storeUrl: storeUrl,
      discountPercent: discountPercent,
      category:
          store?['category_label']?.toString() ?? '', // ✅ كما هي من الـ API
      country: json['country_label']?.toString() ??
          store?['country']?.toString() ??
          '',
      discountRaw: (json['discount'] ?? '0').toString(),
    );
  }
}

class Store {
  final String id;
  final String name;
  final String logoUrl;
  final String url;

  Store({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.url,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    final logo = _normalizeUrl(json['image_url']?.toString() ??
        json['logo_url']?.toString() ??
        json['logo']?.toString() ??
        '');
    final storeUrl = _normalizeUrl(json['url']?.toString() ?? json['link']?.toString() ?? '');
    return Store(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      logoUrl: logo,
      url: storeUrl,
    );
  }
}
