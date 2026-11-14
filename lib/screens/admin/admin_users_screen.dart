import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/company_service.dart';
import '../../models/company_model.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _supabase = Supabase.instance.client;
  final _companyService = CompanyService();

  CompanyMemberModel? _soleMember;
  List<Map<String, dynamic>> _loginSessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final member = await _companyService.getSoleMember();

      final sessionsRes = await _supabase
          .from('login_sessions')
          .select()
          .order('logged_in_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _soleMember = member;
          _loginSessions = List<Map<String, dynamic>>.from(sessionsRes as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Member & Device Access'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
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
                      // Single-Member Enforcement Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                color: AppTheme.primary, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Single-Member Book Enforcement',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Only one member is permitted to enter in this company book. No auxiliary members can join.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Sole Member Card
                      const Text(
                        'Registered Sole Member',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_soleMember == null)
                        const Text('No member currently registered.',
                            style: TextStyle(color: AppTheme.textSecondary))
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primarySoft,
                                child: Text(
                                  _soleMember!.initials,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _soleMember!.displayName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '@${_soleMember!.username} • Sole Controller',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    if (_soleMember!.phone != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Phone: ${_soleMember!.phone}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.revenueSoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ACTIVE (1/1)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.revenue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Device Access & Sessions Log
                      const Text(
                        'Recent Access Sessions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_loginSessions.isEmpty)
                        const Text('No recent sessions recorded.',
                            style: TextStyle(color: AppTheme.textSecondary))
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _loginSessions.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: AppTheme.divider),
                            itemBuilder: (ctx, i) {
                              final s = _loginSessions[i];
                              final device =
                                  s['device_info'] as String? ?? 'Device';
                              final active =
                                  s['is_active'] as bool? ?? false;
                              final inTime = s['logged_in_at'] != null
                                  ? DateTime.tryParse(s['logged_in_at'])
                                  : null;

                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: active
                                      ? AppTheme.revenueSoft
                                      : AppTheme.surfaceRecessed,
                                  child: Icon(
                                    Icons.devices_rounded,
                                    size: 16,
                                    color: active
                                        ? AppTheme.revenue
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                title: Text(
                                  device,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  inTime != null
                                      ? dateFormat.format(inTime)
                                      : 'Recently',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppTheme.revenueSoft
                                        : AppTheme.surfaceRecessed,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    active ? 'ONLINE' : 'CLOSED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: active
                                          ? AppTheme.revenue
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
