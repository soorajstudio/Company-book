class CategoryModel {
  final String id;
  final String companyId;
  final String name;
  final String type; // 'income' (Revenue) or 'expense' (Expense)
  final String color;
  final String iconName;
  final DateTime? createdAt;

  const CategoryModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.type,
    required this.color,
    required this.iconName,
    this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      companyId: map['family_id'] as String? ?? map['company_id'] as String? ?? '',
      name: map['name'] as String,
      type: map['type'] as String,
      color: map['color'] as String? ?? '#4F46E5',
      iconName: map['icon_name'] as String? ?? 'business',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'family_id': companyId,
        'name': name,
        'type': type,
        'color': color,
        'icon_name': iconName,
      };

  CategoryModel copyWith({
    String? name,
    String? type,
    String? color,
    String? iconName,
  }) =>
      CategoryModel(
        id: id,
        companyId: companyId,
        name: name ?? this.name,
        type: type ?? this.type,
        color: color ?? this.color,
        iconName: iconName ?? this.iconName,
        createdAt: createdAt,
      );

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}
