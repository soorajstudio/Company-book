import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import 'company_service.dart';

class CategoryService {
  final _supabase = Supabase.instance.client;

  Future<void> ensureDefaultCategories(String companyId) async {
    try {
      final existing = await _supabase
          .from('categories')
          .select('id')
          .eq('family_id', companyId)
          .limit(1);

      if ((existing as List).isEmpty) {
        final userId = _supabase.auth.currentUser?.id;
        final cats = CompanyService.defaultCategories.map((c) => {
              'family_id': companyId,
              'name': c['name']!,
              'type': c['type']!,
              'color': c['color']!,
              'icon_name': c['icon']!,
              'created_by': userId,
            }).toList();
        await _supabase.from('categories').insert(cats);
      }
    } catch (_) {}
  }

  Future<List<CategoryModel>> getCategories(String companyId) async {
    try {
      await ensureDefaultCategories(companyId);
      final result = await _supabase
          .from('categories')
          .select()
          .eq('family_id', companyId)
          .order('type')
          .order('name');
      return (result as List)
          .map((m) => CategoryModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CategoryModel>> getCategoriesByType(
      String companyId, String type) async {
    try {
      await ensureDefaultCategories(companyId);
      final result = await _supabase
          .from('categories')
          .select()
          .eq('family_id', companyId)
          .eq('type', type)
          .order('name');
      return (result as List)
          .map((m) => CategoryModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<CategoryModel> addCategory({
    required String companyId,
    required String name,
    required String type,
    required String color,
    required String iconName,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    final result = await _supabase.from('categories').insert({
      'family_id': companyId,
      'name': name.trim(),
      'type': type,
      'color': color,
      'icon_name': iconName,
      'created_by': userId,
    }).select().single();

    return CategoryModel.fromMap(result);
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _supabase.from('categories').update({
      'name': category.name.trim(),
      'type': category.type,
      'color': category.color,
      'icon_name': category.iconName,
    }).eq('id', category.id);
  }

  Future<void> deleteCategory(String id) async {
    await _supabase.from('categories').delete().eq('id', id);
  }
}
