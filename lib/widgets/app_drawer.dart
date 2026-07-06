import 'dart:io';
import 'package:discounts_app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../models/api_models.dart';
import '../models/auth_models.dart';
import '../screens/auth/profile_screen.dart';
import '../screens/in_app_webview_screen.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class AppDrawer extends StatefulWidget {
  final SiteInfo? site;
  final HeroData? hero;
  final List<String> availableCategories;
  final List<String> availableCountries;
  final VoidCallback? onNavigateToCoupons;
  final VoidCallback? onNavigateToTopOffers;
  final VoidCallback? onNavigateToStores;
  final VoidCallback? onNavigateToHome;
  final ValueChanged<int>? onSelectTab;
  final int selectedIndex;

  const AppDrawer({
    super.key,
    this.site,
    this.hero,
    this.availableCategories = const [],
    this.availableCountries = const [],
    this.onNavigateToCoupons,
    this.onNavigateToTopOffers,
    this.onNavigateToStores,
    this.onNavigateToHome,
    this.onSelectTab,
    this.selectedIndex = 0,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _emailCtrl = TextEditingController();
  bool _emailSubmitting = false;
  bool _emailSent = false;

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppTheme.primary : Colors.grey.shade600, size: 22),
        title: Text(
          title,
          style: AppTheme.tajawal(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppTheme.primary : Colors.grey.shade800,
          ),
        ),
        onTap: onTap,
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      ),
    );
  }
  String? _emailError;

  static const String _defaultTiktok =
      'https://www.tiktok.com/@3rood_saudia?_r=1&_t=ZS-94wTAUGvh7o';
  static const String _defaultInstagram =
      'https://www.instagram.com/couponat_5sm?igsh=MWp6ZHJ2NnczZmJhZA==';
  static const String _defaultFacebook =
      'https://www.facebook.com/share/1CLo9ZBNup/';
  static const String _whatsappChannel =
      'https://whatsapp.com/channel/0029VaoUhiYATRShF1gyEc2p';
  static const String _whatsappDirect = 'https://wa.me/201203994799';

  String get _tiktokUrl => widget.hero?.tiktokUrl?.isNotEmpty == true
      ? widget.hero!.tiktokUrl!
      : _defaultTiktok;
  String get _instagramUrl => widget.hero?.instagramUrl?.isNotEmpty == true
      ? widget.hero!.instagramUrl!
      : _defaultInstagram;
  String get _facebookUrl => widget.hero?.facebookUrl?.isNotEmpty == true
      ? widget.hero!.facebookUrl!
      : _defaultFacebook;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  // void _openInApp(String url, String title) {
  //   Navigator.pop(context);
  //   Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => InAppWebViewScreen(url: url, title: title),
  //       ));
  // }
    Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }


  void _openProfile() {
    Navigator.pop(context);
    Future.microtask(() {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            availableCategories: widget.availableCategories,
            availableCountries: widget.availableCountries,
          ),
        ),
      );
    });
  }

  void _logout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تسجيل الخروج',
            style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟',
            style: AppTheme.tajawal(fontSize: 14, color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء',
                style: AppTheme.tajawal(color: Colors.grey, fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(ctx);
              ctx.read<AuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('خروج',
                style: AppTheme.tajawal(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitNewsletter() async {
    final email = _emailCtrl.text.trim();
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => _emailError = 'الرجاء إدخال بريد إلكتروني صحيح');
      return;
    }
    setState(() {
      _emailSubmitting = true;
      _emailError = null;
    });
    try {
      await ApiService.subscribeNewsletter(email);
      if (mounted)
        setState(() {
          _emailSent = true;
          _emailSubmitting = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() {
          _emailError = e.toString().replaceAll('Exception: ', '');
          _emailSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final footerLogo = widget.hero?.logoWhiteUrl ?? widget.site?.logoWhiteUrl;

    return Drawer(
      backgroundColor: AppTheme.background,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(children: [
          _DrawerHeader(
            site: widget.site,
            hero: widget.hero,
            footerLogo: footerLogo,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<AuthCubit, AuthState>(
                    buildWhen: (prev, curr) =>
                        curr is AuthAuthenticated ||
                        curr is AuthUnauthenticated ||
                        curr is AuthLoggedOut,
                    builder: (ctx, state) {
                      if (state is AuthAuthenticated) {
                        return _UserCard(
                          user: state.user,
                          onEdit: _openProfile,
                          onLogout: () => _logout(ctx),
                        );
                      }
                      return _AuthButtons(
                        onLogin: () {
                          Navigator.pop(context);
                          Future.microtask(() {
                            if (!mounted) return;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.home_outlined,
                    title: 'الرئيسية',
                    isSelected: widget.selectedIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelectTab?.call(0);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.store_outlined,
                    title: 'المتاجر',
                    isSelected: widget.selectedIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelectTab?.call(1);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.discount_outlined,
                    title: 'جميع الكوبونات',
                    isSelected: false, // شاشة منفصلة
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateToCoupons?.call();
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.local_offer_outlined,
                    title: 'كوبونات الخصم المميزة',
                    isSelected: false, // شاشة منفصلة
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateToTopOffers?.call();
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.star_outline,
                    title: 'المفضلة',
                    isSelected: widget.selectedIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelectTab?.call(2);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.star_outline,
                    title: 'قيمنا ⭐',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.share_outlined,
                    title: 'شارك التطبيق',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  Divider(
                      color: Colors.grey.shade400,
                      thickness: .7,
                      indent: 40,
                      endIndent: 40),
                  const SizedBox(height: 20),
                  const _SectionLabel('تابعنا'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialBtn(
                            icon: const FaIcon(FontAwesomeIcons.tiktok,
                                color: Colors.white, size: 17),
                            onTap: () => _launch(_tiktokUrl )),
                        const SizedBox(width: 10),
                        _SocialBtn(
                            icon: const FaIcon(FontAwesomeIcons.facebookF,
                                color: Colors.white, size: 17),
                            onTap: () => _launch(_facebookUrl)),
                        const SizedBox(width: 10),
                        _SocialBtn(
                            icon: const FaIcon(FontAwesomeIcons.instagram,
                                color: Colors.white, size: 17),
                            onTap: () =>
                                _launch(_instagramUrl)),
                        const SizedBox(width: 10),
                        _SocialBtn(
                            icon: const FaIcon(FontAwesomeIcons.whatsapp,
                                color: Colors.white, size: 17),
                            onTap: () =>
                                _launch(_whatsappDirect)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(
                      color: Colors.grey.shade400,
                      thickness: .7,
                      indent: 40,
                      endIndent: 40),
                  const SizedBox(height: 20),
                  _WhatsappBanner(
                    onTap: () => _launch(_whatsappChannel),
                  ),
                  const SizedBox(height: 20),
                  Divider(
                      color: Colors.grey.shade400,
                      thickness: .7,
                      indent: 40,
                      endIndent: 40),
                  const SizedBox(height: 10),
                  const _SectionLabel('النشرة البريدية'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اشترك للحصول على أحدث الكوبونات على بريدك مباشرة',
                          style: AppTheme.tajawal(
                              color: AppTheme.textSecondaryinWhite,
                              fontSize: 12,
                              height: 1.5),
                        ),
                        const SizedBox(height: 12),
                        if (_emailSent)
                          _SuccessBox()
                        else
                          _NewsletterForm(
                            controller: _emailCtrl,
                            loading: _emailSubmitting,
                            error: _emailError,
                            onSubmit: _submitNewsletter,
                            onChanged: (_) {
                              if (_emailError != null) {
                                setState(() => _emailError = null);
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _DrawerFooter(
              onTap: () => _launch('https://bioagency.net/')),
        ]),
      ),
    );
  }
}

// ── Drawer Header and Logo Fallback ───────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final SiteInfo? site;
  final HeroData? hero;
  final String? footerLogo;

  const _DrawerHeader({this.site, this.hero, this.footerLogo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFE65100),
            AppTheme.primary,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: footerLogo != null && footerLogo!.isNotEmpty
                ? Image.network(footerLogo!,
                    height: 36,
                    alignment: Alignment.centerRight,
                    errorBuilder: (_, __, ___) => _LogoFallback())
                : _LogoFallback(),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
          ),
        ]),
      ]),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/Logo_w.png',
        height: 36,
        errorBuilder: (_, __, ___) => Text(
          'COUPONEY',
          style: AppTheme.tajawal(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      );
}

// ── User card (shown when logged in) ─────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onLogout,
    // required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + Name/Email ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primary.withOpacity(0.25),
                backgroundImage: _resolveAvatar(user),
                child: _resolveAvatar(user) == null
                    ? Text(
                        user.initials,
                        style: AppTheme.tajawal(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppTheme.tajawal(
                          color: AppTheme.textSecondaryinWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppTheme.tajawal(
                          color: AppTheme.textSecondaryinWhite, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.phone != null && user.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.phone!,
                        style: AppTheme.tajawal(
                            color: AppTheme.textSecondaryinWhite, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── Categories chips ─────────────────────────────────
          if (user.preferredCategories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: user.preferredCategories
                  .where((cat) => cat.trim().isNotEmpty)
                  .take(4)
                  .map((cat) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(cat,
                      style: AppTheme.tajawal(
                          color: AppTheme.primary, fontSize: 12)),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),

          // ── Action buttons ───────────────────────────────────
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_outlined,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text('تعديل ',
                            style: AppTheme.tajawal(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: onLogout,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout,
                            color: Colors.redAccent, size: 18),
                        const SizedBox(width: 6),
                        Text('خروج ',
                            style: AppTheme.tajawal(
                                color: Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ]),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  ImageProvider? _resolveAvatar(User user) {
    if (user.localAvatarPath != null &&
        File(user.localAvatarPath!).existsSync()) {
      return FileImage(File(user.localAvatarPath!));
    }
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return NetworkImage(user.avatarUrl!);
    }
    return null;
  }
}

// ── Auth buttons (shown when not logged in) ───────────────────────────────────
class _AuthButtons extends StatelessWidget {
  final VoidCallback? onLogin;
  const _AuthButtons({this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: [
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.login, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('تسجيل الدخول',
                  style: AppTheme.tajawal(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Misc sub-widgets ──────────────────────────────────────────────────────────

class _WhatsappBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _WhatsappBanner({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const FaIcon(FontAwesomeIcons.whatsapp,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('تابعنا على قناة الواتساب',
                style: AppTheme.tajawal(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
        child: Text(text,
            style: AppTheme.tajawal(
                color: AppTheme.textSecondaryinWhite,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      );
}

class _SocialBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  const _SocialBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: AppTheme.textSecondaryinBlack,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.12))),
          child: Center(child: icon),
        ),
      );
}

class _SuccessBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text('تم الاشتراك بنجاح! 🎉',
              style: AppTheme.tajawal(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ]),
      );
}

class _NewsletterForm extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;
  final ValueChanged<String> onChanged;

  const _NewsletterForm({
    required this.controller,
    required this.loading,
    required this.onSubmit,
    required this.onChanged,
    this.error,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: error != null
                      ? Colors.red.withOpacity(0.5)
                      : AppTheme.primary)),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: controller,
                textDirection: TextDirection.rtl,
                keyboardType: TextInputType.emailAddress,
                style:
                    AppTheme.tajawal(color: Colors.grey.shade900, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'أدخل بريدك الإلكتروني',
                  hintStyle: AppTheme.tajawal(color: Colors.grey, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onSubmitted: (_) => onSubmit(),
                onChanged: onChanged,
              ),
            ),
            GestureDetector(
              onTap: loading ? null : onSubmit,
              child: Container(
                margin: const EdgeInsets.all(5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8)),
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white, size: 16),
              ),
            ),
          ]),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 13),
            const SizedBox(width: 4),
            Text(error!,
                style: AppTheme.tajawal(color: Colors.red, fontSize: 11)),
          ]),
        ],
      ]);
}

class _DrawerFooter extends StatelessWidget {
  final VoidCallback onTap;
  const _DrawerFooter({required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade400)),
        ),
        child: Column(children: [
          Text('© 2026 كوبوني . جميع الحقوق محفوظة.',
              style: AppTheme.tajawal(
                  color: AppTheme.textSecondaryinWhite, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Column(children: [
              Text('تم التطوير بواسطة',
                  style: AppTheme.tajawal(
                      color: AppTheme.textSecondaryinWhite, fontSize: 12)),
              const SizedBox(height: 10),
              Image.asset('assets/images/Bio.webp',
                  height: 20,
                  errorBuilder: (_, __, ___) => Text('BioAgency',
                      style: AppTheme.tajawal(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold))),
            ]),
          ),
        ]),
      );
}
