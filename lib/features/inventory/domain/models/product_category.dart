enum ProductCategory { poultry, largeAnimal, pets, supplies, other }

extension ProductCategoryX on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.poultry:
        return 'دواجن';
      case ProductCategory.largeAnimal:
        return 'لارج';
      case ProductCategory.pets:
        return 'حيوانات أليفة';
      case ProductCategory.supplies:
        return 'مستلزمات';
      case ProductCategory.other:
        return 'أخرى';
    }
  }
}
