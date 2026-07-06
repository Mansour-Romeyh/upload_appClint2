import 'package:discounts_app/models/coupon.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_models.dart';
import '../widgets/coupon_card.dart';
import '../widgets/app_drawer.dart';
import '../utils/theme.dart';
import 'top_offers_screen.dart';

class AllCouponsScreen extends StatefulWidget {
  final List<Coupon> coupons;
  final String initialSearchQuery;

  const AllCouponsScreen({super.key, required this.coupons, this.initialSearchQuery = ''});

  @override
  State<AllCouponsScreen> createState() => _AllCouponsScreenState();
}

class _AllCouponsScreenState extends State<AllCouponsScreen> {
  late String _searchQuery;
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<String> _favoriteCouponIds = [];
  int _visibleCount = 10;
  String _selectedCountry = 'جميع الدول';

  final List<String> _countries = [
    'جميع الدول',
    'مصر',
    'السعودية',
    'الإمارات',
    'الكويت',
    'قطر',
    'دولي',
  ];

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearchQuery;
    _searchController = TextEditingController(text: _searchQuery);
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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

  String _getFlagEmoji(String c) {
    if (c == 'مصر') return '🇪🇬';
    if (c == 'السعودية') return '🇸🇦';
    if (c == 'الإمارات') return '🇦🇪';
    if (c == 'الكويت') return '🇰🇼';
    if (c == 'قطر') return '🇶🇦';
    if (c == 'عمان') return '🇴🇲';
    if (c == 'البحرين') return '🇧🇭';
    if (c == 'دولي') return '🌍';
    if (c == 'جميع الدول') return '🌐';
    return '🌐';
  }

  void _openCountryPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.public, color: Colors.orange, size: 18),
              Text('  اختر الدولة',
                  style: AppTheme.tajawal(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.grey),
              ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: ListView.builder(
                itemCount: _countries.length,
                itemBuilder: (context, index) {
                  final c = _countries[index];
                  final isSelected = _selectedCountry == c;

                  return GestureDetector(
                    onTap: () => Navigator.pop(context, c),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withOpacity(0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : const Color(0xFFE0E0E0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${_getFlagEmoji(c)}   $c',
                            style: AppTheme.tajawal(
                              fontSize: 14,
                              color:
                                  isSelected ? AppTheme.primary : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check,
                                color: AppTheme.primary, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedCountry = selected;
        _visibleCount = 10;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.coupons.where((c) {
      final matchSearch = _searchQuery.isEmpty ||
          c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.storeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.code.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchCountry = _selectedCountry == 'جميع الدول'
          ? true
          : c.country.toLowerCase().contains(_selectedCountry.toLowerCase());

      return matchSearch && matchCountry;
    }).toList();

    final visible = filtered.take(_visibleCount).toList();
    final hasMore = _visibleCount < filtered.length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      drawer: AppDrawer(
        site: null,
        hero: null,
        selectedIndex: -1,
        onNavigateToCoupons: () {
          // We are already in AllCouponsScreen, do nothing (drawer is already popped by AppDrawer)
        },
        onNavigateToTopOffers: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TopOffersScreen(coupons: widget.coupons),
            ),
          );
        },
        onSelectTab: (index) {
          Navigator.pop(context, index);
        },
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
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
        titleSpacing: 8,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _openCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _getFlagEmoji(_selectedCountry),
                          style: AppTheme.tajawal(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 26),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _searchFocusNode.requestFocus();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                cursorColor: AppTheme.primary,
                textDirection: TextDirection.rtl,
                style: AppTheme.tajawal(color: Colors.black, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'ابحث عن كوبونات او متاجر...',
                  hintStyle: AppTheme.tajawal(
                      color: Colors.grey.shade400, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.grey, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
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
                    const Icon(Icons.search_off,
                        size: 60, color: Color(0xFFB0B0B0)),
                    const SizedBox(height: 12),
                    Text('لا توجد نتائج',
                        style: AppTheme.tajawal(
                            color: Color(0xFFB0B0B0), fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i == visible.length) {
                      return GestureDetector(
                        onTap: () => setState(() => _visibleCount += 10),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8, bottom: 24),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(30),
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
                      );
                    }
                    final c = visible[i];
                    return ApiCouponCard(
                      key: ValueKey(c.id),
                      coupon: c,
                      index: i,
                      totalItems: visible.length,
                      isFavorite: _favoriteCouponIds.contains(c.id),
                      onFavoriteToggle: () => _toggleFavorite(c.id),
                    );
                  },
                  childCount: visible.length + (hasMore ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
