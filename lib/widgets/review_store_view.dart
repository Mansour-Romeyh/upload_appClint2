import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../screens/savings_calculator_screen.dart';
import '../screens/spin_wheel_screen.dart';

class ReviewStoreView extends StatefulWidget {
  const ReviewStoreView({super.key});

  @override
  State<ReviewStoreView> createState() => _ReviewStoreViewState();
}

class _ReviewStoreViewState extends State<ReviewStoreView> {
  String _selectedCategory = 'الكل';
  final List<Map<String, dynamic>> _cart = [];
  double _totalSaved = 0.0;
  double _savingsGoal = 1000.0;
  int _historyCount = 0;

  final List<Map<String, dynamic>> _products = [
    {
      'id': 'noon_100',
      'title': 'بطاقة هدايا نون (100 ريال)',
      'category': 'بطاقات رقمية',
      'price': 95.0,
      'oldPrice': 100.0,
      'icon': Icons.card_giftcard_rounded,
      'color': Colors.amber,
      'desc': 'بطاقة شحن رقمية صالحة للاستخدام في متجر نون للتسوق لشراء كافة المنتجات والأجهزة بشكل فوري وسريع.',
    },
    {
      'id': 'vip_sub',
      'title': 'اشتراك VIP كوبوني سنوي',
      'category': 'اشتراكات',
      'price': 150.0,
      'oldPrice': 200.0,
      'icon': Icons.star_rounded,
      'color': Colors.purple,
      'desc': 'احصل على ميزات حصرية ونسب كاش باك إضافية وتنبيهات مخصصة طوال العام للادخار الأقصى.',
    },
    {
      'id': 'leather_wallet',
      'title': 'محفظة التوفير الجلدية',
      'category': 'ملحقات',
      'price': 85.0,
      'oldPrice': 120.0,
      'icon': Icons.wallet_rounded,
      'color': Colors.brown,
      'desc': 'محفظة فاخرة مصنوعة من الجلد الطبيعي لتنظيم الكروت والعملات بشكل منظم وأنيق لتتبع نفقاتك.',
    },
    {
      'id': 'smart_holder',
      'title': 'حامل البطاقات الذكي',
      'category': 'ملحقات',
      'price': 40.0,
      'icon': Icons.credit_card_rounded,
      'color': Colors.blueGrey,
      'desc': 'حامل بطاقات مدمج وعصري بتقنية حماية RFID لحفظ بطاقاتك البنكية بأمان تام وسهولة الوصول.',
    },
    {
      'id': 'budget_mug',
      'title': 'كوب رائد الادخار',
      'category': 'ملحقات',
      'price': 30.0,
      'icon': Icons.coffee_rounded,
      'color': Colors.deepOrange,
      'desc': 'كوب سيراميك فاخر مطبوع عليه عبارات تحفيزية للادخار والتوفير الذكي لبدء صباحك بنشاط.',
    },
    {
      'id': 'premium_tshirt',
      'title': 'تيشرت كوبوني المميز',
      'category': 'ملحقات',
      'price': 65.0,
      'oldPrice': 90.0,
      'icon': Icons.checkroom_rounded,
      'color': Colors.blue,
      'desc': 'تيشرت قطني 100% بتصميم عصري مريح يحمل شعار كوبوني الرسمي ومناسب للاستخدام اليومي.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('savings_history');
      final goalVal = prefs.getDouble('savings_goal') ?? 1000.0;
      if (historyStr != null) {
        final List<dynamic> decoded = jsonDecode(historyStr);
        final history = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        double total = 0.0;
        for (var item in history) {
          total += (item['savedAmount'] as num).toDouble();
        }
        setState(() {
          _totalSaved = total;
          _savingsGoal = goalVal;
          _historyCount = history.length;
        });
      } else {
        setState(() {
          _savingsGoal = goalVal;
          _historyCount = 0;
          _totalSaved = 0.0;
        });
      }
    } catch (e) {
      debugPrint('Error loading savings history in review: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategory == 'الكل') return _products;
    return _products.where((p) => p['category'] == _selectedCategory).toList();
  }

  int get _cartTotalItems {
    return _cart.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
  }

  double get _cartTotalPrice {
    return _cart.fold<double>(0.0, (sum, item) => sum + ((item['product']['price'] as double) * (item['quantity'] as int)));
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final index = _cart.indexWhere((item) => item['product']['id'] == product['id']);
      if (index >= 0) {
        _cart[index]['quantity'] = (_cart[index]['quantity'] as int) + 1;
      } else {
        _cart.add({'product': product, 'quantity': 1});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('تمت إضافة "${product['title']}" إلى السلة 🛒', style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
    ));
  }

  void _updateCartQuantity(int index, int delta) {
    setState(() {
      final newQty = (_cart[index]['quantity'] as int) + delta;
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index]['quantity'] = newQty;
      }
    });
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: (product['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(product['icon'] as IconData, size: 64, color: product['color'] as Color),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    product['title'] as String,
                    style: AppTheme.tajawal(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product['category'] as String,
                      style: AppTheme.tajawal(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'الوصف:',
                    style: AppTheme.tajawal(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product['desc'] as String,
                    style: AppTheme.tajawal(fontSize: 14, color: Colors.grey.shade700, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('السعر:', style: AppTheme.tajawal(color: Colors.grey, fontSize: 13)),
                          Row(
                            children: [
                              Text(
                                '${product['price']} ر.س',
                                style: AppTheme.tajawal(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                              if (product['oldPrice'] != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${product['oldPrice']} ر.س',
                                  style: AppTheme.tajawal(
                                    fontSize: 15,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _addToCart(product);
                        },
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: Text('إضافة للسلة', style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 60,
                          height: 5,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('سلة التسوق 🛒', style: AppTheme.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('(${_cartTotalItems} قطع)', style: AppTheme.tajawal(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: _cart.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    Text('سلة التسوق فارغة حالياً', style: AppTheme.tajawal(color: Colors.grey, fontSize: 15)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: _cart.length,
                                itemBuilder: (context, i) {
                                  final item = _cart[i];
                                  final product = item['product'];
                                  final qty = item['quantity'] as int;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                    color: Colors.grey.shade50,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: (product['color'] as Color).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(product['icon'] as IconData, color: product['color'] as Color),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(product['title'] as String, style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                const SizedBox(height: 4),
                                                Text('${product['price']} ر.س', style: AppTheme.tajawal(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  _updateCartQuantity(i, -1);
                                                  setModalState(() {});
                                                  setState(() {});
                                                },
                                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                              ),
                                              Text('$qty', style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
                                              IconButton(
                                                onPressed: () {
                                                  _updateCartQuantity(i, 1);
                                                  setModalState(() {});
                                                  setState(() {});
                                                },
                                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (_cart.isNotEmpty) ...[
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('إجمالي الطلب:', style: AppTheme.tajawal(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('${_cartTotalPrice.toStringAsFixed(2)} ر.س', style: AppTheme.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showCheckout();
                            },
                            child: Text('إتمام الشراء والطلب', style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCheckout() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String paymentMethod = 'الدفع عند الاستلام';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 5,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('تفاصيل الشحن والدفع 💳', style: AppTheme.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل',
                        labelStyle: AppTheme.tajawal(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم الجوال',
                        labelStyle: AppTheme.tajawal(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'عنوان الشحن والتفاصيل',
                        labelStyle: AppTheme.tajawal(fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('طريقة الدفع:', style: AppTheme.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: Text('الدفع عند الاستلام', style: AppTheme.tajawal(fontSize: 14)),
                      value: 'الدفع عند الاستلام',
                      groupValue: paymentMethod,
                      activeColor: AppTheme.primary,
                      onChanged: (val) {
                        setModalState(() => paymentMethod = val!);
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الإجمالي المستحق:', style: AppTheme.tajawal(fontSize: 14, color: Colors.grey)),
                        Text('${_cartTotalPrice.toStringAsFixed(2)} ر.س', style: AppTheme.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('يرجى ملء الاسم ورقم الجوال للمتابعة', style: AppTheme.tajawal()),
                              backgroundColor: Colors.redAccent,
                            ));
                            return;
                          }
                          Navigator.pop(context);
                          _checkoutSuccess();
                        },
                        child: Text('تأكيد وإرسال الطلب', style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _checkoutSuccess() {
    final orderNum = '#CPN${10000 + (DateTime.now().millisecond % 90000)}';
    setState(() {
      _cart.clear();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'تم إرسال طلبك بنجاح! 🎉',
                style: AppTheme.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'رقم الطلب الخاص بك: $orderNum\nسيقوم أحد ممثلي الخدمة بالتواصل معك هاتفياً لتأكيد الشحن خلال 24 ساعة.',
                style: AppTheme.tajawal(fontSize: 13, color: Colors.grey.shade700, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('موافق', style: AppTheme.tajawal(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'مساعد التوفير والتسوق الذكي',
          style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                onPressed: _showCart,
              ),
              if (_cartTotalItems > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_cartTotalItems',
                      style: AppTheme.tajawal(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            // Dashboard Header & Stats (Savings Goal & Tracker Summary)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    _buildStatsCardReview(),
                    const SizedBox(height: 12),
                    _buildGoalCardReview(),
                    const SizedBox(height: 16),
                    _buildQuickToolsRow(),
                  ],
                ),
              ),
            ),

            // Banner Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'عروض الصيف الكبرى ☀️',
                            style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'خصومات حصرية تصل إلى 25% على البطاقات والمستلزمات!',
                            style: AppTheme.tajawal(color: Colors.white.withOpacity(0.9), fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.discount_rounded, color: Colors.white, size: 48),
                  ],
                ),
              ),
            ),

            // Categories Selector
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['الكل', 'بطاقات رقمية', 'اشتراكات', 'ملحقات'].map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(
                          cat,
                          style: AppTheme.tajawal(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primary,
                        backgroundColor: Colors.white,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Products Grid
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final product = _filteredProducts[i];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.05),
                      color: Colors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showProductDetails(product),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: (product['color'] as Color).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(product['icon'] as IconData, size: 48, color: product['color'] as Color),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                product['title'] as String,
                                style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${product['price']} ر.س',
                                        style: AppTheme.tajawal(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14),
                                      ),
                                      if (product['oldPrice'] != null)
                                        Text(
                                          '${product['oldPrice']} ر.س',
                                          style: AppTheme.tajawal(
                                            fontSize: 10,
                                            color: Colors.grey,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                    ],
                                  ),
                                  Container(
                                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                                    child: IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 16),
                                      onPressed: () => _addToCart(product),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _filteredProducts.length,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCardReview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E24), Color(0xFF2E2E38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي التوفير الشخصي',
                  style: AppTheme.tajawal(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_totalSaved.toStringAsFixed(2)} ر.س',
                  style: AppTheme.tajawal(
                    color: AppTheme.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calculate_rounded, color: AppTheme.primary, size: 24),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text(
                      'العمليات',
                      style: AppTheme.tajawal(color: Colors.white60, fontSize: 10),
                    ),
                    Text(
                      '$_historyCount',
                      style: AppTheme.tajawal(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialogReview() {
    final controller = TextEditingController(text: _savingsGoal.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تعديل هدف التوفير',
            style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('حدد المبلغ المستهدف للتوفير بالريال:',
                style: AppTheme.tajawal(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: 'ر.س',
                suffixStyle: AppTheme.tajawal(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء',
                style: AppTheme.tajawal(color: Colors.grey, fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text) ?? 0.0;
              if (val > 0) {
                setState(() {
                  _savingsGoal = val;
                });
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble('savings_goal', val);
                } catch (_) {}
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('حفظ',
                style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCardReview() {
    final progressRatio = (_totalSaved / _savingsGoal).clamp(0.0, 1.0);
    final percentage = (progressRatio * 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEBEB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.track_changes_rounded, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'هدف التوفير المستهدف',
                    style: AppTheme.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showEditGoalDialogReview,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'تعديل الهدف',
                        style: AppTheme.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التقدم: $percentage%',
                style: AppTheme.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: progressRatio >= 1.0 ? Colors.green : Colors.grey.shade700,
                ),
              ),
              Text(
                '${_totalSaved.toStringAsFixed(0)} / ${_savingsGoal.toStringAsFixed(0)} ر.س',
                style: AppTheme.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: constraints.maxWidth * progressRatio,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToolsRow() {
    return Row(
      children: [
        // Savings Calculator Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavingsCalculatorScreen()),
              ).then((_) => _loadHistory());
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFF9800)],
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
                    'سجل نفقاتك ومقدار خصمك',
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
        // Daily Tips Wheel Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SpinWheelScreen(coupons: [])),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF311B92), Color(0xFF673AB7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
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
                    child: const Icon(Icons.tips_and_updates_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'نصيحة التوفير',
                    style: AppTheme.tajawal(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'أدر عجلة النصائح اليومية',
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
    );
  }
}
