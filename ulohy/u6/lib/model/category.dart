/// Kategória z `/products/categories`.
///
/// Pozor: endpoint nevracia reťazce, ale objekty `{slug, name, url}`.
/// `slug` ide do URL, `name` sa ukazuje používateľovi.
class Category {
  final String slug;
  final String name;

  const Category({required this.slug, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    final slug = json['slug'] as String? ?? '';
    return Category(
      slug: slug,
      name: json['name'] as String? ?? slug,
    );
  }
}
