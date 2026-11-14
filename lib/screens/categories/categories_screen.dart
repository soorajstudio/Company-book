import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/category_service.dart';
import '../../models/category_model.dart';

class CategoriesScreen extends StatefulWidget {
  final String companyId;

  const CategoriesScreen({super.key, required this.companyId});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  final _catService = CategoryService();
  late TabController _tabController;

  List<CategoryModel> _income = [];
  List<CategoryModel> _expense = [];
  bool _loading = true;

  static const List<Color> _colorOptions = [
    Color(0xFF059669),
    Color(0xFF10B981),
    Color(0xFF4F46E5),
    Color(0xFF6366F1),
    Color(0xFF2563EB),
    Color(0xFF0284C7),
    Color(0xFFD97706),
    Color(0xFFDC2626),
    Color(0xFF7C3AED),
    Color(0xFF4B5563),
    Color(0xFF0D9488),
    Color(0xFFCA8A04),
  ];

  static const List<Map<String, dynamic>> _iconOptions = [
    {'name': 'payments', 'icon': Icons.payments_outlined},
    {'name': 'storefront', 'icon': Icons.storefront_outlined},
    {'name': 'work', 'icon': Icons.work_outline_rounded},
    {'name': 'autorenew', 'icon': Icons.autorenew_rounded},
    {'name': 'trending_up', 'icon': Icons.trending_up_rounded},
    {'name': 'account_balance_wallet', 'icon': Icons.account_balance_wallet_outlined},
    {'name': 'people', 'icon': Icons.people_outline_rounded},
    {'name': 'business', 'icon': Icons.business_rounded},
    {'name': 'cloud', 'icon': Icons.cloud_outlined},
    {'name': 'campaign', 'icon': Icons.campaign_outlined},
    {'name': 'computer', 'icon': Icons.computer_outlined},
    {'name': 'flight', 'icon': Icons.flight_outlined},
    {'name': 'gavel', 'icon': Icons.gavel_outlined},
    {'name': 'bolt', 'icon': Icons.bolt_outlined},
    {'name': 'inventory', 'icon': Icons.inventory_2_outlined},
    {'name': 'receipt', 'icon': Icons.receipt_long_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final inc = await _catService.getCategoriesByType(widget.companyId, 'income');
      final exp = await _catService.getCategoriesByType(widget.companyId, 'expense');
      if (mounted) {
        setState(() {
          _income = inc;
          _expense = exp;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddEditDialog([CategoryModel? existing]) async {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String type = existing?.type ?? (_tabController.index == 0 ? 'income' : 'expense');
    String colorHex = existing?.color ??
        (type == 'income' ? '#059669' : '#DC2626');
    String iconName = existing?.iconName ??
        (type == 'income' ? 'payments' : 'receipt');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(isEdit ? 'Edit Category' : 'New Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Server Hosting',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'income', child: Text('Revenue / Income')),
                    DropdownMenuItem(value: 'expense', child: Text('Expense / Outflow')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDState(() => type = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Choose Color',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorOptions.map((c) {
                    final hex = '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
                    final isSel = colorHex.toUpperCase() == hex;
                    return GestureDetector(
                      onTap: () => setDState(() => colorHex = hex),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSel
                              ? Border.all(color: Colors.black, width: 2.5)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Choose Icon',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconOptions.map((item) {
                    final iName = item['name'] as String;
                    final isSel = iconName == iName;
                    return GestureDetector(
                      onTap: () => setDState(() => iconName = iName),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSel ? AppTheme.primarySoft : AppTheme.surfaceRecessed,
                          borderRadius: BorderRadius.circular(8),
                          border: isSel
                              ? Border.all(color: AppTheme.primary, width: 1.5)
                              : null,
                        ),
                        child: Icon(item['icon'] as IconData, size: 20),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.of(ctx).pop();

                if (isEdit) {
                  await _catService.updateCategory(existing.copyWith(
                    name: name,
                    type: type,
                    color: colorHex,
                    iconName: iconName,
                  ));
                } else {
                  await _catService.addCategory(
                    companyId: widget.companyId,
                    name: name,
                    type: type,
                    color: colorHex,
                    iconName: iconName,
                  );
                }
                _load();
              },
              child: Text(isEdit ? 'Save Changes' : 'Add Category'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategory(CategoryModel cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${cat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.expense),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _catService.deleteCategory(cat.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(text: 'Revenue (${_income.length})'),
            Tab(text: 'Expenses (${_expense.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Category',
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_income, 'revenue'),
                  _buildList(_expense, 'expense'),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<CategoryModel> list, String group) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              'No $group categories defined yet.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: Text('Create $group Category'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final c = list[i];
        Color color = AppTheme.primary;
        try {
          color = Color(int.parse('FF${c.color.replaceAll('#', '')}', radix: 16));
        } catch (_) {}

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(Icons.category_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      c.isIncome ? 'Revenue Category' : 'Expense Category',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit',
                onPressed: () => _showAddEditDialog(c),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppTheme.expense),
                tooltip: 'Delete',
                onPressed: () => _deleteCategory(c),
              ),
            ],
          ),
        );
      },
    );
  }
}
