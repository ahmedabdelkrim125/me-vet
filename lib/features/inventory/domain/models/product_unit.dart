enum ProductUnit { piece, vial, box, bottle, kg, liter }

extension ProductUnitX on ProductUnit {
  String get label {
    switch (this) {
      case ProductUnit.piece:
        return 'قطعة';
      case ProductUnit.vial:
        return 'فيال';
      case ProductUnit.box:
        return 'علبة';
      case ProductUnit.bottle:
        return 'زجاجة';
      case ProductUnit.kg:
        return 'كيلو';
      case ProductUnit.liter:
        return 'لتر';
    }
  }
}
