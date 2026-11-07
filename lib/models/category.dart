class Category {
  final String slug;
  final String name;

  Category({required this.slug, required this.name});

  /// Mendukung dua bentuk respons: objek {slug, name} atau string biasa.
  factory Category.from(dynamic raw) {
    if (raw is Map) {
      final slug = raw['slug'] as String? ?? '';
      return Category(slug: slug, name: raw['name'] as String? ?? _pretty(slug));
    }
    final slug = raw.toString();
    return Category(slug: slug, name: _pretty(slug));
  }

  static String _pretty(String slug) => slug
      .split('-')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
