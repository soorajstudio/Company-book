import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/onboarding/company_onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/company_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const CompanyBookApp());
}

class CompanyBookApp extends StatelessWidget {
  const CompanyBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Company Book',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashDecider(),
    );
  }
}

class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;

    if (session == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    String? companyId;
    try {
      final profile = await AuthService().getProfile();
      companyId = profile?['family_id'] as String?;
    } catch (_) {}

    if (!mounted) return;

    // If user has not set up a company book yet, route to onboarding
    if (companyId == null || companyId.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CompanyOnboardingScreen()),
      );
      return;
    }

    // Verify Single-Member Access:
    // Only 1 member can enter in the company book
    try {
      final canEnter = await CompanyService().canEnterCompanyBook(companyId);
      if (!canEnter) {
        // Current user is not authorized into this company book
        await CompanyService().leaveCompanyBook();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Access Restricted: Only 1 member is permitted per Company Book. Redirected to Setup.',
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CompanyOnboardingScreen()),
        );
        return;
      }
    } catch (_) {}

    if (!mounted) return;

    // Every logged-in member enters the main Company Book interface
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ShellScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.domain_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Company Book',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Single-Member Financial Ledger',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
