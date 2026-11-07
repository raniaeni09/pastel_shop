import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../theme/app_colors.dart';

/// Form tambah (product == null) atau ubah produk.
/// Mengembalikan [Product] hasil simpan lewat Navigator.pop.
class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProductService();

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _brand;
  late final TextEditingController _price;
  late final TextEditingController _discount;
  late final TextEditingController _stock;
  late final TextEditingController _thumbnail;
  late final TextEditingController _images;
  late final TextEditingController _shipping;
  late final TextEditingController _warranty;
  late final TextEditingController _returnPolicy;

  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    String dash(String? v) => (v == null || v == '-') ? '' : v;
    _title = TextEditingController(text: p?.title ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _price = TextEditingController(text: p == null ? '' : _num(p.price));
    _discount = TextEditingController(
        text: p == null ? '0' : _num(p.discountPercentage));
    _stock = TextEditingController(text: p == null ? '0' : '${p.stock}');
    _thumbnail = TextEditingController(text: p?.thumbnail ?? '');
    // Galeri: tampilkan hanya jika berbeda dari thumbnail-saja.
    final extra = p == null || (p.images.length == 1 && p.images.first == p.thumbnail)
        ? ''
        : p.images.join('\n');
    _images = TextEditingController(text: extra);
    _shipping = TextEditingController(text: dash(p?.shippingInformation));
    _warranty = TextEditingController(text: dash(p?.warrantyInformation));
    _returnPolicy = TextEditingController(text: dash(p?.returnPolicy));
  }

  String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    for (final c in [
      _title, _description, _category, _brand, _price, _discount, _stock,
      _thumbnail, _images, _shipping, _warranty, _returnPolicy,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Product _build() {
    final old = widget.product;
    final thumb = _thumbnail.text.trim();
    final images = _images.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    String orDash(TextEditingController c) =>
        c.text.trim().isEmpty ? '-' : c.text.trim();
    return Product(
      id: old?.id ?? 0,
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category.text.trim(),
      price: double.parse(_price.text.trim().replaceAll(',', '.')),
      discountPercentage: _discount.text.trim().isEmpty
          ? 0
          : double.parse(_discount.text.trim().replaceAll(',', '.')),
      rating: old?.rating ?? 0,
      stock: _stock.text.trim().isEmpty ? 0 : int.parse(_stock.text.trim()),
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      thumbnail: thumb,
      images: images.isEmpty ? [thumb] : images,
      availabilityStatus: old?.availabilityStatus ?? '-',
      shippingInformation: orDash(_shipping),
      warrantyInformation: orDash(_warranty),
      returnPolicy: orDash(_returnPolicy),
      reviews: old?.reviews ?? const [],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final draft = _build();
      final saved = _isEdit
          ? await _service.updateProduct(draft)
          : await _service.createProduct(draft);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Terjadi kesalahan. Coba lagi.');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
      ));
  }

  // ---------- Validator ----------
  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  String? _validPrice(String? v) {
    if (v == null || v.trim().isEmpty) return 'Harga wajib diisi';
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null || n < 0) return 'Masukkan angka yang valid';
    return null;
  }

  String? _validDiscount(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null || n < 0 || n > 100) return 'Isi 0 - 100';
    return null;
  }

  String? _validStock(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null || n < 0) return 'Bilangan bulat >= 0';
    return null;
  }

  String? _validUrl(String? v) {
    if (v == null || v.trim().isEmpty) return 'URL gambar wajib diisi';
    final u = Uri.tryParse(v.trim());
    if (u == null || !(u.isScheme('http') || u.isScheme('https')) || u.host.isEmpty) {
      return 'Harus berupa URL http(s) yang valid';
    }
    return null;
  }

  String? _validUrlList(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    for (final line in v.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final u = Uri.tryParse(t);
      if (u == null || !(u.isScheme('http') || u.isScheme('https')) || u.host.isEmpty) {
        return 'Setiap baris harus URL http(s) yang valid';
      }
    }
    return null;
  }

  // ---------- UI ----------
  InputDecoration _dec(String label, {String? hint, String? prefix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textSoft),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 2),
        ),
      );

  Widget _gap([double h = 14]) => SizedBox(height: h);

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(_isEdit ? 'Ubah Produk' : 'Tambah Produk',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _section('Info utama'),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: _dec('Nama produk *'),
              validator: (v) => _required(v, 'Nama produk'),
            ),
            _gap(),
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: _dec('Deskripsi'),
            ),
            _gap(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _category,
                    decoration: _dec('Kategori *', hint: 'mis. beauty'),
                    validator: (v) => _required(v, 'Kategori'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _brand,
                    decoration: _dec('Brand'),
                  ),
                ),
              ],
            ),
            _section('Harga & stok'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _dec('Harga *', prefix: '\$ '),
                    validator: _validPrice,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _discount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _dec('Diskon', prefix: '% '),
                    validator: _validDiscount,
                  ),
                ),
              ],
            ),
            _gap(),
            TextFormField(
              controller: _stock,
              keyboardType: TextInputType.number,
              decoration: _dec('Stok (unit)'),
              validator: _validStock,
            ),
            _section('Gambar'),
            TextFormField(
              controller: _thumbnail,
              keyboardType: TextInputType.url,
              decoration: _dec('URL gambar utama *', hint: 'https://...'),
              validator: _validUrl,
            ),
            _gap(),
            TextFormField(
              controller: _images,
              minLines: 2,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              decoration: _dec('Gambar galeri (opsional)',
                  hint: 'Satu URL per baris'),
              validator: _validUrlList,
            ),
            _section('Informasi tambahan'),
            TextFormField(
              controller: _shipping,
              decoration:
                  _dec('Pengiriman', hint: 'mis. Ships in 1 week'),
            ),
            _gap(),
            TextFormField(
              controller: _warranty,
              decoration: _dec('Garansi', hint: 'mis. 1 year warranty'),
            ),
            _gap(),
            TextFormField(
              controller: _returnPolicy,
              decoration:
                  _dec('Pengembalian', hint: 'mis. 30 days return policy'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _saving
                      ? 'Menyimpan...'
                      : _isEdit
                          ? 'Simpan perubahan'
                          : 'Tambah produk',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
