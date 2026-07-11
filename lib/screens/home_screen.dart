import 'dart:async';
import 'package:discounts_app/screens/in_app_webview_screen.dart';
import 'package:discounts_app/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../models/coupon.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../widgets/coupon_card.dart';
import '../widgets/store_item.dart';
import '../widgets/filter_sheet.dart';
import '../screens/all_coupons_screen.dart';
import '../screens/top_offers_screen.dart';
import 'savings_calculator_screen.dart';
import 'submit_coupon_screen.dart';
import 'spin_wheel_screen.dart';
import '../services/notification_service.dart';
import '../services/remote_config_service.dart';
import '../widgets/review_store_view.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ─── Data ──────────────────────────────────────────────────────────
  List<Store> _stores = [];
  List<Store> _offerStores = [];
  List<Coupon> _coupons = [];
  SiteInfo? _site;
  HeroData? _hero;
  AppLabels? _labels; // من /api/labels
  List<String> _filterStores = []; // من /api/stores/for-filters
  bool _loading = true;
  String? _error;

  // ─── UI State ──────────────────────────────────────────────────────
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  FilterOptions _filterOptions = FilterOptions();
  int _visibleCount = 8;
  int _sliderIndex = 0;
  bool _emailSubmitting = false;
  bool _emailSent = false;
  String? _emailError;

  // ─── Social (fallback static if API doesn't return) ──────────────
  static const String _defaultTiktokUrl =
      'https://www.tiktok.com/@3rood_saudia?_r=1&_t=ZS-94wTAUGvh7o';
  static const String _defaultInstagramUrl =
      'https://www.instagram.com/couponat_5sm?igsh=MWp6ZHJ2NnczZmJhZA==';
  static const String _defaultFacebookUrl =
      'https://www.facebook.com/share/1CLo9ZBNup/';

  String get _tiktokUrl => _hero?.tiktokUrl?.isNotEmpty == true
      ? _hero!.tiktokUrl!
      : _defaultTiktokUrl;
  String get _instagramUrl => _hero?.instagramUrl?.isNotEmpty == true
      ? _hero!.instagramUrl!
      : _defaultInstagramUrl;
  String get _facebookUrl => _hero?.facebookUrl?.isNotEmpty == true
      ? _hero!.facebookUrl!
      : _defaultFacebookUrl;

  // ─── Banner ────────────────────────────────────────────────────────
  static const List<String> _staticBannerMessages = [
    'وفر أكثر تسوق بذكاء!',
    'لا تفوت أفضل العروض اليومية!',
    'خصومات حصرية تنتظرك الآن!',
    'كل يوم توفير جديد معنا!',
  ];
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  // بيستخدم messages من API لو متاحة، وإلا الـ static
  List<String> get _bannerMessages =>
      (_hero?.announcementMessages.isNotEmpty == true)
          ? _hero!.announcementMessages
          : _staticBannerMessages;

  // ─── Slider ────────────────────────────────────────────────────────
  static const int _loopMultiplier = 1000;
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  // ─── Stores auto-scroll ────────────────────────────────────────────
  final ScrollController _storesScrollController = ScrollController();
  Timer? _storesScrollTimer;
  bool _isUserInteracting = false;

  // ─── Main scroll + Bottom Nav ──────────────────────────────────────
  final ScrollController _mainScrollController = ScrollController();
  final GlobalKey _offersKey = GlobalKey();
  final GlobalKey _storesKey = GlobalKey();
  final GlobalKey _couponsKey = GlobalKey();
  int _selectedNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const String _whatsappChannel =
      'https://whatsapp.com/channel/0029VaoUhiYATRShF1gyEc2p';

  List<String> _favoriteCouponIds = [];
  bool _dailyReminderEnabled = true;

  Future<void> _loadNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? true;
      });
    } catch (_) {}
  }

  Future<void> _toggleDailyReminder(bool value) async {
    setState(() {
      _dailyReminderEnabled = value;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('daily_reminder_enabled', value);
      if (value) {
        await NotificationService.scheduleDailyReminder();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم تفعيل التذكير اليومي بنجاح 🔔', style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
          ));
        }
      } else {
        await NotificationService.cancelDailyReminder();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم إيقاف التذكير اليومي 🔕', style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.grey,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (_) {}
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

  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
  }

  void _onNavTap(int index) {
    if (_selectedNavIndex == index && index == 0) {
      _mainScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
    setState(() => _selectedNavIndex = index);
    if (index == 3) {
      _loadFavorites();
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadData();
    _loadFavorites();
    _loadNotificationPreference();
    _bannerTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        setState(
            () => _bannerIndex = (_bannerIndex + 1) % _bannerMessages.length);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startStoresScroll());
  }

  void _startStoresScroll() {
    _storesScrollTimer?.cancel();
    _storesScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_storesScrollController.hasClients || _isUserInteracting) return;
      final max = _storesScrollController.position.maxScrollExtent;
      final current = _storesScrollController.offset;
      if (max <= 0) return;

      final viewport = _storesScrollController.position.viewportDimension;
      double target = current + viewport;
      if (current == 0) {
        _storesScrollController.jumpTo(max * 0.33);
        target = (max * 0.33) + viewport;
      } else if (target >= max * 0.66) {
        final offsetInMiddle = current - (max * 0.33);
        _storesScrollController.jumpTo(offsetInMiddle);
        target = offsetInMiddle + viewport;
      }

      _storesScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  // ─── Load All Data ─────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // جيب كل البيانات بالتوازي
      final results = await Future.wait([
        ApiService.fetchHome(), // 0
        ApiService.fetchLabels()
            .catchError((_) => AppLabels(countries: [], durations: [])), // 1
        ApiService.fetchStoresForFilters().catchError((_) => <String>[]), // 2
      ]);

      final bundle = results[0] as HomeBundle;

      print('=== HERO ===');
      print('title: ${bundle.hero?.title}');
      print('description: ${bundle.hero?.description}');
      print('bgImage: ${bundle.hero?.bgImageUrl}');
      print('sideImage: ${bundle.hero?.imageUrl}');
      print('hero is null: ${bundle.hero == null}');
      print('=== SITE ===');
      print('name: ${bundle.site?.name}');
      final labels = results[1] as AppLabels;
      final filterStores = results[2] as List<String>;

      // لو الـ bundle ما جبتش كوبونات كافية، جيب من الـ endpoints المنفصلة
      List<Coupon> coupons = bundle.coupons;
      if (coupons.isEmpty) {
        coupons = await ApiService.fetchAllCoupons();
      }

      setState(() {
        _stores = bundle.stores;
        _offerStores = bundle.offers.isNotEmpty ? bundle.offers : bundle.stores;
        _coupons = coupons;
        _site = bundle.site;
        _hero = bundle.hero;
        _labels = labels;
        _filterStores = filterStores;
        _loading = false;
      });
    } catch (e) {
      // Fallback: جيب كل حاجة لوحدها
      try {
        final results = await Future.wait([
          ApiService.fetchStores().catchError((_) => <Store>[]),
          ApiService.fetchAllCoupons().catchError((_) => <Coupon>[]),
          ApiService.fetchOffers().catchError((_) => <Store>[]),
          ApiService.fetchLabels()
              .catchError((_) => AppLabels(countries: [], durations: [])),
          ApiService.fetchStoresForFilters().catchError((_) => <String>[]),
          ApiService.fetchHero()
              .catchError((_) => HeroData(title: '', description: '')),
          ApiService.fetchSite()
              .catchError((_) => SiteInfo(name: '', tagline: '')),
        ]);
        setState(() {
          _stores = results[0] as List<Store>;
          _coupons = results[1] as List<Coupon>;
          final offers = results[2] as List<Store>;
          _offerStores = offers.isNotEmpty ? offers : _stores;
          _labels = results[3] as AppLabels;
          _filterStores = results[4] as List<String>;
          final heroFallback = results[5] as HeroData;
          final siteFallback = results[6] as SiteInfo;
          _hero = heroFallback.title.isNotEmpty ? heroFallback : null;
          _site = siteFallback.name.isNotEmpty ? siteFallback : null;
          _loading = false;
        });
      } catch (e2) {
        setState(() {
          _error =
              'تعذّر الاتصال بالسيرفر.\nتحقق من اتصال الإنترنت وحاول مجدداً.';
          _loading = false;
        });
      }
    }
    if (_offerStores.isNotEmpty) _initSlider();
    // أعد تشغيل الـ stores scroll بعد تحميل البيانات
    WidgetsBinding.instance.addPostFrameCallback((_) => _startStoresScroll());
  }

  void _initSlider() {
    final initialPage = _offerStores.length * (_loopMultiplier ~/ 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) _pageController.jumpToPage(initialPage);
      setState(() => _sliderIndex = initialPage % _offerStores.length);
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_pageController.page ?? 0).round() + 1;
      _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOutQuad);
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _autoScrollTimer?.cancel();
    _storesScrollTimer?.cancel();
    _storesScrollController.dispose();
    _mainScrollController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final cats = _coupons
        .map((c) => c.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    return ['جميع الفئات', ...cats];
  }

  List<Coupon> get filteredCoupons => _coupons.where((c) {
        final matchSearch = _searchQuery.isEmpty ||
            c.title.contains(_searchQuery) ||
            c.storeName.contains(_searchQuery) ||
            c.code.contains(_searchQuery);

        final matchCompany = _filterOptions.company == 'جميع الشركات' ||
            c.storeName == _filterOptions.company;

        // ✅ التعديل هنا: التأكد من تحويل فئة الكوبون الحالية قبل المقارنة
        final matchCategory = _filterOptions.category == 'جميع الفئات' ||
            c.category.trim() == _filterOptions.category.trim();
        final matchCountry = _filterOptions.country == 'جميع الدول'
            ? true
            : c.country
                .toLowerCase()
                .contains(_filterOptions.country.toLowerCase());

        return matchSearch && matchCompany && matchCategory && matchCountry;
      }).toList();

  List<Coupon> get visibleCoupons =>
      filteredCoupons.take(_visibleCount).toList();
  bool get hasMore => _visibleCount < filteredCoupons.length;

  void _openFilter() async {
    final companies = _filterStores.isNotEmpty
        ? ['جميع الشركات', ..._filterStores]
        : ['جميع الشركات', ..._stores.map((s) => s.name)];
    final countries = _labels?.countries.isNotEmpty == true
        ? ['جميع الدول', ..._labels!.countries]
        : null;
    final durations = _labels?.durations.isNotEmpty == true
        ? ['جميع المدد', ..._labels!.durations]
        : null;
    // ✅ الفئات من الكوبونات الحقيقية
    final existingCats = _coupons
        .map((c) => c.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    final categoriesList = [
      'جميع الفئات',
      ...existingCats.toSet().toList()..sort()
    ];
    final result = await showModalBottomSheet<FilterOptions>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterSheet(
        current: _filterOptions,
        companies: companies,
        countries: countries,
        categories: categoriesList, // إرسال القائمة المعربة هنا
      ),
    );
    if (result != null) {
      setState(() {
        _filterOptions = result;
        _visibleCount = 8;
      });
    }
  }

  // ─── Country Quick Filter ──────────────────────────────────────────
  void _openCountryPicker() async {
    final countries = _labels?.countries.isNotEmpty == true
        ? ['جميع الدول', ..._labels!.countries]
        : [
            'جميع الدول',
            'مصر',
            'السعودية',
            'الإمارات',
            'الكويت',
            'قطر',
            'دولي',
          ];

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
              Icon(Icons.public, color: Colors.orange, size: 18),
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
                itemCount: countries.length,
                itemBuilder: (context, index) {
                  final c = countries[index];
                  final isSelected = _filterOptions.country == c;

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
        _filterOptions = _filterOptions.copyWith(country: selected);
        _visibleCount = 8;
      });
    }
  }

  // ─── Newsletter ────────────────────────────────────────────────────
  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => _emailError = 'الرجاء إدخال بريد إلكتروني صحيح');
      return;
    }
    setState(() {
      _emailSubmitting = true;
      _emailError = null;
    });
    try {
      await ApiService.subscribeNewsletter(email);
      setState(() {
        _emailSubmitting = false;
        _emailSent = true;
      });
      _emailController.clear();
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '');
      if (err == 'backend_missing_route') {
        setState(() {
          _emailSubmitting = false;
          _emailError = 'خدمة الاشتراك غير متاحة حالياً، يرجى المحاولة لاحقاً';
        });
      } else {
        setState(() {
          _emailSubmitting = false;
          _emailError = err;
        });
      }
    }
  }

  // void _openInApp(String url, {String title = ''}) {
  //   Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => InAppWebViewScreen(url: url, title: title),
  //       ));
  // }

  Future<void> _launch(String url) async {
    if (RemoteConfigService.isReviewMode) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم نسخ الرابط بنجاح! 🔗', style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _buildError();
    return Scaffold(
      key: _scaffoldKey, // ✅ للـ Drawer
      backgroundColor: AppTheme.background,
      // // ✅ Sidebar الرئيسي
      drawer: AppDrawer(
        site: _site,
        hero: _hero,
        selectedIndex: _selectedNavIndex == 3 ? 2 : _selectedNavIndex,
        onNavigateToCoupons: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AllCouponsScreen(coupons: _coupons),
            ),
          ).then((result) {
            _loadFavorites();
            if (result is int) {
              setState(() => _selectedNavIndex = result == 2 ? 3 : result);
            }
          });
        },
        onNavigateToTopOffers: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TopOffersScreen(coupons: _coupons),
            ),
          );
        },
        onSelectTab: (index) {
          setState(() {
            _selectedNavIndex = index == 2 ? 3 : index;
          });
          if (index == 2) {
            _loadFavorites();
          }
        },
      ),

      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 55), // Pushes the FAB down into the notch slightly
        child: SizedBox(
          width: 65,
          height: 65,
          child: FloatingActionButton(
            onPressed: () {
              if (RemoteConfigService.isReviewMode) {
                setState(() {
                  _selectedNavIndex = 2; // Switch to Tools tab
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TopOffersScreen(coupons: _coupons),
                  ),
                );
              }
            },
            backgroundColor: (RemoteConfigService.isReviewMode && _selectedNavIndex == 2)
                ? const Color(0xFFFF485A)
                : AppTheme.primary,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            child: Icon(
              RemoteConfigService.isReviewMode ? Icons.widgets_rounded : Icons.local_offer_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadData,
        child: Column(
          children: [
            _buildOfflineBanner(),
            Expanded(
              child: IndexedStack(
                index: _selectedNavIndex,
                children: [
                  _buildHomeTab(),
                  _buildStoresTab(),
                  _buildToolsTab(),
                  _buildFavoritesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return const SizedBox();
  }

  Widget _buildLoading() => Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 16),
          Text('جاري تحميل العروض...',
              style: AppTheme.tajawal(color: AppTheme.textSecondaryinWhite)),
        ])),
      );

  Widget _buildError() => Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off,
                        size: 64, color: AppTheme.textSecondaryinWhite),
                    const SizedBox(height: 16),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: AppTheme.tajawal(
                            color: AppTheme.textSecondaryinWhite, height: 1.6)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14)),
                      child: Text('إعادة المحاولة',
                          style: AppTheme.tajawal(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ))),
      );

  Widget _buildAppBar() => SliverAppBar(
        automaticallyImplyLeading: false,
        floating: true,
        pinned: true,
        elevation: 0,
        titleSpacing: 8, // تقليل المسافة لتكون القائمة في البداية تماماً
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD84315), // Darker orange for gradient depth
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
            // Right Side in RTL: Menu + Logo
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
                _site?.logoWhiteUrl != null && _site!.logoWhiteUrl!.isNotEmpty
                    ? Image.network(
                        _site!.logoWhiteUrl!,
                        height: 32,
                        errorBuilder: (_, __, ___) => Image.asset(
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
                      )
                    : Image.asset(
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
            // Left Side in RTL (Last child): Search + Country
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
                          _getFlagEmoji(_filterOptions.country),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllCouponsScreen(coupons: _coupons),
                      ),
                    ).then((result) {
                      _loadFavorites();
                      if (result is int) {
                        setState(() => _selectedNavIndex = result == 2 ? 3 : result);
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: const Color(0xFF111111),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.3), end: Offset.zero)
                      .animate(anim),
                  child: child)),
          child: Text(_bannerMessages[_bannerIndex],
              key: ValueKey(_bannerIndex),
              textAlign: TextAlign.center,
              style: AppTheme.tajawal(color: Colors.white70, fontSize: 12)),
        ),
      );

  Widget _buildHeroSection() {
    final title = (_hero?.title != null && _hero!.title.isNotEmpty)
        ? _hero!.title
        : 'وفر أكثر مع كوبوني';
    final desc = (_hero?.description != null && _hero!.description.isNotEmpty)
        ? _hero!.description
        : 'استمتع بخصومات تصل إلى 50% على مجموعة واسعة من المنتجات من متاجرك المفضلة.';
    final heroImage = _hero?.imageUrl;
    final bgImage = _hero?.bgImageUrl;

    // ── Background: API bg image أو asset fallback ──
    Widget bgWidget;
    if (bgImage != null && bgImage.isNotEmpty) {
      bgWidget = Image.network(
        bgImage,
        width: double.infinity,
        height: 420,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/back.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF1A1A1A)),
        ),
      );
    } else {
      bgWidget = Image.asset(
        'assets/images/back.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)),
      );
    }

    return Stack(children: [
      SizedBox(width: double.infinity, height: 320, child: bgWidget),
      Container(height: 320, color: Colors.black.withOpacity(0.5)),
      SizedBox(
          height: 320,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Expanded(
            // child: Center(
            //     child: _loading
            //         ? const CircularProgressIndicator(
            //             color: AppTheme.primary)
            //         : heroImage != null && heroImage.isNotEmpty
            //             ? Image.network(heroImage,
            //                 height: 200,
            //                 errorBuilder: (_, __, ___) => Image.asset(
            //                     'assets/images/hero.png',
            //                     height: 200,
            //                     errorBuilder: (_, __, ___) =>
            //                         const SizedBox()))
            //             : Image.asset('assets/images/hero.png',
            //                 height: 200,
            //                 errorBuilder: (_, __, ___) =>
            //                     const SizedBox()))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(title,
                        style: AppTheme.tajawal(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Text(
                      desc,
                      style: AppTheme.tajawal(
                          color: Colors.white60, fontSize: 12, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    searchMethod(),
                  ]),
            ),
          ])),
    ]);
  }

  TextField searchMethod() {
    return TextField(
      cursorColor: AppTheme.primary,
      controller: _searchController,
      textDirection: TextDirection.rtl,
      style: AppTheme.tajawal(color: Colors.black),
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: const Color.fromARGB(79, 156, 156, 156))),
        hintText: 'ابحث عن كوبونات او متاجر...',
        hintStyle: AppTheme.tajawal(color: Colors.grey, fontSize: 13),
        suffixIcon: GestureDetector(
          onTap: () {
            final q = _searchController.text.trim();
            if (q.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllCouponsScreen(
                    coupons: _coupons,
                    initialSearchQuery: q,
                  ),
                ),
              ).then((result) {
                _loadFavorites();
                if (result is int) {
                  setState(() => _selectedNavIndex = result == 2 ? 3 : result);
                }
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.search, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text('بحث',
                  style: AppTheme.tajawal(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ]),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onSubmitted: (v) {
        if (v.trim().isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AllCouponsScreen(
                coupons: _coupons,
                initialSearchQuery: v.trim(),
              ),
            ),
          ).then((result) {
            _loadFavorites();
            if (result is int) {
              setState(() => _selectedNavIndex = result == 2 ? 3 : result);
            }
          });
        }
      },
    );
  }

  Widget _buildFeaturedSection([Key? sectionKey]) {
    final totalPages = _offerStores.length * _loopMultiplier;
    return Column(key: sectionKey, children: [
      _buildSectionHeader('🔥  عروض مميزة', s: 'أفضل العروض والخصومات الحصرية'),
      SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalPages,
            onPageChanged: (i) =>
                setState(() => _sliderIndex = i % _offerStores.length),
            itemBuilder: (context, i) {
              final store = _offerStores[i % _offerStores.length];
              return GestureDetector(
                onTap: () async {
                  if (store.url.isNotEmpty)
                    _launch(store.url);
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildStoreImage(store)),
                ),
              );
            },
          )),
      const SizedBox(height: 10),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              _offerStores.length.clamp(0, 10),
              (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _sliderIndex == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: _sliderIndex == i
                          ? AppTheme.primary
                          : const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(4))))),
      const SizedBox(height: 8),
    ]);
  }

  Widget _buildStoreImage(Store store) {
    final logo = store.logoUrl;
    Widget fallback() => Center(
        child: Text(store.name,
            style: AppTheme.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary)));

    if (logo.isEmpty) return fallback();

    final isSvg = logo.endsWith('.svg');
    final isHttp = logo.startsWith('http');
    final isAsset = logo.startsWith('assets/');

    if (isSvg) {
      if (isAsset) {
        return Padding(
            padding: const EdgeInsets.all(24),
            child: SvgPicture.asset(logo,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => fallback()));
      }
      if (isHttp) {
        return Padding(
            padding: const EdgeInsets.all(24),
            child: SvgPicture.network(logo,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => fallback()));
      }
      return fallback();
    }

    if (isAsset) {
      return Image.asset(logo,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => fallback());
    }

    if (isHttp) {
      return Image.network(logo,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (_, child, p) => p == null
              ? child
              : Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      value: p.expectedTotalBytes != null
                          ? p.cumulativeBytesLoaded / p.expectedTotalBytes!
                          : null)),
          errorBuilder: (_, __, ___) => fallback());
    }

    return fallback();
  }

  Widget _buildSectionHeader(String title, {String s = '', VoidCallback? onAllTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTheme.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF444444),
                ),
              ),
              if (onAllTap != null)
                GestureDetector(
                  onTap: onAllTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'الكل',
                        style: AppTheme.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF485A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF485A).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          size: 16,
                          color: Color(0xFFFF485A),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (s.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              s,
              style: AppTheme.tajawal(
                fontSize: 11,
                color: AppTheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoresList() {
    if (_stores.isEmpty) return const SizedBox();
    // loop المتاجر عشان تكون infinite
    final looped = [..._stores, ..._stores, ..._stores];
    return SizedBox(
      height: 120,
      child: ListView.builder(
        controller: _storesScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: looped.length,
        itemBuilder: (context, i) => StoreItem(
          store: looped[i],
          index: i % _stores.length,
          totalItems: _stores.length,
          onTap:  () {
            final url = looped[i].url;
            if (url.isNotEmpty) _launch(url);
          },
        ),
      ),
    );
  }

  Widget _buildCouponsHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🏷️  كوبونات مميزة',
                    style: AppTheme.tajawal(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('أحدث العروض والكوبونات الحصرية',
                    style: AppTheme.tajawal(
                        fontSize: 12, color: AppTheme.primary)),
              ]),
              GestureDetector(
                onTap: _openFilter,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _filterOptions.isDefault
                        ? AppTheme.background
                        : AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _filterOptions.isDefault
                            ? const Color(0xFFCCCCCC)
                            : AppTheme.primary),
                  ),
                  child: Row(children: [
                    Icon(Icons.filter_alt,
                        size: 16,
                        color: _filterOptions.isDefault
                            ? AppTheme.textSecondaryinWhite
                            : Colors.white),
                    const SizedBox(width: 4),
                    Text('فلتر',
                        style: AppTheme.tajawal(
                            fontSize: 13,
                            color: _filterOptions.isDefault
                                ? AppTheme.textSecondaryinWhite
                                : Colors.white,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ]),
            SizedBox(height: 12),
            searchMethod(),
          ],
        ),
      );

  Widget _buildCouponsList() {
    if (filteredCoupons.isEmpty) {
      return Center(
        child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(children: [
              const Icon(Icons.search_off,
                  size: 60, color: AppTheme.textSecondaryinWhite),
              const SizedBox(height: 12),
              Text('لا توجد نتائج',
                  style: AppTheme.tajawal(
                      color: AppTheme.textSecondaryinWhite, fontSize: 16)),
            ])),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: [
        ...visibleCoupons.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          final isFav = _favoriteCouponIds.contains(c.id);
          return ApiCouponCard(
            key: ValueKey(c.id),
            coupon: c,
            index: i,
            totalItems: visibleCoupons.length,
            isFavorite: isFav,
            onFavoriteToggle: () => _toggleFavorite(c.id),
          );
        }),
        if (hasMore) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _visibleCount += 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(30)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_circle_outline,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('إظهار المزيد من الكوبونات',
                    style: AppTheme.tajawal(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ]),
    );
  }

  // ─── Bottom Navigation Bar ─────────────────────────────────────────
  Widget _buildBottomNav() {
    return BottomAppBar(
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _navItem(0, Icons.home_rounded, 'الرئيسية'),
                const SizedBox(width: 12),
                _navItem(1, Icons.storefront_rounded, 'المتاجر'),
              ],
            ),
            Row(
              children: [
                _navItem(3, Icons.star_rounded, 'المفضلة'),
                const SizedBox(width: 12),
                _navItem(4, Icons.more_horiz_rounded, 'المزيد', () {
                  _scaffoldKey.currentState?.openDrawer();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label,
      [VoidCallback? onTap]) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: onTap ?? () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : Colors.grey.shade500,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.tajawal(
                fontSize: 11,
                color: isSelected ? AppTheme.primary : Colors.grey.shade500,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final footerLogo = _hero?.logoWhiteUrl ?? _site?.logoWhiteUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(
        top: 24,
      ),
      color: const Color(0xFF111111),
      child: Column(children: [
        // Logo - من API لو متاح، وإلا الـ local
        footerLogo != null && footerLogo.isNotEmpty
            ? Image.network(footerLogo,
                height: 50,
                errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/Logo_w.png',
                    height: 50,
                    errorBuilder: (_, __, ___) => Text('COUPONEY',
                        style: AppTheme.tajawal(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20))))
            : Image.asset('assets/images/Logo_w.png',
                height: 50,
                errorBuilder: (_, __, ___) => Text('COUPONEY',
                    style: AppTheme.tajawal(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20))),
        const SizedBox(height: 16),
        Text(_site?.tagline ?? 'منصتك لأفضل كوبونات الخصم والعروض الحصرية.',
            style: AppTheme.tajawal(
                color: AppTheme.textSecondaryinBlack, fontSize: 12),
            textAlign: TextAlign.center),
        //       const SizedBox(height: 16),
        //       Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        //         _socialIcon(
        //             const FaIcon(FontAwesomeIcons.whatsapp,
        //                 color: Colors.white60, size: 18),
        //             'https://wa.me/201203994799'),
        //         const SizedBox(width: 16),
        //         _socialIcon(
        //             const FaIcon(FontAwesomeIcons.tiktok,
        //                 color: Colors.white60, size: 18),
        //             _tiktokUrl),
        //         const SizedBox(width: 16),
        //         _socialIcon(
        //             const FaIcon(FontAwesomeIcons.instagram,
        //                 color: Colors.white60, size: 18),
        //             _instagramUrl),
        //         const SizedBox(width: 16),
        //         _socialIcon(
        //             const FaIcon(FontAwesomeIcons.facebookF,
        //                 color: Colors.white60, size: 18),
        //             _facebookUrl),
        //       ]),
        //       const SizedBox(height: 20),
        //       GestureDetector(
        //         onTap: () async {
        //           try {
        //             await launchUrl(
        //               Uri.parse(
        //                   'https://whatsapp.com/channel/0029VaoUhiYATRShF1gyEc2p'),
        //               mode: LaunchMode.externalApplication,
        //             );
        //           } catch (_) {}
        //         },
        //         child: Container(
        //           width: 250,
        //           padding:
        //               const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        //           decoration: BoxDecoration(
        //             color: const Color(0xFF25D366),
        //             borderRadius: BorderRadius.circular(30),
        //           ),
        //           child: Row(
        //             mainAxisAlignment: MainAxisAlignment.center,
        //             children: [
        //               const FaIcon(FontAwesomeIcons.whatsapp,
        //                   color: Colors.white, size: 20),
        //               const SizedBox(width: 10),
        //               Text(
        //                 'تابعنا على قناة الواتساب',
        //                 style: AppTheme.tajawal(
        //                   color: Colors.white,
        //                   fontSize: 15,
        //                   fontWeight: FontWeight.bold,
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //       ),
      ]),
    );
  }

  Widget _buildHomeTab() {
    if (RemoteConfigService.isReviewMode) {
      return const ReviewStoreView();
    }
    return CustomScrollView(
      controller: _mainScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        _buildAppBar(),
        if (_loading)
          SliverToBoxAdapter(
            child: _buildHomeShimmer(),
          )
        else ...[
          SliverToBoxAdapter(child: _buildHorizontalStoresCircleList()),
          SliverToBoxAdapter(child: _buildFeaturedSection()),
          SliverToBoxAdapter(child: _buildTopCouponsSection()),
          SliverToBoxAdapter(child: _buildTopStoresSection()),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ],
    );
  }

  Widget _buildToolsHubSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🛠️  أدوات التوفير الذكية',
            style: AppTheme.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Savings Calculator Card
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavingsCalculatorScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.calculate_outlined, color: Colors.white, size: 20),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'حاسبة التوفير',
                          style: AppTheme.tajawal(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'احسب خصم الكوبون وسجل أرباحك',
                          style: AppTheme.tajawal(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Submit Coupon Card
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubmitCouponScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF3D00), Color(0xFFFF6D00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'اقترح كوبون',
                          style: AppTheme.tajawal(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'شارك كود خصم مع مجتمع كوبوني',
                          style: AppTheme.tajawal(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Spin Wheel Banner inside Home Tab Tools section
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SpinWheelScreen(coupons: _coupons),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF311B92), Color(0xFF673AB7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.toys_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عجلة التوفير اليومية 🎁',
                          style: AppTheme.tajawal(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'أدر العجلة واربح خصومات ونصائح ذكية',
                          style: AppTheme.tajawal(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHomeShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      direction: ShimmerDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Shimmer for Circular Stores
          Container(
            height: 110,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 65, height: 65, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(height: 10),
                    Container(width: 50, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5))),
                  ],
                ),
              ),
            ),
          ),
          // 2. Shimmer for Top Coupons
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 140, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5))),
                    Container(width: 40, height: 15, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5))),
                  ],
                ),
              ),
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 3,
                  itemBuilder: (_, __) => Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
          // 3. Shimmer for Top Stores
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Container(width: 120, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5))),
              ),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 4,
                  itemBuilder: (_, __) => Container(
                    width: 110,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStoresCircleList() {
    if (_stores.isEmpty) return const SizedBox();
    final looped = [..._stores, ..._stores, ..._stores];
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollStartNotification) {
            _isUserInteracting = true;
          } else if (notification is ScrollEndNotification) {
            _isUserInteracting = false;
          }
          return false;
        },
        child: ListView.builder(
          controller: _storesScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: looped.length,
          itemBuilder: (context, i) => StoreItem(
            store: looped[i],
            index: i % _stores.length,
            totalItems: _stores.length,
            onTap: () {
              final url = looped[i].url;
              if (url.isNotEmpty) _launch(url);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopCouponsSection() {
    if (_coupons.isEmpty) return const SizedBox();
    final topCoupons = _coupons.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('أفضل الكوبونات', onAllTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AllCouponsScreen(coupons: _coupons),
            ),
          ).then((result) {
            _loadFavorites();
            if (result is int) {
              setState(() => _selectedNavIndex = result == 2 ? 3 : result);
            }
          });
        }),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: topCoupons.length,
            itemBuilder: (context, i) {
              final coupon = topCoupons[i];
              return Container(
                width: 155,
                margin: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Center(
                        child: coupon.storeLogo.isNotEmpty
                            ? Image.network(
                                coupon.storeLogo,
                                height: 48,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Text(
                                  coupon.storeName,
                                  style: AppTheme.tajawal(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Text(
                                coupon.storeName,
                                style: AppTheme.tajawal(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: const Color(0xFF333333)),
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: coupon.code));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('تم نسخ الكود: ${coupon.code}',
                                style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
                            backgroundColor: const Color(0xFFFF485A),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ));
                        }
                        if (coupon.storeUrl.isNotEmpty) {
                          await Future.delayed(const Duration(milliseconds: 600));
                          _launch(coupon.storeUrl);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF485A), // Vibrant red/pink matching screenshot button
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'نسخ الكود',
                          style: AppTheme.tajawal(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopStoresSection() {
    if (_stores.isEmpty) return const SizedBox();
    final topStores = _stores.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('أشهر المتاجر', onAllTap: () => _onNavTap(1)),
        SizedBox(
          height: 175,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: topStores.length,
            itemBuilder: (context, i) {
              final store = topStores[i];
              final discount = _getStoreDiscountText(store.name);
              return GestureDetector(
                onTap: () {
                  if (store.url.isNotEmpty) _launch(store.url);
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: store.logoUrl.isNotEmpty
                              ? (store.logoUrl.startsWith('http')
                                  ? Image.network(
                                      store.logoUrl,
                                      height: 44,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Text(
                                        store.name,
                                        style: AppTheme.tajawal(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: const Color(0xFF333333)),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : (store.logoUrl.startsWith('assets/')
                                      ? Image.asset(
                                          store.logoUrl,
                                          height: 44,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Text(
                                            store.name,
                                            style: AppTheme.tajawal(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: const Color(0xFF333333)),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      : Text(
                                          store.name,
                                          style: AppTheme.tajawal(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: const Color(0xFF333333)),
                                          textAlign: TextAlign.center,
                                        )))
                              : Text(
                                  store.name,
                                  style: AppTheme.tajawal(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: const Color(0xFF333333)),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        discount,
                        style: AppTheme.tajawal(
                          color: const Color(0xFFFF485A), // Pinkish-red discount label
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store.name,
                        style: AppTheme.tajawal(
                          color: const Color(0xFF888888),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getStoreDiscountText(String storeName) {
    final name = storeName.toLowerCase().trim();
    if (name.contains('noon') || name.contains('نون')) return 'خصم يصل إلى 80%';
    if (name.contains('iherb') || name.contains('ايهيرب')) return 'خصم يصل إلى 50%';
    if (name.contains('temu') || name.contains('تيمو')) return 'خصم 30% للمشتركين';
    if (name.contains('riva') || name.contains('ريفا')) return 'خصم حصري 7%';
    if (name.contains('aliexpress') || name.contains('علي اكسبرس')) return 'تخفيضات 50%';
    if (name.contains('shein') || name.contains('شي ان')) return 'خصومات حتى 90%';
    if (name.contains('farfetch') || name.contains('فارفيتش')) return 'خصم يصل إلى 60%';
    if (name.contains('max') || name.contains('ماكس')) return 'كوبون حصري 10%';
    
    final coupon = _coupons.firstWhere((c) => c.storeName.toLowerCase().contains(name), 
      orElse: () => Coupon(id: '', storeId: '', storeName: '', storeLogo: '', storeImage: '', title: '', code: '', expiryText: '', badge: '', storeUrl: '', discountPercent: 0, category: '', discountRaw: 'خصم حصرى'));
    return coupon.discountRaw.isNotEmpty && coupon.discountRaw != '0' ? 'خصم يصل إلى ${coupon.discountRaw}' : 'عروض حصرية مميزة';
  }

  String _getFlagEmoji(String country) {
    final c = country.trim();
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

  Widget _buildStoresTab() {
    return Container(
      color: const Color(0xFFF9F9F9),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildAppBar(),
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
                    'المتاجر',
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
          if (_stores.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                alignment: Alignment.center,
                child: Text(
                  'لا توجد متاجر متاحة حالياً',
                  style: AppTheme.tajawal(color: Colors.grey),
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
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final store = _stores[i];
                    final discount = _getStoreDiscountText(store.name);
                    return GestureDetector(
                      onTap: () {
                        if (store.url.isNotEmpty) _launch(store.url);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Center(
                                child: store.logoUrl.isNotEmpty
                                    ? (store.logoUrl.startsWith('http')
                                        ? Image.network(
                                            store.logoUrl,
                                            height: 52,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => Text(
                                              store.name,
                                              style: AppTheme.tajawal(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        : (store.logoUrl.startsWith('assets/')
                                            ? Image.asset(
                                                store.logoUrl,
                                                height: 52,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) => Text(
                                                  store.name,
                                                  style: AppTheme.tajawal(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              )
                                            : Text(
                                                store.name,
                                                style: AppTheme.tajawal(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              )))
                                    : Text(
                                        store.name,
                                        style: AppTheme.tajawal(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              discount,
                              style: AppTheme.tajawal(
                                color: const Color(0xFFFF485A),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              store.name,
                              style: AppTheme.tajawal(
                                color: const Color(0xFF888888),
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _stores.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final favoriteCoupons = _coupons.where((c) => _favoriteCouponIds.contains(c.id)).toList();
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  'المفضلة',
                  style: AppTheme.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondaryinWhite,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        if (favoriteCoupons.isEmpty)
          SliverToBoxAdapter(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد مفضلات حالياً',
                    style: AppTheme.tajawal(color: AppTheme.textSecondaryinWhite, fontSize: 15),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final coupon = favoriteCoupons[i];
                  return ApiCouponCard(
                    key: ValueKey(coupon.id),
                    coupon: coupon,
                    index: i,
                    totalItems: favoriteCoupons.length,
                    isFavorite: true,
                    onFavoriteToggle: () => _toggleFavorite(coupon.id),
                  );
                },
                childCount: favoriteCoupons.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGridToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[1].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Decorative background circles for a modern glassmorphic look
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.tajawal(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: AppTheme.tajawal(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolsAppBar() => SliverAppBar(
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const SizedBox(width: 12),
                Text(
                  'الأدوات',
                  style: AppTheme.tajawal(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'التنبيهات',
                  style: AppTheme.tajawal(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                Switch.adaptive(
                  value: _dailyReminderEnabled,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.white.withOpacity(0.3),
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.white12,
                  onChanged: _toggleDailyReminder,
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildToolsTab() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        _buildToolsAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                
                // Featured Tool (Full width)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpinWheelScreen(coupons: _coupons),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF311B92), Color(0xFF7E57C2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF673AB7).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -40,
                            top: -40,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'حصري وتفاعلي 🎁',
                                          style: AppTheme.tajawal(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'عجلة الحظ اليومية',
                                        style: AppTheme.tajawal(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'أدر العجلة واربح أحدث الكوبونات الحصرية أو نصائح التوفير المذهلة!',
                                        style: AppTheme.tajawal(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.toys_rounded, color: Colors.white, size: 48),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 2x2 Grid using GridView
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildGridToolCard(
                      title: 'حاسبة التوفير',
                      subtitle: 'احسب قيمة الخصومات بدقة وفورية.',
                      icon: Icons.calculate_rounded,
                      gradientColors: const [Color(0xFFE65100), Color(0xFFFF9800)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SavingsCalculatorScreen()),
                        );
                      },
                    ),
                    _buildGridToolCard(
                      title: 'شارك كوبون',
                      subtitle: 'اقترح وانشر كوبونات للمجتمع.',
                      icon: Icons.add_moderator_rounded,
                      gradientColors: const [Color(0xFF00796B), Color(0xFF26A69A)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SubmitCouponScreen()),
                        );
                      },
                    ),
                    _buildGridToolCard(
                      title: 'كل الكوبونات',
                      subtitle: 'تصفح قائمة الكوبونات كاملة.',
                      icon: Icons.local_offer_rounded,
                      gradientColors: const [Color(0xFFC2185B), Color(0xFFF06292)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AllCouponsScreen(coupons: _coupons)),
                        );
                      },
                    ),
                    _buildGridToolCard(
                      title: 'المفضلة',
                      subtitle: 'الوصول السريع للكوبونات المحفوظة.',
                      icon: Icons.favorite_rounded,
                      gradientColors: const [Color(0xFF0277BD), Color(0xFF29B6F6)],
                      onTap: () {
                         setState(() {
                           _selectedNavIndex = 3;
                         });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialIcon(Widget icon, String url) => GestureDetector(
        onTap: () => _launch(url),
        child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.15))),
            child: Center(child: icon)),
      );
}

// Helper extension to avoid null check repetition
extension on Widget {
  Widget get errorWidget => this;
}
