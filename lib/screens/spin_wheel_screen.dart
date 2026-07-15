// lib/screens/spin_wheel_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/coupon.dart';
import '../utils/theme.dart';
import '../services/remote_config_service.dart';

class SpinWheelScreen extends StatefulWidget {
  final List<Coupon> coupons;
  const SpinWheelScreen({super.key, required this.coupons});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _rotationAngle = 0.0;
  bool _isSpinning = false;
  int _winnerIndex = 0;

  // 8 predefined items for the wheel (coupons or saving tips)
  final List<Map<String, dynamic>> _wheelItems = [
    {
      'label': 'كوبون نون',
      'code': 'NOON50',
      'store': 'نون',
      'isCoupon': true,
      'color': const Color(0xFFFFB300)
    },
    {
      'label': 'نصيحة توفير',
      'tip': 'قارن الأسعار بين المتاجر المختلفة قبل إتمام الشراء لتضمن التوفير الفعلي.',
      'isCoupon': false,
      'color': const Color(0xFFE040FB)
    },
    {
      'label': 'كوبون نمشي',
      'code': 'NAMSHI15',
      'store': 'نمشي',
      'isCoupon': true,
      'color': const Color(0xFF00E676)
    },
    {
      'label': 'نصيحة توفير',
      'tip': 'قم بحفظ الكوبونات المفضلة لديك لتتمكن من استخدامها بسهولة دون إنترنت.',
      'isCoupon': false,
      'color': const Color(0xFF00B0FF)
    },
    {
      'label': 'كوبون ايهيرب',
      'code': 'IHERB22',
      'store': 'ايهيرب',
      'isCoupon': true,
      'color': const Color(0xFFFF3D00)
    },
    {
      'label': 'نصيحة توفير',
      'tip': 'تجنب الشراء الاندفاعي؛ انتظر 24 ساعة قبل شراء أي منتج غير ضروري.',
      'isCoupon': false,
      'color': const Color(0xFFEC407A)
    },
    {
      'label': 'كوبون تيمو',
      'code': 'TEMU100',
      'store': 'تيمو',
      'isCoupon': true,
      'color': const Color(0xFF29B6F6)
    },
    {
      'label': 'نصيحة توفير',
      'tip': 'استخدم حاسبة التوفير الذكية بالتطبيق لتسجيل ومتابعة إجمالي أرباحك وتوفيرك.',
      'isCoupon': false,
      'color': const Color(0xFFAB47BC)
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    );

    // Overwrite some coupon codes with real coupons if available in the system
    _matchRealCoupons();
  }

  void _matchRealCoupons() {
    if (RemoteConfigService.isReviewMode) {
      final List<Map<String, dynamic>> reviewTips = [
        {
          'label': 'نصيحة الميزانية',
          'tip': 'حدد ميزانية شهرية للمشتريات والتزم بها لتتجنب النفقات الزائدة.',
          'isCoupon': false,
          'color': const Color(0xFFFFB300)
        },
        {
          'label': 'نصيحة المقارنة',
          'tip': 'قارن الأسعار بين المتاجر المختلفة قبل إتمام الشراء لتضمن التوفير الفعلي.',
          'isCoupon': false,
          'color': const Color(0xFFE040FB)
        },
        {
          'label': 'نصيحة التتبع',
          'tip': 'قم بتسجيل مشترياتك في حاسبة التوفير لمراقبة نمو مدخراتك باستمرار.',
          'isCoupon': false,
          'color': const Color(0xFF00E676)
        },
        {
          'label': 'نصيحة الانتظار',
          'tip': 'تجنب الشراء الاندفاعي؛ انتظر 24 ساعة قبل شراء أي منتج غير ضروري.',
          'isCoupon': false,
          'color': const Color(0xFF00B0FF)
        },
        {
          'label': 'نصيحة القوائم',
          'tip': 'اكتب قائمة مشترياتك قبل الذهاب للتسوق واشترِ فقط ما هو مدون فيها.',
          'isCoupon': false,
          'color': const Color(0xFFFF3D00)
        },
        {
          'label': 'نصيحة البدائل',
          'tip': 'ابحث عن بدائل محلية للمنتجات ذات الأسعار المرتفعة للتوفير الفعال.',
          'isCoupon': false,
          'color': const Color(0xFFEC407A)
        },
        {
          'label': 'نصيحة الكاش باك',
          'tip': 'استغل عروض الشحن المجاني والبطاقات الائتمانية التي توفر كاش باك على المشتريات.',
          'isCoupon': false,
          'color': const Color(0xFF29B6F6)
        },
        {
          'label': 'نصيحة المواسم',
          'tip': 'تسوق في مواسم التخفيضات الكبرى واشترِ المنتجات الموسمية خارج وقت ذروتها.',
          'isCoupon': false,
          'color': const Color(0xFFAB47BC)
        },
      ];
      _wheelItems.clear();
      _wheelItems.addAll(reviewTips);
      return;
    }

    if (widget.coupons.isEmpty) return;
    int wheelCouponIdx = 0;
    for (int i = 0; i < _wheelItems.length; i++) {
      if (_wheelItems[i]['isCoupon'] == true) {
        if (wheelCouponIdx < widget.coupons.length) {
          final realCoupon = widget.coupons[wheelCouponIdx];
          _wheelItems[i]['label'] = 'كوبون ${realCoupon.storeName}';
          _wheelItems[i]['code'] = realCoupon.code;
          _wheelItems[i]['store'] = realCoupon.storeName;
          wheelCouponIdx++;
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
    });

    // Generate a random target angle (5 to 10 full turns + offset)
    final random = Random();
    final double extraRotations = (5 + random.nextInt(5)) * 2 * pi;
    final int targetIndex = random.nextInt(_wheelItems.length);
    _winnerIndex = targetIndex;

    // Angle of each segment is 2*pi / 8 = pi/4
    // We want the selected segment to stop at the top pointer (angle = 3*pi/2 in standard polar coords)
    // To make targetIndex land on the top, the rotation angle should be:
    // angle = (3 * pi / 2) - (targetIndex * pi / 4) - (pi / 8) [center of segment]
    final double segmentAngle = 2 * pi / _wheelItems.length;
    // We compute the target angle to rotate the canvas
    final double targetOffset = (2 * pi) - (targetIndex * segmentAngle) - (segmentAngle / 2);
    final double totalAngle = extraRotations + targetOffset;

    _animation = Tween<double>(
      begin: _rotationAngle % (2 * pi),
      end: totalAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    ));

    _controller.reset();
    _controller.forward().then((_) {
      setState(() {
        _rotationAngle = totalAngle;
        _isSpinning = false;
      });
      _showResultDialog();
    });
  }

  void _showResultDialog() {
    final winner = _wheelItems[_winnerIndex];
    final isCoupon = winner['isCoupon'] as bool;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Result',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              contentPadding: EdgeInsets.zero,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCoupon
                            ? [const Color(0xFFFF485A), const Color(0xFFFF7A8A)]
                            : [const Color(0xFF00796B), const Color(0xFF00BFA5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isCoupon
                              ? Icons.local_offer_rounded
                              : Icons.tips_and_updates_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isCoupon ? 'تهانينا! لقد فزت بكوبون' : 'نصيحة التوفير اليومية',
                          style: AppTheme.tajawal(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        if (isCoupon) ...[
                          Text(
                            'كوبون خصم مميز لـ ${winner['store']}',
                            style: AppTheme.tajawal(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.shade300,
                                  style: BorderStyle.solid,
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Blurred code style to match user requirements of permanent blur in listing,
                                // but here inside the game it reveals so they can use it
                                Text(
                                  winner['code'],
                                  style: AppTheme.tajawal(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF485A),
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: winner['code']));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم نسخ الكود: ${winner['code']}',
                                    style: AppTheme.tajawal(color: Colors.white),
                                  ),
                                  backgroundColor: const Color(0xFFFF485A),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.copy_rounded, color: Colors.white),
                            label: Text(
                              'نسخ الكود',
                              style: AppTheme.tajawal(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF485A),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ] else ...[
                          Text(
                            winner['tip'],
                            style: AppTheme.tajawal(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00796B),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                            ),
                            child: Text(
                              'شكراً لك',
                              style: AppTheme.tajawal(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildWheelLabels() {
    final double radius = 150; // Size is 300, so radius is 150
    final double segmentAngle = 2 * pi / _wheelItems.length;

    List<Widget> widgets = [];
    for (int i = 0; i < _wheelItems.length; i++) {
      final label = _wheelItems[i]['label'] as String;
      double angle = i * segmentAngle + (segmentAngle / 2);
      angle = angle % (2 * pi);

      widgets.add(
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: angle,
              child: Transform.translate(
                offset: Offset(radius * 0.52, 0), // Center of the space
                child: SizedBox(
                  width: radius - 20, // Prevents text from ever overflowing outside the wheel
                  child: Text(
                    label,
                    style: AppTheme.tajawal(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right, // In RTL, right means the outer edge
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF150A21), // Dark space theme
      appBar: AppBar(
        title: Text(
          'عجلة التوفير اليومية',
          style: AppTheme.tajawal(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'أدر العجلة اليوم لتحصل على كود خصم إضافي أو نصائح توفيرية حصرية تزيد من ذكاء تسوقك! 🎁',
                  style: AppTheme.tajawal(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              // Wheel Container
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow/shadow
                    Container(
                      width: 310,
                      height: 310,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF485A).withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                    ),
                    // Wheel Painter
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _isSpinning ? _animation.value : _rotationAngle,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: 300,
                        height: 300,
                        child: Stack(
                          children: [
                            CustomPaint(
                              size: const Size(300, 300),
                              painter: SpinWheelPainter(items: _wheelItems),
                            ),
                            ..._buildWheelLabels(),
                          ],
                        ),
                      ),
                    ),
                    // Central spin button
                    GestureDetector(
                      onTap: _spinWheel,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                          border: Border.all(
                              color: const Color(0xFF150A21), width: 4),
                        ),
                        child: Center(
                          child: Text(
                            'SPIN',
                            style: AppTheme.tajawal(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFFFF485A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Pointer at the top
                    Positioned(
                      top: 0,
                      child: Transform.rotate(
                        angle: pi,
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Information Box
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF485A).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFFF485A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طريقة اللعب',
                            style: AppTheme.tajawal(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اضغط على زر SPIN في المنتصف، وستبدأ العجلة بالدوران. ستقف العجلة على جائزة حصرية عشوائية.',
                            style: AppTheme.tajawal(
                              color: Colors.white60,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class SpinWheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> items;
  SpinWheelPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final double sweepAngle = 2 * pi / items.length;

    // Draw slices
    for (int i = 0; i < items.length; i++) {
      final double startAngle = i * sweepAngle;

      final paint = Paint()
        ..color = items[i]['color'] as Color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Draw thin lines between slices
      final borderPaint = Paint()
        ..color = const Color(0xFF150A21).withOpacity(0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

      // Labels are now drawn in Stack via _buildWheelLabels() to prevent disjointed characters.
    }

    // Draw outer border
    final outerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 3, outerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
