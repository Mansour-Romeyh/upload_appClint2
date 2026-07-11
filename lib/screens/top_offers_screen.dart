import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/coupon.dart';
import '../widgets/coupon_card.dart';
import '../utils/theme.dart';
import '../services/remote_config_service.dart';

class TopOffersScreen extends StatefulWidget {
  final List<Coupon> coupons;

  const TopOffersScreen({super.key, required this.coupons});

  @override
  State<TopOffersScreen> createState() => _TopOffersScreenState();
}

class _TopOffersScreenState extends State<TopOffersScreen> {
  late String _searchQuery;
  late TextEditingController _searchController;
  List<String> _favoriteCouponIds = [];
  int _visibleCount = 10;
  List<Coupon> _featuredCoupons = [];

  @override
  void initState() {
    super.initState();
    _searchQuery = '';
    _searchController = TextEditingController(text: _searchQuery);
    _loadFavorites();
    // تصفية الكوبونات لتشمل الكوبونات ذات الخصم المئوي أو المميزة فقط
    _featuredCoupons = widget.coupons.where((c) {
      return c.discountPercent > 0 ||
          ['مميز', 'حصري', 'عرض خاص', 'جديد'].contains(c.badge);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _favoriteCouponIds = prefs.getStringList('favorite_coupons') ?? [];
      });
    } catch (e) {
      setState(() {
        _favoriteCouponIds = [];
      });
    }
  }

  Future<void> _toggleFavorite(String couponId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        if (_favoriteCouponIds.contains(couponId)) {
          _favoriteCouponIds.remove(couponId);
        } else {
          _favoriteCouponIds.add(couponId);
        }
      });
      await prefs.setStringList('favorite_coupons', _favoriteCouponIds);
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _featuredCoupons.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.title.toLowerCase().contains(q) ||
          c.storeName.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q);
    }).toList();

    final visible = filtered.take(_visibleCount).toList();
    final hasMore = _visibleCount < filtered.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            floating: true,
            pinned: true,
            elevation: 0,
            titleSpacing: 8,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFD84315),
                    AppTheme.primary,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Right Side in RTL: Back Button + Logo
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/images/Logo_w.png',
                      height: 32,
                      errorBuilder: (_, __, ___) => Text(
                        'COUPONEY',
                        style: AppTheme.tajawal(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                // Left Side in RTL: Country + Search
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '🇪🇬', // Default Egypt Flag as requested previously
                            style: AppTheme.tajawal(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white, size: 26),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {}, // Search is already available below in the TextField
                    ),
                  ],
                ),
              ],
            ),
            centerTitle: false,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
                  ),
                  child: Text(
                    'أفضل العروض',
                    style: AppTheme.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF555555),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_offer_outlined,
                        size: 60, color: Color(0xFFB0B0B0)),
                    const SizedBox(height: 12),
                    Text('لا توجد عروض مطابقة حالياً',
                        style: AppTheme.tajawal(
                            color: const Color(0xFFB0B0B0), fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final c = visible[i];
                    return _buildGridCouponCard(c);
                  },
                  childCount: visible.length,
                ),
              ),
            ),
          if (hasMore)
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => setState(() => _visibleCount += 10),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'عرض المزيد',
                    textAlign: TextAlign.center,
                    style: AppTheme.tajawal(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridCouponCard(Coupon coupon) {
    return GestureDetector(
      onTap: () async {
        // 1. نسخ الكوبون إذا وجد
        if (coupon.code.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: coupon.code));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم نسخ الكود بنجاح',
                style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ));
        } else {
          // إذا لم يكن هناك كود، نعرض تفاصيل العرض كبديل
          _showCouponDialog(coupon);
        }

        // 2. فتح رابط المتجر
        if (!RemoteConfigService.isReviewMode && coupon.storeUrl.isNotEmpty && mounted) {
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) {
            try {
              await launchUrl(Uri.parse(coupon.storeUrl), mode: LaunchMode.externalApplication);
            } catch (_) {}
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            // صورة المتجر
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  child: coupon.storeLogo.isNotEmpty
                      ? Image.network(
                          coupon.storeLogo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.store, color: Colors.grey, size: 40),
                        )
                      : const Icon(Icons.store, color: Colors.grey, size: 40),
                ),
              ),
            ),
            // بيانات الكوبون
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      coupon.storeName,
                      style: AppTheme.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        coupon.discountRaw.isNotEmpty ? coupon.discountRaw : 'عرض خاص',
                        style: AppTheme.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCouponDialog(Coupon coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(coupon.storeName, textAlign: TextAlign.center, style: AppTheme.tajawal(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(coupon.title, textAlign: TextAlign.center, style: AppTheme.tajawal(fontSize: 14)),
            const SizedBox(height: 16),
            if (coupon.code.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(coupon.code, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: AppTheme.tajawal(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
