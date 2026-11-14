import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/company_service.dart';
import '../../models/company_model.dart';
import '../login_screen.dart';
import '../onboarding/company_onboarding_screen.dart';
import '../categories/categories_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isAdmin;
  final String companyName;

  const ProfileScreen({
    super.key,
    this.isAdmin = false,
    this.companyName = '',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _companyService = CompanyService();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  Map<String, dynamic>? _profile;
  CompanyModel? _company;
  bool _loading = true;
  bool _saving = false;
  String? _saveMsg;
  bool _saveOk = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await _auth.getProfile();
    final c = await _companyService.getMyCompany();

    if (mounted) {
      setState(() {
        _profile = p;
        _company = c;
        _fullNameCtrl.text = p?['full_name'] as String? ?? '';
        _phoneCtrl.text = p?['phone'] as String? ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveMsg = null;
    });
    try {
      await _auth.supabase.from('profiles').update({
        'full_name': _fullNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      }).eq('id', _profile!['id'] as String);
      setState(() {
        _saveMsg = 'Profile updated successfully.';
        _saveOk = true;
        _saving = false;
      });
    } catch (_) {
      setState(() {
        _saveMsg = 'Could not save profile changes.';
        _saveOk = false;
        _saving = false;
      });
    }
  }

  Future<void> _leaveCompany() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Company Book'),
        content: Text(
          'Are you sure you want to unlink from "${_company?.name ?? widget.companyName}"? You will return to the company setup screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.expense),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unlink Book'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _companyService.leaveCompanyBook();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CompanyOnboardingScreen()),
      (_) => false,
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out of Company Book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.expense),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = _profile?['username'] as String? ?? 'Member';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Member Profile & Settings'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Member Avatar & Identity Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.primary,
                            child: Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : 'M',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fullNameCtrl.text.isNotEmpty
                                      ? _fullNameCtrl.text
                                      : username,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@$username',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primarySoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Sole Authorized Controller',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Profile Edit Form
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Edit Member Details',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_saveMsg != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _saveOk
                                    ? AppTheme.revenueSoft
                                    : AppTheme.expenseSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _saveMsg!,
                                style: TextStyle(
                                  color: _saveOk
                                      ? AppTheme.revenue
                                      : AppTheme.expense,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextField(
                            controller: _fullNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Full Name / Director Name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Details'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Ledger Categories Management
                    ListTile(
                      tileColor: AppTheme.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppTheme.divider),
                      ),
                      leading: const Icon(Icons.category_rounded,
                          color: AppTheme.primary),
                      title: const Text(
                        'Manage Ledger Categories',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Customize your revenue and expense categories',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        if (_company?.id != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CategoriesScreen(
                                companyId: _company!.id,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Danger Zone / Book Actions
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Account & Book Actions',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: _leaveCompany,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.expense),
                              foregroundColor: AppTheme.expense,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.link_off_rounded, size: 18),
                            label: const Text('Unlink This Company Book'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _signOut,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Company Book v1.0.0 • Single-Member Financial Ledger',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
