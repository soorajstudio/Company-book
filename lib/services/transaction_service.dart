import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final _supabase = Supabase.instance.client;

  Future<List<TransactionModel>> getTransactions({
    required String companyId,
    DateTime? fromDate,
    DateTime? toDate,
    String? type, // 'income' | 'expense' | null = all
    String? categoryId,
    int limit = 200,
  }) async {
    try {
      var query = _supabase
          .from('transactions')
          .select('*, categories(name, color, icon_name)')
          .eq('family_id', companyId);

      if (type != null) query = query.eq('type', type);
      if (categoryId != null) query = query.eq('category_id', categoryId);
      if (fromDate != null) {
        query = query.gte('date', _dateStr(fromDate));
      }
      if (toDate != null) {
        query = query.lte('date', _dateStr(toDate));
      }

      final result = await query.order('date', ascending: false).limit(limit);
      final rawList = List<Map<String, dynamic>>.from(result as List);
      return await _enrichTransactions(rawList);
    } catch (e) {
      // Fallback if join syntax fails
      try {
        var query = _supabase
            .from('transactions')
            .select()
            .eq('family_id', companyId);

        if (type != null) query = query.eq('type', type);
        if (categoryId != null) query = query.eq('category_id', categoryId);
        if (fromDate != null) {
          query = query.gte('date', _dateStr(fromDate));
        }
        if (toDate != null) {
          query = query.lte('date', _dateStr(toDate));
        }

        final result = await query.order('date', ascending: false).limit(limit);
        final rawList = List<Map<String, dynamic>>.from(result as List);
        return await _enrichTransactions(rawList);
      } catch (_) {
        return [];
      }
    }
  }

  Future<List<TransactionModel>> _enrichTransactions(
      List<Map<String, dynamic>> rawList) async {
    final missingUserIds = <String>{};
    final missingCategoryIds = <String>{};

    for (final map in rawList) {
      final prof = map['profiles'] as Map<String, dynamic>?;
      final uid = map['user_id'] as String?;
      if ((prof == null ||
              (prof['username'] == null && prof['full_name'] == null)) &&
          uid != null &&
          uid.isNotEmpty) {
        missingUserIds.add(uid);
      }

      final cat = map['categories'] as Map<String, dynamic>?;
      final catId = map['category_id'] as String?;
      if (cat == null && catId != null && catId.isNotEmpty) {
        missingCategoryIds.add(catId);
      }
    }

    final profMap = <String, Map<String, dynamic>>{};
    if (missingUserIds.isNotEmpty) {
      try {
        final profilesRes = await _supabase
            .from('profiles')
            .select('id, username, full_name')
            .filter('id', 'in', missingUserIds.toList());
        for (final p in (profilesRes as List)) {
          final pMap = p as Map<String, dynamic>;
          final id = pMap['id'] as String?;
          if (id != null) profMap[id] = pMap;
        }
      } catch (_) {}
    }

    final catMap = <String, Map<String, dynamic>>{};
    if (missingCategoryIds.isNotEmpty) {
      try {
        final catsRes = await _supabase
            .from('categories')
            .select('id, name, color, icon_name')
            .filter('id', 'in', missingCategoryIds.toList());
        for (final c in (catsRes as List)) {
          final cMap = c as Map<String, dynamic>;
          final id = cMap['id'] as String?;
          if (id != null) catMap[id] = cMap;
        }
      } catch (_) {}
    }

    return rawList.map((m) {
      final copy = Map<String, dynamic>.from(m);
      final uid = copy['user_id'] as String?;
      final cid = copy['category_id'] as String?;

      if (copy['profiles'] == null && uid != null && profMap.containsKey(uid)) {
        copy['profiles'] = profMap[uid];
      }
      if (copy['categories'] == null && cid != null && catMap.containsKey(cid)) {
        copy['categories'] = catMap[cid];
      }

      return TransactionModel.fromMap(copy);
    }).toList();
  }

  Future<TransactionModel> addTransaction({
    required String companyId,
    required String type,
    required double amount,
    required String? categoryId,
    String? description,
    required DateTime date,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final result = await _supabase
        .from('transactions')
        .insert({
          'family_id': companyId,
          'user_id': userId,
          'type': type,
          'amount': amount,
          'category_id': categoryId,
          'description': description?.trim(),
          'date': _dateStr(date),
        })
        .select()
        .single();

    final raw = Map<String, dynamic>.from(result);
    final enriched = await _enrichTransactions([raw]);
    return enriched.first;
  }

  Future<void> updateTransaction({
    required String id,
    required String type,
    required double amount,
    required String? categoryId,
    String? description,
    required DateTime date,
  }) async {
    await _supabase.from('transactions').update({
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'description': description?.trim(),
      'date': _dateStr(date),
    }).eq('id', id);
  }

  Future<void> deleteTransaction(String id) async {
    await _supabase.from('transactions').delete().eq('id', id);
  }

  Future<double> getTotalIncome(
      String companyId, DateTime fromDate, DateTime toDate) async {
    final txns = await getTransactions(
      companyId: companyId,
      fromDate: fromDate,
      toDate: toDate,
      type: 'income',
      limit: 1000,
    );
    return txns.fold<double>(0.0, (double sum, TransactionModel t) => sum + t.amount);
  }

  Future<double> getTotalExpense(
      String companyId, DateTime fromDate, DateTime toDate) async {
    final txns = await getTransactions(
      companyId: companyId,
      fromDate: fromDate,
      toDate: toDate,
      type: 'expense',
      limit: 1000,
    );
    return txns.fold<double>(0.0, (double sum, TransactionModel t) => sum + t.amount);
  }

  Future<List<TransactionModel>> getRecentTransactions(
      String companyId, int limit) async {
    return getTransactions(companyId: companyId, limit: limit);
  }

  Future<Map<String, double>> getExpenseByCategory({
    required String companyId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final txns = await getTransactions(
      companyId: companyId,
      fromDate: fromDate,
      toDate: toDate,
      type: 'expense',
      limit: 1000,
    );

    final Map<String, double> map = {};
    for (final t in txns) {
      final name = t.displayCategory;
      map[name] = (map[name] ?? 0.0) + t.amount;
    }
    return map;
  }

  Future<List<Map<String, double>>> getMonthlySummary(
      String companyId, int months) async {
    final now = DateTime.now();
    final List<Map<String, double>> list = [];

    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final firstDay = DateTime(date.year, date.month, 1);
      final lastDay = DateTime(date.year, date.month + 1, 0);

      final inc = await getTotalIncome(companyId, firstDay, lastDay);
      final exp = await getTotalExpense(companyId, firstDay, lastDay);

      list.add({'income': inc, 'expense': exp});
    }
    return list;
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
