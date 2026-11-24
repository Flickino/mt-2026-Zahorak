import 'package:flutter/material.dart';

import '../api/dummyjson_api.dart';
import '../model/product.dart';
import 'product_tile.dart';

/// Obrazovka so zoznamom produktov.
///
/// Stará sa len o stav obrazovky (načítavam / chyba / dáta) – samotné
/// sťahovanie rieši [DummyJsonApi], dáta drží [ProductPage].
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final DummyJsonApi _api = DummyJsonApi();

  /// null = ešte nemáme žiadne dáta (prvé načítanie alebo chyba pri ňom)
  ProductPage? _page;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  /// Načítanie dát.
  ///
  /// Pri `isRefresh: true` (potiahnutie) **nemažeme staré dáta** – zostanú
  /// na obrazovke, kým nepríde nová odpoveď.
  Future<void> _load({bool isRefresh = false}) async {
    setState(() {
      _loading = true;
      if (!isRefresh) _error = null;
    });

    try {
      final page = await _api.fetchProducts(limit: 20);
      if (!mounted) return;
      setState(() {
        _page = page;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
      // Ak nejaké dáta už máme, necháme ich na obrazovke
      // a o chybe informujeme len cez SnackBar.
      if (_page != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            action: SnackBarAction(
              label: 'Znova',
              onPressed: () => _load(isRefresh: true),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produkty'),
        actions: [
          // Len na odskúšanie stavov (pomalá odpoveď / chyba servera).
          PopupMenuButton<ApiTestMode>(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Testovací režim',
            initialValue: _api.testMode,
            onSelected: (mode) {
              setState(() {
                _api.testMode = mode;
                // zahodíme dáta, aby bolo vidieť načítanie od nuly
                _page = null;
              });
              _load();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ApiTestMode.normal,
                child: Text('Normálne'),
              ),
              PopupMenuItem(
                value: ApiTestMode.slow,
                child: Text('Pomalá odpoveď (delay=2000)'),
              ),
              PopupMenuItem(
                value: ApiTestMode.error,
                child: Text('Chyba servera (503)'),
              ),
            ],
          ),
        ],
        bottom: _loading && _page != null
            // obnova pri už zobrazených dátach – tenký prúžok hore
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(minHeight: 4),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(isRefresh: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // 1. prvé načítanie – používateľ vidí, že sa načítava
    if (_page == null && _loading) {
      return const _CenteredScrollable(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Načítavam produkty…'),
          ],
        ),
      );
    }

    // 2. chyba a žiadne dáta – správa + možnosť skúsiť znova
    if (_page == null && _error != null) {
      return _CenteredScrollable(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Produkty sa nepodarilo načítať',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loading ? null : () => _load(),
                icon: const Icon(Icons.refresh),
                label: const Text('Skúsiť znova'),
              ),
            ],
          ),
        ),
      );
    }

    final products = _page?.products ?? const <Product>[];

    if (products.isEmpty) {
      return const _CenteredScrollable(child: Text('Žiadne produkty.'));
    }

    // 3. dáta
    return ListView.builder(
      // aby sa dalo potiahnuť aj keď je zoznam kratší ako obrazovka
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: products.length + 1,
      itemBuilder: (context, index) {
        if (index == products.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            child: Text(
              'Zobrazených ${products.length} z ${_page!.total} produktov',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        return ProductTile(product: products[index]);
      },
    );
  }
}

/// Obsah v strede obrazovky, ktorý sa stále dá potiahnuť (kvôli RefreshIndicator).
class _CenteredScrollable extends StatelessWidget {
  final Widget child;

  const _CenteredScrollable({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
