import 'product.dart';

enum SortOption {
  relevance('Default'),
  priceAsc('Harga terendah'),
  priceDesc('Harga tertinggi'),
  ratingDesc('Rating tertinggi'),
  titleAsc('Nama A-Z');

  const SortOption(this.label);

  final String label;

  /// Mengembalikan salinan list yang sudah diurutkan.
  List<Product> apply(List<Product> input) {
    final list = List<Product>.of(input);
    switch (this) {
      case SortOption.relevance:
        break;
      case SortOption.priceAsc:
        list.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
      case SortOption.priceDesc:
        list.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
      case SortOption.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case SortOption.titleAsc:
        list.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return list;
  }
}
