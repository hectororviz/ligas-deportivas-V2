import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

final categoriesCatalogProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final response = await ref.read(apiClientProvider).get<List<dynamic>>('/categories');
  final data = response.data ?? [];
  return data
      .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
      .where((category) => category.active)
      .toList();
});

class CategoryModel {
  CategoryModel({
    required this.id,
    required this.name,
    required this.birthYearMin,
    required this.birthYearMax,
    required this.gender,
    required this.promotional,
    required this.active,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        birthYearMin: json['birthYearMin'] as int,
        birthYearMax: json['birthYearMax'] as int,
        gender: json['gender'] as String? ?? 'MIXTO',
        promotional: json['promotional'] as bool? ?? false,
        active: json['active'] as bool? ?? true,
      );

  final int id;
  final String name;
  final int birthYearMin;
  final int birthYearMax;
  final String gender;
  final bool promotional;
  final bool active;

  String get genderLabel {
    switch (gender) {
      case 'MASCULINO':
        return 'Masculino';
      case 'FEMENINO':
        return 'Femenino';
      default:
        return 'Mixto';
    }
  }

  String get birthYearRangeLabel {
    if (birthYearMin == birthYearMax) {
      return '$birthYearMin';
    }
    return '$birthYearMin - $birthYearMax';
  }
}
