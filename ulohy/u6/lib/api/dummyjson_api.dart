import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../model/category.dart';
import '../model/product.dart';

/// Chyba, ktorej text sa dá rovno ukázať používateľovi.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Režim na odskúšanie stavov UI.
enum ApiTestMode {
  /// Normálna požiadavka.
  normal,

  /// `?delay=2000` – celá odpoveď oneskorená o 2 s (etapa 1).
  slow,

  /// Pomalá sieť: **každá položka** sa ťahá zvlášť a dostane náhodné
  /// oneskorenie 0–3000 ms, takže niektoré karty dobiehajú dlhšie ako iné.
  slowNetwork,

  /// `/http/503` – server vráti chybu.
  error,
}

/// **Jediná trieda, ktorá komunikuje so serverom.**
///
/// UI o HTTP ani o JSON nevie nič – dostane hotový model alebo [ApiException].
/// API: https://dummyjson.com/docs – bez kľúča.
class DummyJsonApi {
  static const String _host = 'dummyjson.com';

  /// Polia, ktoré zoznam naozaj zobrazuje.
  static const String _fields =
      'title,brand,price,discountPercentage,thumbnail';

  /// Horná hranica náhodného oneskorenia v režime pomalej siete.
  static const int maxRandomDelayMs = 3000;

  final http.Client _client;
  final Random _random = Random();

  /// Prepína sa z UI (ikona chrobáka), v ostrej aplikácii by tu nebol.
  ApiTestMode testMode;

  DummyJsonApi({http.Client? client, this.testMode = ApiTestMode.normal})
      : _client = client ?? http.Client();

  bool get isSlowNetwork => testMode == ApiTestMode.slowNetwork;

  /// Zoznam kategórií – `GET /products/categories`.
  ///
  /// Jediná odpoveď v celom API, ktorá je na vrchu **pole**, nie objekt.
  Future<List<Category>> fetchCategories() async {
    final list = await _getList(path: '/products/categories');
    return list
        .whereType<Map<String, dynamic>>()
        .map(Category.fromJson)
        .where((category) => category.slug.isNotEmpty)
        .toList();
  }

  /// Zoznam produktov aj s dátami.
  ///
  /// Bez kategórie `GET /products`, s kategóriou `GET /products/category/{slug}`.
  /// Používa sa v bežnom režime: jedna požiadavka = celá dávka.
  Future<ProductPage> fetchProducts({
    int limit = 20,
    int skip = 0,
    String? categorySlug,
  }) async {
    final json = await _getMap(
      path: _listPath(categorySlug),
      query: {
        'limit': '$limit',
        'skip': '$skip',
        'select': _fields,
      },
    );
    return ProductPage.fromJson(json);
  }

  /// Iba identifikátory dávky (`?select=id`).
  ///
  /// Používa sa v režime pomalej siete: najprv sa zistí, *čo* v dávke je
  /// (aby sa dali hneď vykresliť skeletony), a dáta každej položky sa
  /// doťahujú zvlášť cez [fetchProduct].
  Future<ProductIdPage> fetchProductIds({
    int limit = 20,
    int skip = 0,
    String? categorySlug,
  }) async {
    final json = await _getMap(
      path: _listPath(categorySlug),
      query: {
        'limit': '$limit',
        'skip': '$skip',
        'select': 'id',
      },
    );
    return ProductIdPage.fromJson(json);
  }

  /// Jeden produkt – `GET /products/{id}`.
  ///
  /// V režime pomalej siete dostane požiadavka náhodné `?delay=0–3000`,
  /// takže oneskorenie je **skutočná sieťová latencia**, nie čakanie v appke.
  Future<Product> fetchProduct(int id) async {
    final json = await _getMap(
      path: '/products/$id',
      query: {'select': _fields},
      randomDelay: isSlowNetwork,
    );
    return Product.fromJson(json);
  }

  String _listPath(String? categorySlug) => categorySlug == null
      ? '/products'
      : '/products/category/$categorySlug';

  // ------------------------------------------------------------- vnútro

  Future<Map<String, dynamic>> _getMap({
    required String path,
    Map<String, String> query = const {},
    bool randomDelay = false,
  }) async {
    final decoded =
        await _get(path: path, query: query, randomDelay: randomDelay);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Server poslal neplatnú odpoveď.');
    }
    return decoded;
  }

  Future<List<dynamic>> _getList({
    required String path,
    Map<String, String> query = const {},
  }) async {
    final decoded = await _get(path: path, query: query);
    if (decoded is! List<dynamic>) {
      throw const ApiException('Server poslal neplatnú odpoveď.');
    }
    return decoded;
  }

  /// Spoločná časť pre všetky požiadavky: zostavenie URL, HTTP, stavový kód, JSON.
  Future<dynamic> _get({
    required String path,
    Map<String, String> query = const {},
    bool randomDelay = false,
  }) async {
    final Uri url;
    if (testMode == ApiTestMode.error) {
      // vynútená chyba servera
      url = Uri.https(_host, '/http/503');
    } else {
      url = Uri.https(_host, path, {
        ...query,
        if (testMode == ApiTestMode.slow) 'delay': '2000',
        // Oneskoruje sa len požiadavka na jednu položku. Zoznam idčiek
        // ide naplno, aby boli skeletony na obrazovke hneď.
        if (randomDelay) 'delay': '${_random.nextInt(maxRandomDelayMs + 1)}',
      });
    }

    final http.Response response;
    try {
      response = await _client.get(url).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const ApiException('Server neodpovedá. Skontrolujte pripojenie.');
    } on SocketException {
      throw const ApiException('Žiadne pripojenie na internet.');
    } on http.ClientException {
      throw const ApiException('Spojenie so serverom zlyhalo.');
    }

    if (response.statusCode != 200) {
      throw ApiException(
        'Server vrátil chybu ${response.statusCode}. Skúste to znova.',
      );
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('Server poslal neplatnú odpoveď.');
    }
  }

  void dispose() => _client.close();
}
