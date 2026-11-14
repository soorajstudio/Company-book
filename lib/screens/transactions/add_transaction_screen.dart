import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/transaction_service.dart';
import '../../services/category_service.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../categories/categories_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final String companyId;
  final TransactionModel? editTransaction;

  const AddTransactionScreen({
    super.key,
    required this.companyId,
    this.editTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _txnService = TransactionService();
  final _catService = CategoryService();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _type = 'expense';
  DateTime _date = DateTime.now();
  String? _categoryId;
  List<CategoryModel> _categories = [];
  bool _loading = false;
  bool _catLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.editTransaction?.type ?? 'expense';

    if (widget.editTransaction != null) {
      final e = widget.editTransaction!;
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _descCtrl.text = e.description ?? '';
      _date = e.date;
      _categoryId = e.categoryId;
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _switchType(String type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      _categoryId = null;
    });
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _catLoading = true);
    try {
      final cats =
          await _catService.getCategoriesByType(widget.companyId, _type);
      if (mounted) {
        setState(() {
          _categories = cats;
          if (_categoryId != null && !cats.any((c) => c.id == _categoryId)) {
            _categoryId = null;
          }
          if (_categoryId == null && cats.isNotEmpty) {
            _categoryId = cats.first.id;
          }
          _catLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _catLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit() async {
    final text = _amountCtrl.text.trim().replaceAll(',', '');
    final amount = double.tryParse(text);

    if (amount == null || amount <= 0) {
      setState(() => _error = 'Please enter a valid amount greater than 0');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.editTransaction != null) {
        await _txnService.updateTransaction(
          id: widget.editTransaction!.id,
          type: _type,
          amount: amount,
          categoryId: _categoryId,
          description: _descCtrl.text.trim(),
          date: _date,
        );
      } else {
        await _txnService.addTransaction(
          companyId: widget.companyId,
          type: _type,
          amount: amount,
          categoryId: _categoryId,
          description: _descCtrl.text.trim(),
          date: _date,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'Failed to save entry. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editTransaction != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Company Entry' : 'New Company Entry'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sole Member Ledger Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded,
                          size: 18, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Authorized Entry: Stamped and recorded by Sole Member',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Revenue vs Expense Switcher
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _typeTab(
                          label: 'Revenue / Inflow',
                          active: _type == 'income',
                          activeColor: AppTheme.revenue,
                          onTap: () => _switchType('income'),
                        ),
                      ),
                      Expanded(
                        child: _typeTab(
                          label: 'Expense / Outflow',
                          active: _type == 'expense',
                          activeColor: AppTheme.expense,
                          onTap: () => _switchType('expense'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.expenseSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          color: AppTheme.expense, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Amount Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amount (₹)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          prefixIcon: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            child: Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          prefixIconConstraints:
                              BoxConstraints(minWidth: 0, minHeight: 0),
                          hintText: '0.00',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Category Selector
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Corporate Category',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CategoriesScreen(
                                    companyId: widget.companyId,
                                  ),
                                ),
                              );
                              _loadCategories();
                            },
                            child: const Text(
                              '+ Manage Categories',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_catLoading)
                        const SizedBox(
                          height: 48,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_categories.isEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'No categories found.',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            TextButton(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CategoriesScreen(
                                      companyId: widget.companyId,
                                    ),
                                  ),
                                );
                                _loadCategories();
                              },
                              child: const Text('Add Category'),
                            ),
                          ],
                        )
                      else
                        DropdownButtonFormField<String>(
                          key: ValueKey('$_type-$_categoryId'),
                          initialValue: _categoryId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          items: _categories.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _parseColor(c.color),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      c.name,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _categoryId = val);
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Date & Description Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Entry Date',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.divider),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMMM yyyy').format(_date),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Icon(Icons.calendar_month_rounded,
                                  size: 18, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Invoice Ref / Description / Notes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. Inv #4092 - Client retainer payment for Nov',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing
                          ? 'Update Company Entry'
                          : 'Save Company Entry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeTab({
    required String label,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppTheme.primary;
    }
  }
}
