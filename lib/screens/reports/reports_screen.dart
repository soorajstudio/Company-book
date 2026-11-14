import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../theme/app_theme.dart';
import '../../services/transaction_service.dart';
import '../../services/pdf_service.dart';
import '../../models/transaction_model.dart';

class ReportsScreen extends StatefulWidget {
  final String companyId;
  final String companyName;

  const ReportsScreen({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _txnService = TransactionService();
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  String _period = 'this_month';
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();
  double _revenue = 0;
  double _expense = 0;
  Map<String, double> _catBreakdown = {};
  List<TransactionModel> _transactions = [];
  bool _loading = true;
  bool _pdfLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _setPeriod(String p) {
    final now = DateTime.now();
    setState(() {
      _period = p;
      if (p == 'this_month') {
        _fromDate = DateTime(now.year, now.month, 1);
        _toDate = now;
      } else if (p == 'last_month') {
        _fromDate = DateTime(now.year, now.month - 1, 1);
        _toDate = DateTime(now.year, now.month, 0);
      } else if (p == 'ytd') {
        _fromDate = DateTime(now.year, 1, 1);
        _toDate = now;
      }
    });
    if (p != 'custom') _load();
  }

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );

    if (range != null) {
      setState(() {
        _fromDate = range.start;
        _toDate = range.end;
        _period = 'custom';
      });
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final txns = await _txnService.getTransactions(
        companyId: widget.companyId,
        fromDate: _fromDate,
        toDate: _toDate,
        limit: 1000,
      );

      double rev = 0;
      double exp = 0;
      final Map<String, double> cats = {};

      for (final t in txns) {
        if (t.isIncome) {
          rev += t.amount;
        } else {
          exp += t.amount;
          final cat = t.displayCategory;
          cats[cat] = (cats[cat] ?? 0.0) + t.amount;
        }
      }

      if (mounted) {
        setState(() {
          _transactions = txns;
          _revenue = rev;
          _expense = exp;
          _catBreakdown = cats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generatePdf() async {
    setState(() => _pdfLoading = true);
    try {
      final bytes = await PdfService.generateCompanyReport(
        companyName: widget.companyName,
        fromDate: _fromDate,
        toDate: _toDate,
        transactions: _transactions,
      );

      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name:
            '${widget.companyName}_Financial_Report_${DateFormat('yyyyMMdd').format(_fromDate)}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final netProfit = _revenue - _expense;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          IconButton(
            icon: _pdfLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export Financial PDF',
            onPressed: _loading || _pdfLoading ? null : _generatePdf,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _periodChip('this_month', 'This Month'),
                    const SizedBox(width: 8),
                    _periodChip('last_month', 'Last Month'),
                    const SizedBox(width: 8),
                    _periodChip('ytd', 'Year to Date'),
                    const SizedBox(width: 8),
                    _periodChip('custom', 'Custom Range', onTap: _pickCustomRange),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Date Range Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_rounded,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      '${dateFormat.format(_fromDate)} — ${dateFormat.format(_toDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              else ...[
                // P&L Summary Cards
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'STATEMENT SUMMARY',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            '${_transactions.length} entries',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statCol('REVENUE', _revenue, AppTheme.revenueSoft),
                          Container(
                              height: 36, width: 1, color: Colors.white24),
                          _statCol('EXPENSES', _expense, AppTheme.expenseSoft),
                          Container(
                              height: 36, width: 1, color: Colors.white24),
                          _statCol(
                            'NET PROFIT',
                            netProfit,
                            netProfit >= 0
                                ? const Color(0xFF34D399)
                                : const Color(0xFFF87171),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // PDF Export Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Generate Official Report',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Includes P&L statement, category breakdown & itemized ledger.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _pdfLoading ? null : _generatePdf,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                        ),
                        child: const Text('Export'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Expense Breakdown List
                const Text(
                  'Expense Category Allocation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                if (_catBreakdown.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: const Center(
                      child: Text(
                        'No expenses recorded in this period.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      children: _catBreakdown.entries.map((entry) {
                        final pct = _expense > 0
                            ? (entry.value / _expense * 100).toStringAsFixed(1)
                            : '0.0';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _currency.format(entry.value),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 44,
                                child: Text(
                                  '$pct%',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCol(String title, double val, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _currency.format(val),
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodChip(String id, String label, {VoidCallback? onTap}) {
    final selected = _period == id;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap ?? () => _setPeriod(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
