import 'package:flutter/material.dart';

import '../api/dummyjson_api.dart';
import '../model/product_slot.dart';
import 'product_tile.dart';

/// Výsledok jednej dávky – položky a koľko ich je celkovo na serveri.
class _PageResult {
  final List<ProductSlot> slots;
  final int total;

  const _PageResult({required this.slots, required this.total});
}

/// Obrazovka so zoznamom produktov.
///
/// Stará sa len o stav obrazovky (načítavam / chyba / dáta / dopĺňam ďalšie) –
/// samotné sťahovanie rieši [DummyJsonApi], dáta držia [ProductSlot].
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  /// Veľkosť jednej dávky.
  static const int _pageSize = 20;

  /// Koľko pixelov pred koncom zoznamu sa začne ťahať ďalšia dávka.
  /// Vďaka tomu používateľ na koniec zvyčajne ani nedorazí.
  static const double _prefetchPx = 600;

  final DummyJsonApi _api = DummyJsonApi();
  final ScrollController _scroll = ScrollController();

  /// Nazbierané položky zo všetkých doteraz načítaných dávok.
  List<ProductSlot> _slots = [];

  /// Koľko produktov má server celkovo (z odpovede `total`).
  int _total = 0;

  /// Prvé načítanie už prebehlo úspešne.
  bool _hasData = false;

  /// Beží prvé načítanie alebo obnova.
  bool _loadingPage = false;

  /// Beží dopĺňanie ďalšej dávky.
  bool _loadingMore = false;

  /// Chyba prvého načítania (celá obrazovka).
  String? _error;

  /// Chyba dopĺňania (iba pätička zoznamu).
  String? _moreError;

  /// Číslo generácie požiadaviek.
  ///
  /// Zvýši sa pri obnove a pri zmene režimu. Odpovede so starým číslom sa
  /// zahodia – inak by pomalá odpoveď dobehla až po obnove a prepísala
  /// čerstvé dáta alebo nasypala duplicity.
  int _generation = 0;

  bool get _hasMore => _hasData && _slots.length < _total;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _api.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- scroll

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - _prefetchPx) {
      _loadNextPage();
    }
  }

  // ------------------------------------------------------------- načítanie

  /// Prvá dávka. Pri `isRefresh: true` (potiahnutie) **nemažeme staré dáta** –
  /// zostanú na obrazovke, kým nepríde nová odpoveď.
  Future<void> _loadFirstPage({bool isRefresh = false}) async {
    final generation = ++_generation;

    setState(() {
      _loadingPage = true;
      _loadingMore = false;
      _moreError = null;
      if (!isRefresh) {
        _error = null;
        _slots = [];
        _hasData = false;
      }
    });

    try {
      final page = await _fetchPage(skip: 0);
      if (!mounted || generation != _generation) return;
      setState(() {
        _slots = page.slots;
        _total = page.total;
        _hasData = true;
        _error = null;
        _loadingPage = false;
      });
      _startItemLoads(page.slots, generation, refreshAll: isRefresh);
    } catch (e) {
      if (!mounted || generation != _generation) return;
      final message = _messageFor(e);
      setState(() {
        _loadingPage = false;
        _error = message;
      });
      // Ak nejaké dáta už máme, necháme ich na obrazovke
      // a o chybe informujeme len cez SnackBar.
      if (_hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: 'Znova',
              onPressed: () => _loadFirstPage(isRefresh: true),
            ),
          ),
        );
      }
    }
  }

  /// Ďalšia dávka – volá sa automaticky zo scrollu, bez tlačidla.
  Future<void> _loadNextPage() async {
    if (_loadingPage || _loadingMore || !_hasMore || _moreError != null) return;

    final generation = _generation;
    setState(() => _loadingMore = true);

    try {
      final page = await _fetchPage(skip: _slots.length);
      if (!mounted || generation != _generation) return;

      // poistka proti duplicitám, keby sa dávka opakovala
      final known = _slots.map((slot) => slot.id).toSet();
      final fresh =
          page.slots.where((slot) => !known.contains(slot.id)).toList();

      setState(() {
        _slots = [..._slots, ...fresh];
        _total = page.total;
        _loadingMore = false;
      });
      _startItemLoads(fresh, generation);
    } catch (e) {
      if (!mounted || generation != _generation) return;
      final message = _messageFor(e);
      setState(() {
        _loadingMore = false;
        // Kým chyba visí, scroll ďalšiu dávku nespustí –
        // inak by sa pri každom pohybe pálili requesty.
        _moreError = message;
      });
    }
  }

  /// Načítanie jednej dávky podľa režimu.
  ///
  /// Bežne príde celá dávka jednou požiadavkou. V režime pomalej siete prídu
  /// najprv iba identifikátory (skeletony sú na obrazovke hneď) a dáta každej
  /// položky sa doťahujú zvlášť – preto niektoré karty dobiehajú dlhšie.
  Future<_PageResult> _fetchPage({required int skip}) async {
    if (_api.isSlowNetwork) {
      final page = await _api.fetchProductIds(limit: _pageSize, skip: skip);

      // Dáta, ktoré už na obrazovke sú. Pri obnove sa karta nesmie vrátiť
      // do skeletonu len preto, že sa obnovuje – ostane stará hodnota,
      // kým nedorazí nová.
      final known = {
        for (final slot in _slots)
          if (slot.product != null) slot.id: slot.product!,
      };

      return _PageResult(
        slots: page.ids.map((id) {
          final product = known[id];
          return product == null
              ? ProductSlot.pending(id)
              : ProductSlot.loaded(product);
        }).toList(),
        total: page.total,
      );
    }

    final page = await _api.fetchProducts(limit: _pageSize, skip: skip);
    return _PageResult(
      slots: page.products.map(ProductSlot.loaded).toList(),
      total: page.total,
    );
  }

  /// Spustí sťahovanie dát pre položky, ktoré ešte žiadne nemajú.
  /// Požiadavky bežia súbežne, každá si dobehne vlastným tempom.
  void _startItemLoads(
    List<ProductSlot> slots,
    int generation, {
    bool refreshAll = false,
  }) {
    // V bežnom režime prišli dáta rovno s dávkou, netreba nič doťahovať.
    if (!_api.isSlowNetwork) return;
    for (final slot in slots) {
      if (refreshAll || slot.isLoading) _loadItem(slot.id, generation);
    }
  }

  /// Text chyby pre používateľa – aj pre chybu, ktorú API vrstva nepozná.
  String _messageFor(Object error) => error is ApiException
      ? error.message
      : 'Neočakávaná chyba. Skúste to znova.';

  Future<void> _loadItem(int id, int generation) async {
    try {
      final product = await _api.fetchProduct(id);
      if (!mounted || generation != _generation) return;
      _replaceSlot(id, (slot) => slot.withProduct(product));
    } catch (e) {
      if (!mounted || generation != _generation) return;
      final message = _messageFor(e);
      _replaceSlot(id, (slot) => slot.withError(message));
    }
  }

  void _replaceSlot(int id, ProductSlot Function(ProductSlot) update) {
    setState(() {
      _slots = [
        for (final slot in _slots)
          if (slot.id == id) update(slot) else slot,
      ];
    });
  }

  void _retryItem(int id) {
    _replaceSlot(id, (slot) => slot.retrying());
    _loadItem(id, _generation);
  }

  void _retryNextPage() {
    setState(() => _moreError = null);
    _loadNextPage();
  }

  void _changeMode(ApiTestMode mode) {
    setState(() => _api.testMode = mode);
    // zahodíme dáta, aby bolo vidieť načítanie od nuly
    _loadFirstPage();
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produkty'),
        actions: [
          // Len na odskúšanie stavov, v ostrej aplikácii by tu nebolo.
          PopupMenuButton<ApiTestMode>(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Testovací režim',
            initialValue: _api.testMode,
            onSelected: _changeMode,
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
                value: ApiTestMode.slowNetwork,
                child: Text('Pomalá sieť (0–3000 ms na položku)'),
              ),
              PopupMenuItem(
                value: ApiTestMode.error,
                child: Text('Chyba servera (503)'),
              ),
            ],
          ),
        ],
        bottom: _loadingPage && _hasData
            // obnova pri už zobrazených dátach – tenký prúžok hore
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(minHeight: 4),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadFirstPage(isRefresh: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // 1. prvé načítanie – používateľ vidí, že sa načítava
    if (!_hasData && _loadingPage) {
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
    if (!_hasData && _error != null) {
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
                onPressed: _loadingPage ? null : () => _loadFirstPage(),
                icon: const Icon(Icons.refresh),
                label: const Text('Skúsiť znova'),
              ),
            ],
          ),
        ),
      );
    }

    if (_slots.isEmpty) {
      return const _CenteredScrollable(child: Text('Žiadne produkty.'));
    }

    // 3. dáta – posledný prvok je pätička so stavom dopĺňania
    return ListView.builder(
      controller: _scroll,
      // aby sa dalo potiahnuť aj keď je zoznam kratší ako obrazovka
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _slots.length + 1,
      itemBuilder: (context, index) {
        if (index == _slots.length) return _buildFooter();
        final slot = _slots[index];
        return ProductSlotTile(
          slot: slot,
          onRetry: () => _retryItem(slot.id),
        );
      },
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);

    if (_moreError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        child: Column(
          children: [
            Text(_moreError!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _retryNextPage,
              icon: const Icon(Icons.refresh),
              label: const Text('Skúsiť znova'),
            ),
          ],
        ),
      );
    }

    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(12, 16, 12, 32),
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 8),
            Text('Načítavam ďalšie…'),
          ],
        ),
      );
    }

    if (!_hasMore) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 32),
        child: Text(
          'Koniec zoznamu – ${_slots.length} z $_total produktov',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    // je čo dopĺňať, ale ešte sa nespustilo – miesto pre spinner
    return const SizedBox(height: 72);
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
