import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/company_service.dart';
import 'dashboard/dashboard_screen.dart';
import 'transactions/transactions_screen.dart';
import 'reports/reports_screen.dart';
import 'company/company_screen.dart';
import 'onboarding/company_onboarding_screen.dart';

class ShellScreen extends StatefulWidget {
  final bool isAdmin;
  const ShellScreen({super.key, this.isAdmin = false});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;
  String? _companyId;
  String _companyName = 'Company Book';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    try {
      final cs = CompanyService();
      final comp = await cs.getMyCompany();
      if (mounted) {
        if (comp == null) {
          // No company linked, redirect to onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CompanyOnboardingScreen()),
          );
          return;
        }
        setState(() {
          _companyId = comp.id;
          _companyName = comp.name;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Widget> get _pages {
    if (_companyId == null) {
      return [
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
        const Center(child: CircularProgressIndicator()),
      ];
    }
    return [
      DashboardScreen(
        companyId: _companyId!,
        companyName: _companyName,
        isAdmin: widget.isAdmin,
      ),
      TransactionsScreen(companyId: _companyId!),
      ReportsScreen(companyId: _companyId!, companyName: _companyName),
      CompanyScreen(
        companyId: _companyId!,
        companyName: _companyName,
        isAdmin: widget.isAdmin,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        height: 68,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Ledger',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.domain_outlined),
            selectedIcon: Icon(Icons.domain_rounded),
            label: 'Company',
          ),
        ],
      ),
    );
  }
}
