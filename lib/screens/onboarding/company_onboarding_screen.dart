import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/company_service.dart';
import '../../services/auth_service.dart';
import '../shell_screen.dart';
import '../login_screen.dart';

class CompanyOnboardingScreen extends StatefulWidget {
  const CompanyOnboardingScreen({super.key});

  @override
  State<CompanyOnboardingScreen> createState() => _CompanyOnboardingScreenState();
}

class _CompanyOnboardingScreenState extends State<CompanyOnboardingScreen> {
  final _companyService = CompanyService();
  final _authService = AuthService();

  final _companyNameCtrl = TextEditingController();
  final _companyCodeCtrl = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  bool _showCodeEntry = false;

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _companyCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreateCompany() async {
    final name = _companyNameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your company or business name');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _companyService.createCompanyBook(name);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ShellScreen(isAdmin: false)),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create Company Book. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _handleEnterByCode() async {
    final code = _companyCodeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a company book code');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _companyService.enterCompanyByCode(code);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ShellScreen(isAdmin: false)),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
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
        title: const Text('Company Book Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Banner
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.domain_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Establish Company Book',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Set up your corporate financial ledger. Each Company Book allows strictly ONE member to enter and manage transactions.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_person_outlined,
                                  size: 15, color: AppTheme.gold),
                              SizedBox(width: 6),
                              Text(
                                'Strict Single-Member Entry Policy Active',
                                style: TextStyle(
                                  color: AppTheme.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.expenseSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.expense.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppTheme.expense, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.expense,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Main Setup Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Company Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter your business name to open the company ledger.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _companyNameCtrl,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleCreateCompany(),
                          decoration: const InputDecoration(
                            labelText: 'Company / Trade Name *',
                            hintText: 'e.g. Acme Technologies Ltd',
                            prefixIcon: Icon(Icons.business_rounded),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _handleCreateCompany,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline_rounded),
                          label: Text(_loading
                              ? 'Initializing...'
                              : 'Create & Enter Company Book'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Collapsible Code Entry with 1-Member Guard
                  Center(
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _showCodeEntry = !_showCodeEntry),
                      icon: Icon(
                        _showCodeEntry
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.vpn_key_outlined,
                        size: 18,
                      ),
                      label: Text(_showCodeEntry
                          ? 'Hide Book Code Entry'
                          : 'Have an existing Company Book Code?'),
                    ),
                  ),

                  if (_showCodeEntry) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shield_outlined,
                                  size: 18, color: AppTheme.gold),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Single-Member Validation Rule',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.gold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'If another member has already entered this company book, your request will be rejected. Only 1 member is admitted per book.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _companyCodeCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Company Book Code',
                              hintText: 'e.g. CORP-XXXXXX',
                              prefixIcon: Icon(Icons.key_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: _loading ? null : _handleEnterByCode,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Verify & Enter Company Book',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
