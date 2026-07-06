import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/coupon.dart';
import '../utils/theme.dart';

class StoreItem extends StatelessWidget {
  final Store store;
  final VoidCallback? onTap;
  final int index;
  final int totalItems;

  const StoreItem(
      {super.key,
      required this.store,
      this.onTap,
      required this.index,
      required this.totalItems});

  bool get _isLocal => store.logoUrl.startsWith('assets/');

  Widget _buildLogo() {
    final logo = store.logoUrl;
    if (logo.isEmpty) return _fallback();

    if (_isLocal) {
      if (logo.endsWith('.svg')) {
        return SvgPicture.asset(logo,
            fit: BoxFit.cover, placeholderBuilder: (_) => _fallback());
      }
      return Image.asset(logo,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback());
    }

    if (logo.startsWith('http')) {
      if (logo.endsWith('.svg')) {
        return SvgPicture.network(logo,
            fit: BoxFit.cover, placeholderBuilder: (_) => _fallback());
      }
      return Image.network(logo,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback());
    }

    return _fallback();
  }

  Widget _fallback() => Center(
        child: Text(store.name,
            style: AppTheme.tajawal(
                fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ValueNotifier(index),
        ValueNotifier(totalItems),
      ]),
      builder: (context, child) {
        final total = totalItems > 0 ? totalItems : 1;
        final progress = ((index / total) * 0.3 + 0.7).clamp(0.0, 1.0);
        final animation = Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: AlwaysStoppedAnimation<double>(progress),
            curve: Curves.easeInOut,
          ),
        );

        return AppTheme.animatedSlideFadeIn(
          child: child!,
          animation: animation,
          offset: 20,
          direction: AxisDirection.up,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 76,
          margin: const EdgeInsets.only(left: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: ClipOval(child: _buildLogo()),
              ),
              const SizedBox(height: 6),
              Text(
                store.name,
                style: AppTheme.tajawal(
                  fontSize: 12,
                  color: AppTheme.textSecondaryinWhite,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
