import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../model/product.dart';

/// Chyba, ktorej text sa dá rovno ukázať používateľovi.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Režim na odskúšanie stavov UI (zadanie si pýta dôkaz aj o chybovom stave).
enum ApiTestMode {
  /// Normálna požiadavka.
  normal,

  /// `?delay=2000` – odpoveď oneskorená o 2 s, aby bolo vidieť načítavanie.
  slow,

  /// `/http/503` – server vráti chybu.
  error,
}

/// **Jediná trieda, ktorá komunikuje so serverom.**
///
/// UI o HTTP ani o JSON nevie nič – dostane hotový model alebo [ApiException].
/// API: https://dummyjson.com/docs – bez kľúča.
class DummyJsonApi {
  static const String _host = 'dummyjson.com';

  final http.Client _client;

  /// Prepína sa z UI (ikona chrobáka), v ostrej aplikácii by tu nebol.
  ApiTestMode testMode;

  DummyJsonApi({http.Client? client, this.testMode = ApiTestMode.normal})
      : _client = client ?? http.Client();

  /// Zoznam produktov – `GET /products?limit=&skip=`.
  Future<ProductPage> fetchProducts({int limit = 20, int skip = 0}) async {
    final json = await _getJson(
      path: '/products',
      query: {
        'limit': '$limit',
        'skip': '$skip',
        // zoznam potrebuje len tieto polia, nie celý produkt s reviews
        'select': 'title,brand,price,discountPercentage,thumbnail',
      },
    );
    return ProductPage.fromJson(json);
  }

  /// Spoločná časť pre všetky požiadavky: zostavenie URL, HTTP, stavový kód, JSON.
  Future<Map<String, dynamic>> _getJson({
    required String path,
    Map<String, String> query = const {},
  }) async {
    final Uri url;
    if (testMode == ApiTestMode.error) {
      // vynútená chyba servera
      url = Uri.https(_host, '/http/503');
    } else {
      url = Uri.https(_host, path, {
        ...query,
        if (testMode == ApiTestMode.slow) 'delay': '2000',
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
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException('Server poslal neplatnú odpoveď.');
    }
  }

  void dispose() => _client.close();
}
