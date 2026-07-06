import 'package:flutter/material.dart';
import '../utils/theme.dart';

class FilterOptions {
  String company;
  String country;
  String category;

  FilterOptions({
    this.company = 'جميع الشركات',
    this.country = 'مصر',
    this.category = 'جميع الفئات',
  });

  FilterOptions copyWith({
    String? company,
    String? country,
    String? category,
  }) =>
      FilterOptions(
        company: company ?? this.company,
        country: country ?? this.country,
        category: category ?? this.category,
      );

  bool get isDefault =>
      company == 'جميع الشركات' &&
      country == 'مصر' &&
      category == 'جميع الفئات';
}

class FilterSheet extends StatefulWidget {
  final FilterOptions current;
  final List<String> companies;
  final List<String>? countries;
  final List<String>? categories;

  const FilterSheet({
    super.key,
    required this.current,
    this.companies = const ['جميع الشركات'],
    this.countries = const ['جميع الدول'],
    this.categories = const ['جميع الفئات'],
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late FilterOptions _options;

  static const List<String> _defaultCountries = [
    'جميع الدول',
    'مصر',
    'السعودية',
    'الإمارات',
    'الكويت',
    'قطر',
    'دولي',
  ];

  static const List<String> _defaultCategories = [
    'جميع الفئات',
    'أزياء',
    'إلكترونيات',
    'جمال',
    'رياضة',
    'طعام',
    'أخرى',
  ];

  // ✅ FIX: deduplicate بـ LinkedHashSet للحفاظ على الترتيب
  List<String> _dedupe(List<String> input) =>
      input.toSet().toList();

  List<String> get _countries =>
      _dedupe(widget.countries ?? _defaultCountries);

  List<String> get _categories {
    final raw = (widget.categories != null && widget.categories!.isNotEmpty)
        ? widget.categories!
        : _defaultCategories;
    return _dedupe(raw);
  }

  List<String> get _companies {
    final list = widget.companies.toList();
    if (!list.contains('جميع الشركات')) list.insert(0, 'جميع الشركات');
    return _dedupe(list);
  }

  @override
  void initState() {
    super.initState();
    _options = FilterOptions(
      company: widget.current.company,
      country: widget.current.country,
      category: widget.current.category,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
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
              Text(
                '🏷️  فلترة الكوبونات',
                style: AppTheme.tajawal(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.grey),
              ),
            ]),

            const SizedBox(height: 4),

            Text(
              'اختر الفلاتر المناسبة للعثور على أفضل الكوبونات',
              style: AppTheme.tajawal(fontSize: 12, color: AppTheme.primary),
            ),

            const SizedBox(height: 20),

            _buildDropdown(
              '🏢  المتجر:',
              _options.company,
              _companies,
              (v) => setState(() => _options = _options.copyWith(company: v)),
            ),

            const SizedBox(height: 16),

            _buildDropdown(
              '🌐  الدولة:',
              _options.country,
              _countries,
              (v) => setState(() => _options = _options.copyWith(country: v)),
            ),

            const SizedBox(height: 16),

            _buildDropdown(
              '🏷  الفئة:',
              _options.category,
              _categories,
              (v) => setState(() => _options = _options.copyWith(category: v)),
            ),

            const SizedBox(height: 24),

            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _options = FilterOptions()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9E9E9E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'إعادة تعيين',
                          style: AppTheme.tajawal(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, _options),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_alt,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'تطبيق الفلاتر',
                          style: AppTheme.tajawal(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),

            SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom + 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    // ✅ FIX: safeValue يضمن إن الـ value موجودة في الـ items
    // لو مش موجودة يرجع أول عنصر (عادةً "جميع ...")
    final safeValue =
        items.contains(value.trim()) ? value.trim() : items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              AppTheme.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Colors.grey),
              style:
                  AppTheme.tajawal(color: Colors.black, fontSize: 14),
              // ✅ FIX: toSet().toList() قبل الـ map يضمن عدم تكرار items
              items: items
                  .toSet()
                  .toList()
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}