import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company_model.dart';

class CompanyService {
  final _supabase = Supabase.instance.client;

  // Pre-configured corporate finance categories
  static const List<Map<String, String>> defaultCategories = [
    // Income / Revenue
    {
      'name': 'Client Invoices & Fees',
      'type': 'income',
      'color': '#059669',
      'icon': 'payments',
    },
    {
      'name': 'Product & Sales Revenue',
      'type': 'income',
      'color': '#10B981',
      'icon': 'storefront',
    },
    {
      'name': 'Consulting & Services',
      'type': 'income',
      'color': '#0284C7',
      'icon': 'work',
    },
    {
      'name': 'Recurring Retainers',
      'type': 'income',
      'color': '#6366F1',
      'icon': 'autorenew',
    },
    {
      'name': 'Investment & Interest',
      'type': 'income',
      'color': '#8B5CF6',
      'icon': 'trending_up',
    },
    {
      'name': 'Other Revenue',
      'type': 'income',
      'color': '#14B8A6',
      'icon': 'account_balance_wallet',
    },
    // Expense / Outflow
    {
      'name': 'Payroll & Salaries',
      'type': 'expense',
      'color': '#DC2626',
      'icon': 'people',
    },
    {
      'name': 'Office Rent & Facilities',
      'type': 'expense',
      'color': '#EA580C',
      'icon': 'business',
    },
    {
      'name': 'SaaS & Cloud Services',
      'type': 'expense',
      'color': '#2563EB',
      'icon': 'cloud',
    },
    {
      'name': 'Marketing & Advertising',
      'type': 'expense',
      'color': '#D97706',
      'icon': 'campaign',
    },
    {
      'name': 'Equipment & Hardware',
      'type': 'expense',
      'color': '#4B5563',
      'icon': 'computer',
    },
    {
      'name': 'Travel & Business Hospitality',
      'type': 'expense',
      'color': '#0D9488',
      'icon': 'flight',
    },
    {
      'name': 'Legal, Audit & Taxes',
      'type': 'expense',
      'color': '#7C3AED',
      'icon': 'gavel',
    },
    {
      'name': 'Utilities & Communication',
      'type': 'expense',
      'color': '#CA8A04',
      'icon': 'bolt',
    },
    {
      'name': 'Office Supplies',
      'type': 'expense',
      'color': '#0891B2',
      'icon': 'inventory',
    },
    {
      'name': 'Operating Expenses',
      'type': 'expense',
      'color': '#64748B',
      'icon': 'receipt',
    },
  ];

  /// Creates a new Company Book with strict single-member ownership.
  /// The creator is registered as the sole authorized member.
  Future<CompanyModel> createCompanyBook(
    String companyName, {
    String businessType = 'Corporation',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Generate unique corporate book code
    final code = 'CORP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    Map<String, dynamic>? companyResult;

    try {
      companyResult = await _supabase
          .from('families')
          .insert({
            'name': companyName.trim(),
            'created_by': userId,
            'invite_code': code,
          })
          .select()
          .single();
    } catch (_) {
      companyResult = await _supabase
          .from('families')
          .insert({
            'name': companyName.trim(),
            'created_by': userId,
          })
          .select()
          .single();
    }

    final company = CompanyModel.fromMap(companyResult);

    // Link current user as the sole authorized member and admin of this company book
    await _supabase.from('profiles').update({
      'family_id': company.id,
      'is_admin': true,
    }).eq('id', userId);

    // Seed default corporate ledger categories
    final cats = defaultCategories.map((c) => {
          'family_id': company.id,
          'name': c['name']!,
          'type': c['type']!,
          'color': c['color']!,
          'icon_name': c['icon']!,
          'created_by': userId,
        }).toList();

    try {
      await _supabase.from('categories').insert(cats);
    } catch (_) {}

    return company;
  }

  /// Strictly checks if a user is permitted to enter the company book.
  /// RULE: Only ONE member can enter and manage a Company Book.
  Future<bool> canEnterCompanyBook(String companyId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    // Check profiles assigned to this company
    final result = await _supabase
        .from('profiles')
        .select('id, family_id')
        .eq('family_id', companyId);

    final members = (result as List);

    // If company already has members:
    // Only the single registered member is allowed to enter!
    if (members.isNotEmpty) {
      final isExistingMember = members.any((m) => m['id'] == currentUserId);
      if (!isExistingMember) {
        // Reject! Single-member restriction reached
        return false;
      }
      return true;
    }

    // If company is empty, creator can enter
    return true;
  }

  /// Attempts to enter an existing company book by code with strict 1-member enforcement.
  /// Throws error if another member already occupies the company book.
  Future<CompanyModel> enterCompanyByCode(String code) async {
    final cleanCode = code.trim().toUpperCase().replaceAll(' ', '');
    if (cleanCode.isEmpty) {
      throw Exception('Please enter a valid company book code.');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated.');

    // Look up company
    Map<String, dynamic>? match;
    try {
      final res = await _supabase
          .from('families')
          .select()
          .eq('invite_code', cleanCode)
          .maybeSingle();
      if (res != null) match = res;
    } catch (_) {}

    if (match == null) {
      final all = await _supabase.from('families').select();
      for (final f in (all as List)) {
        final id = (f['id'] as String).replaceAll('-', '').toUpperCase();
        if (id.startsWith(cleanCode)) {
          match = f as Map<String, dynamic>;
          break;
        }
      }
    }

    if (match == null) {
      throw Exception('Company Book not found with code "$cleanCode".');
    }

    final companyId = match['id'] as String;

    // Check member count for this company book
    final membersRes = await _supabase
        .from('profiles')
        .select('id, username')
        .eq('family_id', companyId);

    final members = List<Map<String, dynamic>>.from(membersRes as List);

    if (members.isNotEmpty) {
      final alreadyIn = members.any((m) => m['id'] == userId);
      if (!alreadyIn) {
        // Enforce the constraint: ONLY ONE MEMBER CAN ENTER IN THE COMPANY BOOK!
        throw Exception(
          'Access Denied: This Company Book is strictly limited to 1 member only. Another member is already registered in this book.',
        );
      }
    }

    // Assign user to this company book
    await _supabase.from('profiles').update({
      'family_id': companyId,
      'is_admin': true,
    }).eq('id', userId);

    return CompanyModel.fromMap(match);
  }

  /// Fetches the user's active Company Book
  Future<CompanyModel?> getMyCompany() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final profileRes = await _supabase
        .from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();

    final companyId = profileRes?['family_id'] as String?;
    if (companyId == null || companyId.isEmpty) return null;

    final companyRes = await _supabase
        .from('families')
        .select()
        .eq('id', companyId)
        .maybeSingle();

    if (companyRes == null) return null;
    return CompanyModel.fromMap(companyRes);
  }

  /// Fetches the sole member of this company book
  Future<CompanyMemberModel?> getSoleMember() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final company = await getMyCompany();
    if (company == null) return null;

    final result = await _supabase
        .from('profiles')
        .select()
        .eq('family_id', company.id)
        .limit(1)
        .maybeSingle();

    if (result == null) return null;
    return CompanyMemberModel.fromMap(result);
  }

  /// Close or unlink company book
  Future<void> leaveCompanyBook() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('profiles').update({
      'family_id': null,
      'is_admin': false,
    }).eq('id', userId);
  }

  /// Update company name
  Future<void> updateCompanyName(String companyId, String newName) async {
    await _supabase
        .from('families')
        .update({'name': newName.trim()})
        .eq('id', companyId);
  }
}
