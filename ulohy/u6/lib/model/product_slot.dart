import 'product.dart';

/// Jedno miesto v zozname.
///
/// V bežnom režime vznikne rovno s dátami. V režime pomalej siete vznikne
/// prázdne (vieme iba `id`) a dáta doň dobehnú neskôr – dovtedy je na jeho
/// mieste skeleton. Preto má každá položka **vlastný stav načítania**.
class ProductSlot {
  final int id;
  final Product? product;
  final String? error;

  const ProductSlot({required this.id, this.product, this.error});

  /// Položka, ktorá ešte nemá dáta.
  const ProductSlot.pending(this.id)
      : product = null,
        error = null;

  /// Položka, ktorá prišla aj s dátami (bežný režim).
  ProductSlot.loaded(Product this.product)
      : id = product.id,
        error = null;

  bool get isLoading => product == null && error == null;

  ProductSlot withProduct(Product value) =>
      ProductSlot(id: id, product: value);

  ProductSlot withError(String message) =>
      ProductSlot(id: id, error: message);

  /// Späť do stavu „načítava sa" (po stlačení *Skúsiť znova* na karte).
  ProductSlot retrying() => ProductSlot.pending(id);
}
