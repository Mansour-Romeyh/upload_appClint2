import 'coupon.dart';

// ─── Home Bundle (/api/home) ──────────────────────────────────────
class HomeBundle {
  final List<Store> stores;
  final List<Store> offers;
  final List<Coupon> coupons;
  final SiteInfo? site;
  final HeroData? hero;

  HomeBundle(
      {required this.stores,
      required this.offers,
      required this.coupons,
      this.site,
      this.hero});

  factory HomeBundle.fromJson(Map<String, dynamic> json) {
    List<Store> parseStores(dynamic raw) {
      if (raw == null) return [];
      final list = raw is List ? raw : (raw['data'] ?? []);
      return (list as List).map((e) => Store.fromJson(e)).toList();
    }

    List<Coupon> parseCoupons(dynamic raw) {
      if (raw == null) return [];
      if (raw is Map) {
        final all = <Coupon>[];
        final seen = <String>{};
        for (final key in ['latest', 'most_used', 'high_discount']) {
          final items = raw[key];
          if (items is List) {
            for (final e in items) {
              final c = Coupon.fromJson(e);
              if (seen.add(c.id)) all.add(c);
            }
          }
        }
        return all;
      }
      if (raw is List) return raw.map((e) => Coupon.fromJson(e)).toList();
      return [];
    }

    return HomeBundle(
      stores: parseStores(json['stores']),
      offers: parseStores(json['offers']),
      coupons: parseCoupons(json['coupons']),
      site: json['site'] != null ? SiteInfo.fromJson(json['site']) : null,
      hero: json['hero'] != null ? HeroData.fromJson(json['hero']) : null,
    );
  }
}

// ─── Site Info (/api/site) ────────────────────────────────────────
class SiteInfo {
  final String name;
  final String tagline;
  final String? logoUrl;
  final String? logoWhiteUrl;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? tiktokUrl;
  final String? whatsappUrl;
  final String? twitterUrl;

  SiteInfo({
    required this.name,
    required this.tagline,
    this.logoUrl,
    this.logoWhiteUrl,
    this.facebookUrl,
    this.instagramUrl,
    this.tiktokUrl,
    this.whatsappUrl,
    this.twitterUrl,
  });

  factory SiteInfo.fromJson(Map<String, dynamic> json) {
    final social = json['social_links'] as Map<String, dynamic>? ??
        json['social'] as Map<String, dynamic>? ??
        {};
    return SiteInfo(
      name: json['name']?.toString() ?? json['site_name']?.toString() ?? '',
      tagline:
          json['tagline']?.toString() ?? json['description']?.toString() ?? '',
      logoUrl: json['logo']?.toString() ?? json['logo_url']?.toString(),
      logoWhiteUrl:
          json['logo_white']?.toString() ?? json['logo_w']?.toString(),
      facebookUrl: social['facebook']?.toString() ??
          json['facebook']?.toString() ??
          json['facebook_url']?.toString(),
      instagramUrl: social['instagram']?.toString() ??
          json['instagram']?.toString() ??
          json['instagram_url']?.toString(),
      tiktokUrl: social['tiktok']?.toString() ??
          json['tiktok']?.toString() ??
          json['tiktok_url']?.toString(),
      whatsappUrl: social['whatsapp']?.toString() ??
          json['whatsapp']?.toString() ??
          json['whatsapp_url']?.toString(),
      twitterUrl: social['twitter']?.toString() ??
          json['twitter']?.toString() ??
          json['twitter_url']?.toString(),
    );
  }
}

// ─── Hero Data (/api/hero) ────────────────────────────────────────
// يغطي: hero section + banner announcements + footer
class HeroData {
  final String title;
  final String description;
  final String? imageUrl; // الصورة الجانبية (side_image)
  final String? bgImageUrl; // الخلفية (bg_image)
  final List<String> announcementMessages; // الشريط العلوي المتحرك
  final String? footerDescription;
  // social
  final String? facebookUrl;
  final String? instagramUrl;
  final String? tiktokUrl;
  final String? whatsappUrl;
  final String? twitterUrl;
  final String? logoUrl;
  final String? logoWhiteUrl;

  HeroData({
    required this.title,
    required this.description,
    this.imageUrl,
    this.bgImageUrl,
    this.announcementMessages = const [],
    this.footerDescription,
    this.facebookUrl,
    this.instagramUrl,
    this.tiktokUrl,
    this.whatsappUrl,
    this.twitterUrl,
    this.logoUrl,
    this.logoWhiteUrl,
  });

  factory HeroData.fromJson(Map<String, dynamic> json) {
    // ─── Banner messages ───────────────────────────────────────────
    // الداشبورد: announcements[] - كل عنصر ممكن يكون String أو Map
    List<String> parseMessages(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .map((e) {
              if (e is String) return e;
              if (e is Map) {
                return e['text']?.toString() ??
                    e['message']?.toString() ??
                    e['content']?.toString() ??
                    e['title']?.toString() ??
                    e['phrase']?.toString() ??
                    '';
              }
              return e.toString();
            })
            .where((s) => s.isNotEmpty)
            .toList();
      }
      if (raw is String && raw.isNotEmpty) return [raw];
      return [];
    }

    final social = json['social_links'] as Map<String, dynamic>? ??
        json['social'] as Map<String, dynamic>? ??
        {};

    return HeroData(
      // ─── الداشبورد بيسميهم: title, subtitle, bg_image, side_image ──
      title: json['title']?.toString() ??
          json['heading']?.toString() ??
          json['hero_title']?.toString() ??
          '',
      description: json['paragraph']?.toString() ??
          json['description']?.toString() ??
          json['hero_subtitle']?.toString() ??
          json['text']?.toString() ??
          '',
      // الصورة الجانبية من الداشبورد (رفع الصورة الجانبية)
      imageUrl: json['side_image']?.toString() ??
          json['image']?.toString() ??
          json['image_url']?.toString() ??
          json['hero_image']?.toString(),
      // الخلفية (رفع الصورة الخلفية)
      bgImageUrl: json['background_url']?.toString() ??
          json['background_image']?.toString() ??
          json['background']?.toString(),
      // الشريط العلوي - الداشبورد: announcements[]
      announcementMessages: parseMessages(
        json['announcements'] ??
            json['banners'] ??
            json['marquee'] ??
            json['messages'] ??
            json['ticker'] ??
            json['phrases'],
      ),
      footerDescription: json['footer_description']?.toString() ??
          json['footer_text']?.toString(),
      facebookUrl:
          // social['facebook']?.toString() ??
          //     json['facebook']?.toString() ??
          json['facebook_url']?.toString(),
      instagramUrl: social['instagram']?.toString() ??
          json['instagram']?.toString() ??
          json['instagram_url']?.toString(),
      tiktokUrl: social['tiktok']?.toString() ??
          json['tiktok']?.toString() ??
          json['tiktok_url']?.toString(),
      whatsappUrl: social['whatsapp']?.toString() ??
          json['whatsapp']?.toString() ??
          json['whatsapp_url']?.toString(),
      twitterUrl: social['twitter']?.toString() ??
          json['twitter']?.toString() ??
          json['twitter_url']?.toString(),
      logoUrl: json['logo']?.toString() ?? json['logo_url']?.toString(),
      logoWhiteUrl:
          json['logo_white']?.toString() ?? json['logo_w']?.toString(),
    );
  }
}

// ─── Footer Data (/api/footer) ───────────────────────────────────
class FooterData {
  final String siteName;
  final String? logoUrl;
  final String tagline;
  final String? whatsappUrl;
  final String? instagramUrl;
  final String? facebookUrl;
  final String? tiktokUrl;
  final String newsletterTitle;
  final String newsletterIntro;
  final String newsletterPlaceholder;
  final String copyrightYear;

  FooterData({
    required this.siteName,
    this.logoUrl,
    required this.tagline,
    this.whatsappUrl,
    this.instagramUrl,
    this.facebookUrl,
    this.tiktokUrl,
    required this.newsletterTitle,
    required this.newsletterIntro,
    required this.newsletterPlaceholder,
    required this.copyrightYear,
  });

  factory FooterData.fromJson(Map<String, dynamic> json) {
    final social = json['social'] as Map<String, dynamic>? ?? {};
    final newsletter = json['newsletter'] as Map<String, dynamic>? ?? {};
    return FooterData(
      siteName: json['site_name']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString(),
      tagline: json['tagline']?.toString() ?? '',
      whatsappUrl: social['whatsapp_url']?.toString(),
      instagramUrl: social['instagram_url']?.toString(),
      facebookUrl: social['facebook_url']?.toString(),
      tiktokUrl: social['tiktok_url']?.toString(),
      newsletterTitle: newsletter['title']?.toString() ?? 'النشرة البريدية',
      newsletterIntro: newsletter['intro']?.toString() ?? '',
      newsletterPlaceholder:
          newsletter['placeholder']?.toString() ?? 'أدخل بريدك الإلكتروني',
      copyrightYear: json['copyright_year']?.toString() ?? '2026',
    );
  }
}

// ─── App Labels (/api/labels) ─────────────────────────────────────
class AppLabels {
  final List<String> countries;
  final List<String> durations;

  AppLabels({required this.countries, required this.durations});

  factory AppLabels.fromJson(Map<String, dynamic> json) {
    List<String> parse(dynamic v) {
      if (v == null) return [];
      if (v is List)
        return v
            .map((e) =>
                e['name']?.toString() ?? e['label']?.toString() ?? e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      return [];
    }

    return AppLabels(
      countries: parse(json['countries'] ?? json['country']),
      durations: parse(json['category'] ?? json['duration']),
    );
  }
}
