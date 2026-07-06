// lib/screens/auth/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../cubits/profile/profile_state.dart';
import '../../models/auth_models.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';

const List<String> _kCategories = [
  'أزياء',
  'إلكترونيات',
  'جمال',
  'رياضة',
  'طعام',
  'سفر',
  'صحة',
  'منزل',
  'ترفيه',
  'أخرى',
];

const List<String> _kCountries = [
  'مصر',
  'السعودية',
  'الإمارات',
  'الكويت',
  'قطر',
  'البحرين',
  'الأردن',
  'المغرب',
  'دولي',
];

class ProfileScreen extends StatefulWidget {
  final List<String> availableCategories;
  final List<String> availableCountries;

  const ProfileScreen({
    super.key,
    this.availableCategories = const [],
    this.availableCountries = const [],
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // ── Info fields ─────────────────────────────────────────────────
  final _infoKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedCountry;
  List<String> _selectedCats = [];
  String? _localAvatarPath;
  final _picker = ImagePicker();

  // ── Password fields ─────────────────────────────────────────────
  final _passKey = GlobalKey<FormState>();
  final _curPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confPassCtrl = TextEditingController();
  bool _obscureCur = true, _obscureNew = true, _obscureConf = true;

  List<String> get _cats => widget.availableCategories.isNotEmpty
      ? widget.availableCategories
      : _kCategories;

  List<String> get _countries => widget.availableCountries.isNotEmpty
      ? widget.availableCountries
      : _kCountries;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileCubit>().load();
    });
  }

  void _populateFields(User user) {
    _nameCtrl.text = user.name;
    _emailCtrl.text = user.email;
    _phoneCtrl.text = user.phone ?? '';
    _selectedCountry = _countries.contains(user.country) ? user.country : null;
    _selectedCats = List.from(user.preferredCategories);
    _localAvatarPath = user.localAvatarPath;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _curPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text('الكاميرا', style: AppTheme.tajawal(fontSize: 15)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text('معرض الصور', style: AppTheme.tajawal(fontSize: 15)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 800);
    if (picked != null && mounted) {
      setState(() => _localAvatarPath = picked.path);
    }
  }

  void _toggleCat(String cat) {
    setState(() {
      if (_selectedCats.contains(cat)) {
        _selectedCats.remove(cat);
      } else {
        _selectedCats.add(cat);
      }
    });
  }

  void _saveInfo() {
    if (!_infoKey.currentState!.validate()) return;
    context.read<ProfileCubit>().updateProfile(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          country: _selectedCountry,
          preferredCategories: _selectedCats.isEmpty ? null : _selectedCats,
          localAvatarPath: _localAvatarPath,
        );
  }

  void _changePassword() {
    if (!_passKey.currentState!.validate()) return;
    context.read<ProfileCubit>().changePassword(
          currentPassword: _curPassCtrl.text,
          newPassword: _newPassCtrl.text,
          confirmPassword: _confPassCtrl.text,
        );
  }

  void _showDeleteAccountDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              'حذف الحساب نهائياً',
              style:
                  AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف حسابك نهائياً؟ هذا الإجراء لا يمكن التراجع عنه وسيتم مسح كافة تفضيلاتك.',
          style: AppTheme.tajawal(
              fontSize: 13, color: Colors.black54, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: AppTheme.tajawal(color: Colors.grey, fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ctx.read<AuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(
              'تأكيد الحذف',
              style: AppTheme.tajawal(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            _populateFields(state.user);
          }
          if (state is ProfileUpdateSuccess) {
            context.read<AuthCubit>().refreshUser();
            _showSnack(context, state.message, isError: false);
          }
          if (state is PasswordChangeSuccess) {
            _showSnack(context, 'تم تغيير كلمة المرور بنجاح ✅', isError: false);
            _curPassCtrl.clear();
            _newPassCtrl.clear();
            _confPassCtrl.clear();
          }
          if (state is ProfileError) {
            _showSnack(context, state.message, isError: true);
          }
        },
        builder: (context, state) {
          final loading = state is ProfileLoading;

          if (state is ProfileInitial) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }

          return Column(
            children: [
              _buildPremiumHeader(loading),
              _buildTabBarContainer(),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _buildInfoTab(loading),
                    _buildPasswordTab(loading),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumHeader(bool loading) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFD84315),
            AppTheme.primary,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 40, bottom: 24, left: 16, right: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'الملف الشخصي',
                style: AppTheme.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 48), // Balancing spacer
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: loading ? null : _pickImage,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    backgroundImage: _localAvatarPath != null
                        ? FileImage(File(_localAvatarPath!))
                        : null,
                    child: _localAvatarPath == null
                        ? Text(
                            _nameCtrl.text.isNotEmpty
                                ? _nameCtrl.text[0].toUpperCase()
                                : '؟',
                            style: AppTheme.tajawal(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF485A),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'مستخدم جديد',
            style: AppTheme.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _emailCtrl.text.isNotEmpty ? _emailCtrl.text : '---',
            style: AppTheme.tajawal(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarContainer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabs,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle:
              AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: AppTheme.tajawal(fontSize: 13),
          tabs: const [
            Tab(text: 'البيانات الشخصية'),
            Tab(text: 'أمان الحساب'),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Info ─────────────────────────────────────────────────
  Widget _buildInfoTab(bool loading) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Form(
        key: _infoKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined,
                          color: AppTheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'المعلومات الأساسية',
                        style: AppTheme.tajawal(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _PLabel('الاسم الكامل'),
                  _PField(
                    controller: _nameCtrl,
                    hint: 'الاسم الكامل',
                    icon: Icons.person_outline_rounded,
                    validator: Validators.name,
                    enabled: !loading,
                  ),
                  const SizedBox(height: 16),
                  _PLabel('البريد الإلكتروني'),
                  _PField(
                    controller: _emailCtrl,
                    hint: 'example@email.com',
                    icon: Icons.email_outlined,
                    ltr: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    enabled: !loading,
                  ),
                  const SizedBox(height: 16),
                  _PLabel('رقم الهاتف'),
                  _PField(
                    controller: _phoneCtrl,
                    hint: '+966 5X XXX XXXX',
                    icon: Icons.phone_outlined,
                    ltr: true,
                    keyboardType: TextInputType.phone,
                    validator: Validators.phoneOptional,
                    enabled: !loading,
                  ),
                  const SizedBox(height: 16),
                  _PLabel('الدولة'),
                  _DropdownBox(
                    value: _selectedCountry,
                    items: _countries,
                    hint: 'اختر دولتك',
                    enabled: !loading,
                    onChanged: (v) => setState(() => _selectedCountry = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.interests_outlined,
                          color: AppTheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'اهتماماتك وتفضيلاتك',
                        style: AppTheme.tajawal(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اختر الفئات التي تهمك لتخصيص تجربتك وعرض كوبونات مناسبة لك',
                    style: AppTheme.tajawal(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _cats.map((cat) {
                      final sel = _selectedCats.contains(cat);
                      return GestureDetector(
                        onTap: loading ? null : () => _toggleCat(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.primary.withOpacity(0.08)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  sel ? AppTheme.primary : Colors.grey.shade200,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: AppTheme.tajawal(
                              fontSize: 12,
                              color:
                                  sel ? AppTheme.primary : Colors.grey.shade700,
                              fontWeight:
                                  sel ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD84315), AppTheme.primary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.24),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: loading ? null : _saveInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'حفظ البيانات الشخصية',
                          style: AppTheme.tajawal(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed:
                    loading ? null : () => _showDeleteAccountDialog(context),
                icon: const Icon(Icons.delete_forever_rounded,
                    color: Colors.redAccent, size: 20),
                label: Text(
                  'حذف الحساب',
                  style: AppTheme.tajawal(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Password ─────────────────────────────────────────────
  Widget _buildPasswordTab(bool loading) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Form(
        key: _passKey,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: AppTheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'تحديث كلمة المرور',
                        style: AppTheme.tajawal(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تأكد من استخدام كلمة مرور قوية لحماية حسابك من الاختراق',
                    style: AppTheme.tajawal(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  _PLabel('كلمة المرور الحالية'),
                  _PassField(
                    controller: _curPassCtrl,
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscureCur,
                    enabled: !loading,
                    validator: (v) => v == null || v.isEmpty
                        ? 'أدخل كلمة المرور الحالية'
                        : null,
                    onToggle: () => setState(() => _obscureCur = !_obscureCur),
                  ),
                  const SizedBox(height: 16),
                  _PLabel('كلمة المرور الجديدة'),
                  _PassField(
                    controller: _newPassCtrl,
                    hint: 'على الأقل ٦ أحرف',
                    icon: Icons.lock_reset_outlined,
                    obscure: _obscureNew,
                    enabled: !loading,
                    validator: Validators.password,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: 16),
                  _PLabel('تأكيد كلمة المرور الجديدة'),
                  _PassField(
                    controller: _confPassCtrl,
                    hint: 'أعد كتابة كلمة المرور',
                    icon: Icons.check_circle_outline_rounded,
                    obscure: _obscureConf,
                    enabled: !loading,
                    validator: (v) => v != _newPassCtrl.text
                        ? 'كلمتا المرور غير متطابقَين'
                        : null,
                    onToggle: () =>
                        setState(() => _obscureConf = !_obscureConf),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD84315), AppTheme.primary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.24),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: loading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'تغيير كلمة المرور',
                          style: AppTheme.tajawal(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Local widgets ────────────────────────────────────────────────────────────

void _showSnack(BuildContext context, String msg, {required bool isError}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(
      children: [
        Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            textDirection: TextDirection.rtl,
            style: AppTheme.tajawal(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
    backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  ));
}

class _PLabel extends StatelessWidget {
  final String text;
  const _PLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(text,
            style: AppTheme.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      );
}

class _PField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool ltr;
  final bool enabled;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _PField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.ltr = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
        enabled: enabled,
        validator: validator,
        style: AppTheme.tajawal(fontSize: 14, color: Colors.black87),
        decoration: _dec(hint, icon),
      );
}

class _PassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool enabled;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PassField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.obscure,
    required this.onToggle,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        validator: validator,
        style: AppTheme.tajawal(fontSize: 14, color: Colors.black87),
        decoration: _dec(hint, icon).copyWith(
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey, size: 20),
          ),
        ),
      );
}

InputDecoration _dec(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      hintStyle: AppTheme.tajawal(color: Colors.grey.shade400, fontSize: 12),
      prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade200, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
      ),
    );

class _DropdownBox extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String hint;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const _DropdownBox({
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: Text(hint,
                style: AppTheme.tajawal(
                    color: Colors.grey.shade400, fontSize: 13)),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.grey, size: 22),
            dropdownColor: Colors.white,
            style: AppTheme.tajawal(color: Colors.black87, fontSize: 14),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      );
}
