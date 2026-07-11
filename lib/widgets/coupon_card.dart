import 'dart:ui';
import 'package:discounts_app/models/coupon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
// import '../screens/in_app_webview_screen.dart'; // ✅ جديد
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import 'dashed_border.dart';
import '../services/remote_config_service.dart';


class ApiCouponCard extends StatefulWidget {
  final Coupon coupon;
  final int index;
  final int totalItems;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const ApiCouponCard({
    super.key,
    required this.coupon,
    required this.index,
    required this.totalItems,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });
  @override
  State<ApiCouponCard> createState() => _ApiCouponCardState();
}

class _ApiCouponCardState extends State<ApiCouponCard> {
  bool? _votedWorked;
  int _workedCount = 0;
  int _expiredCount = 0;



  @override
  void initState() {
    super.initState();
    _loadVoteState();
  }

  void _loadVoteState() async {
    final seedWorked = (widget.coupon.id.hashCode % 15) + 4;
    final seedExpired = (widget.coupon.id.hashCode % 3);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final vote = prefs.getBool('vote_${widget.coupon.id}');
      if (mounted) {
        setState(() {
          _votedWorked = vote;
          _workedCount = seedWorked + (vote == true ? 1 : 0);
          _expiredCount = seedExpired + (vote == false ? 1 : 0);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _workedCount = seedWorked;
          _expiredCount = seedExpired;
        });
      }
    }
  }

  Future<void> _vote(bool worked) async {
    if (_votedWorked == worked) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vote_${widget.coupon.id}', worked);

      setState(() {
        if (_votedWorked == null) {
          if (worked) {
            _workedCount++;
          } else {
            _expiredCount++;
          }
        } else {
          if (worked) {
            _workedCount++;
            _expiredCount = (_expiredCount - 1).clamp(0, 9999);
          } else {
            _expiredCount++;
            _workedCount = (_workedCount - 1).clamp(0, 9999);
          }
        }
        _votedWorked = worked;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            worked ? 'تم تسجيل نجاح الكوبون! 👍' : 'تم تسجيل عدم فعالية الكوبون! 👎',
            style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          backgroundColor: worked ? AppTheme.accent : Colors.redAccent,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {}
  }


  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.coupon.code));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.copy, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('تم نسخ الكود بنجاح',
                style: AppTheme.tajawal(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Color get badgeColor =>
      AppTheme.badgeColors[widget.coupon.badge] ?? AppTheme.primary;
  Color get badgeTextColor =>
      AppTheme.badgeTextColors[widget.coupon.badge] ?? Colors.black;

  // ✅ فتح الموقع جوه التطبيق بعد نسخ الكود
  Future<void> _revealAndOpen() async {
    await Clipboard.setData(ClipboardData(text: widget.coupon.code));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('تم نسخ الكود بنجاح',
              style: AppTheme.tajawal(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
    }

    // ✅ افتح الموقع جوه التطبيق
    if (!RemoteConfigService.isReviewMode && widget.coupon.storeUrl.isNotEmpty && mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        _launch(widget.coupon.storeUrl);
      }
    }
  }

  Widget _buildLogo() {
    final url = widget.coupon.storeLogo;
    if (url.isEmpty)
      return Center(
          child: Text(widget.coupon.storeName,
              style: AppTheme.tajawal(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 12),
              textAlign: TextAlign.center));
    return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.grey[100]),
        errorWidget: (_, __, ___) => Center(
            child: Text(widget.coupon.storeName,
                style: AppTheme.tajawal(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 12),
                textAlign: TextAlign.center)));
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final totalItems = widget.totalItems > 0 ? widget.totalItems : 1;
    final progress = ((widget.index / totalItems) * 0.4 + 0.6).clamp(0.0, 1.0);
    final animation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: AlwaysStoppedAnimation<double>(progress),
        curve: Curves.easeInOut,
      ),
    );

    return AppTheme.animatedSlideFadeIn(
      animation: animation,
      offset: 25,
      direction: AxisDirection.up,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Badge الخصم ─────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(widget.coupon.discountRaw,
                                    style: AppTheme.tajawal(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary)),
                              ),
                              if (widget.onFavoriteToggle != null)
                                GestureDetector(
                                  onTap: widget.onFavoriteToggle,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      widget.isFavorite
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: widget.isFavorite
                                          ? Colors.orange
                                          : Colors.grey.shade600,
                                      size: 22,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ─── العنوان ──────────────────────────────────
                          Text(widget.coupon.title,
                              style: AppTheme.tajawal(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 6),

                          // ─── الدولة ───────────────────────────
                          if (widget.coupon.country.isNotEmpty)
                            Row(children: [
                              const Icon(Icons.language,
                                  size: 14,
                                  color: AppTheme.textSecondaryinWhite),
                              const SizedBox(width: 4),
                              Expanded(
                                  child: Text(widget.coupon.country,
                                      style: AppTheme.tajawal(
                                          fontSize: 12,
                                          color: AppTheme.textSecondaryinWhite),
                                      overflow: TextOverflow.visible)),
                            ]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: sw * 0.22,
                      height: sw * 0.22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildLogo(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // ─── كود الكوبون المباشر (Dashed Border) ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _revealAndOpen,
                        child: DashedBorder(
                          color: const Color(0xFFE0E0E0),
                          strokeWidth: 1.5,
                          dashWidth: 6,
                          dashSpace: 4,
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: 5,
                                  sigmaY: 5,
                                ),
                                child: Text(
                                  widget.coupon.code,
                                  style: AppTheme.tajawal(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 2,
                                  ),
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
                
                // ─── زر تفعيل الخصم (الأحمر/الكورال) ──────────────────────────────
                GestureDetector(
                  onTap: _revealAndOpen,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF485A), // Coral/Red
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'نسخ الكود',
                        style: AppTheme.tajawal(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade100, height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'هل اشتغل الكوبون معك؟',
                      style: AppTheme.tajawal(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _vote(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _votedWorked == true 
                                  ? AppTheme.accent.withOpacity(0.12)
                                  : Colors.grey.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _votedWorked == true 
                                    ? AppTheme.accent.withOpacity(0.3)
                                    : Colors.transparent
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.thumb_up_alt_rounded, 
                                  size: 14, 
                                  color: _votedWorked == true ? AppTheme.accent : Colors.grey.shade500
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '($_workedCount) نعم',
                                  style: AppTheme.tajawal(
                                    fontSize: 11, 
                                    color: _votedWorked == true ? AppTheme.accent : Colors.grey.shade700,
                                    fontWeight: _votedWorked == true ? FontWeight.bold : FontWeight.normal
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _vote(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _votedWorked == false 
                                  ? Colors.redAccent.withOpacity(0.12)
                                  : Colors.grey.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _votedWorked == false 
                                    ? Colors.redAccent.withOpacity(0.3)
                                    : Colors.transparent
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.thumb_down_alt_rounded, 
                                  size: 14, 
                                  color: _votedWorked == false ? Colors.redAccent : Colors.grey.shade500
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '($_expiredCount) لا',
                                  style: AppTheme.tajawal(
                                    fontSize: 11, 
                                    color: _votedWorked == false ? Colors.redAccent : Colors.grey.shade700,
                                    fontWeight: _votedWorked == false ? FontWeight.bold : FontWeight.normal
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
