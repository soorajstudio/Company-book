import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/company_service.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';
import '../../models/company_model.dart';
import '../login_screen.dart';
import '../shell_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;
  final _companyService = CompanyService();
  final _txnService = TransactionService();
  final _auth = AuthService();
  final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  int _totalUsers = 0;
  int _totalTransactions = 0;
  double _monthIncome = 0;
  double _monthExpense = 0;
  bool _loading = true;

  CompanyModel? _company;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final comp = await _companyService.getMyCompany();

      int usersCount = 0;
      int txnCount = 0;
      double income = 0;
      double expense = 0;

      if (comp != null) {
        final users = await _supabase
            .from('profiles')
            .select('id')
            .eq('family_id', comp.id);
        usersCount = (users as List).length;

        final now = DateTime.now();
        final firstDay = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0);

        income = await _txnService.getTotalIncome(comp.id, firstDay, lastDay);
        expense = await _txnService.getTotalExpense(comp.id, firstDay, lastDay);

        final transactions = await _supabase
            .from('transactions')
            .select('id')
            .eq('family_id', comp.id);
        txnCount = (transactions as List).length;
      }

      if (mounted) {
        setState(() {
          _company = comp;
          _totalUsers = usersCount;
          _totalTransactions = txnCount;
          _monthIncome = income;
          _monthExpense = expense;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch to Standard App View',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (_) => const ShellScreen(isAdmin: true)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: AppTheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Admin Header Banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.ink, AppTheme.inkElevated],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.admin_panel_settings_rounded,
                                    color: AppTheme.gold, size: 24),
                                SizedBox(width: 10),
                                Text(
                                  'System Administrator Mode',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Target Company Book: ${_company?.name ?? "None"}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Enforcing: 1 Member Entry Restriction Per Book',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.gold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Metrics Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _statCard(
                            'REGISTERED MEMBERS',
                            '$_totalUsers',
                            Icons.person_rounded,
                            AppTheme.primary,
                          ),
                          _statCard(
                            'TOTAL ENTRIES',
                            '$_totalTransactions',
                            Icons.receipt_rounded,
                            AppTheme.gold,
                          ),
                          _statCard(
                            'MONTH REVENUE',
                            _currency.format(_monthIncome),
                            Icons.trending_up_rounded,
                            AppTheme.revenue,
                          ),
                          _statCard(
                            'MONTH EXPENSE',
                            _currency.format(_monthExpense),
                            Icons.trending_down_rounded,
                            AppTheme.expense,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Quick action to standard UI
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ShellScreen(isAdmin: true)),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded,
                            color: AppTheme.primary),
                        label: const Text(
                          'Open Sole Member Company Dashboard',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
