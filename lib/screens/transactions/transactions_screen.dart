import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/transaction_service.dart';
import '../../models/transaction_model.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final String companyId;
  final bool canAdd;

  const TransactionsScreen({
    super.key,
    required this.companyId,
    this.canAdd = true,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _txnService = TransactionService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _searchCtrl = TextEditingController();

  List<TransactionModel> _all = [];
  List<TransactionModel> _filtered = [];
  String _typeFilter = 'all'; // all | income | expense
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final txns = await _txnService.getTransactions(
          companyId: widget.companyId, limit: 500);
      if (mounted) {
        setState(() {
          _all = txns;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((t) {
        final matchType = _typeFilter == 'all' || t.type == _typeFilter;
        final matchSearch = query.isEmpty ||
            (t.displayCategory.toLowerCase().contains(query)) ||
            (t.description?.toLowerCase().contains(query) ?? false) ||
            (t.recordedByTitle.toLowerCase().contains(query));
        return matchType && matchSearch;
      }).toList();
    });
  }

  Future<void> _delete(TransactionModel t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Company Entry'),
        content: Text(
          'Are you sure you want to remove this ${t.isIncome ? "revenue" : "expense"} entry of ${_currency.format(t.amount)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.expense),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _txnService.deleteTransaction(t.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalFiltered = _filtered.fold(
      0.0,
      (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Company Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh entries',
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: widget.canAdd
          ? FloatingActionButton.extended(
              onPressed: () async {
                final res = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) =>
                        AddTransactionScreen(companyId: widget.companyId),
                  ),
                );
                if (res == true) _load();
              },
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Entry'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: AppTheme.background,
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => _applyFilter(),
                    decoration: InputDecoration(
                      hintText: 'Search ledger (invoice #, category, note)...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _applyFilter();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('all', 'All Entries (${_all.length})'),
                        const SizedBox(width: 8),
                        _filterChip('income', 'Revenue'),
                        const SizedBox(width: 8),
                        _filterChip('expense', 'Expenses'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Summary Sub-header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppTheme.card,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filtered.length} entries found',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Net: ${_currency.format(totalFiltered)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: totalFiltered >= 0
                          ? AppTheme.revenue
                          : AppTheme.expense,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.divider),

            // Entry List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long_outlined,
                                  size: 48, color: AppTheme.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No company entries match criteria.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              if (widget.canAdd) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final res =
                                        await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => AddTransactionScreen(
                                            companyId: widget.companyId),
                                      ),
                                    );
                                    if (res == true) _load();
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Entry'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppTheme.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final t = _filtered[i];
                              final isInc = t.isIncome;
                              return Dismissible(
                                key: Key(t.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.expense,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_outline_rounded,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (_) async {
                                  _delete(t);
                                  return false;
                                },
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    final edited =
                                        await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => AddTransactionScreen(
                                          companyId: widget.companyId,
                                          editTransaction: t,
                                        ),
                                      ),
                                    );
                                    if (edited == true) _load();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.card,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppTheme.divider),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isInc
                                              ? AppTheme.revenueSoft
                                              : AppTheme.expenseSoft,
                                          child: Icon(
                                            isInc
                                                ? Icons.arrow_downward_rounded
                                                : Icons.arrow_upward_rounded,
                                            color: isInc
                                                ? AppTheme.revenue
                                                : AppTheme.expense,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t.displayCategory,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                t.description?.isNotEmpty ==
                                                        true
                                                    ? t.description!
                                                    : 'No notes provided',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${DateFormat('dd MMM yyyy').format(t.date)} • Sole Member Entry',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${isInc ? '+' : '-'} ${_currency.format(t.amount)}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: isInc
                                                ? AppTheme.revenue
                                                : AppTheme.expense,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures()
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _typeFilter == value;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() => _typeFilter = value);
        _applyFilter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
