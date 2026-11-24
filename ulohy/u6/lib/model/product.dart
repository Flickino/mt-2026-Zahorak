/// Model jedného produktu z DummyJSON (/products).
///
/// Z odpovede si berieme iba polia, ktoré obrazovka potrebuje:
/// názov, obrázok, značka, cena, zľava.
class Product {
  final int id;
  final String title;
  final String thumbnail;

  /// Pozor: `brand` v API **chýba** pri 92 z 194 produktov
  /// (napr. kategória `groceries`), preto je nullable.
  final String? brand;

  /// Pôvodná cena v USD.
  final double price;

  /// Zľava v percentách (v API 0.04 – 19.61).
  final double discountPercentage;

  const Product({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.brand,
    required this.price,
    required this.discountPercentage,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Bez názvu',
      thumbnail: json['thumbnail'] as String? ?? '',
      brand: json['brand'] as String?,
      // price aj discountPercentage chodia ako int aj ako double -> num
      price: (json['price'] as num? ?? 0).toDouble(),
      discountPercentage: (json['discountPercentage'] as num? ?? 0).toDouble(),
    );
  }

  /// Cena po odrátaní zľavy.
  double get discountedPrice => price * (1 - discountPercentage / 100);

  /// Zľavu pod 1 % nemá zmysel zobrazovať ako odznak.
  bool get hasDiscount => discountPercentage >= 1;
}

/// Jedna "stránka" zoznamu – API vracia aj total/skip/limit (pre stránkovanie v ďalšej etape).
class ProductPage {
  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  const ProductPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory ProductPage.fromJson(Map<String, dynamic> json) {
    final list = json['products'] as List<dynamic>? ?? const [];
    return ProductPage(
      products: list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      skip: json['skip'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
    );
  }
}

/// Dávka, z ktorej potrebujeme iba identifikátory (`?select=id`).
///
/// V režime pomalej siete sa najprv zistí, čo v dávke je, a dáta každej
/// položky sa doťahujú zvlášť.
class ProductIdPage {
  final List<int> ids;
  final int total;
  final int skip;
  final int limit;

  const ProductIdPage({
    required this.ids,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory ProductIdPage.fromJson(Map<String, dynamic> json) {
    final list = json['products'] as List<dynamic>? ?? const [];
    return ProductIdPage(
      ids: list
          .map((e) => (e as Map<String, dynamic>)['id'] as int)
          .toList(),
      total: json['total'] as int? ?? 0,
      skip: json['skip'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
    );
  }
}
