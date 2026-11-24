# U6 – etapa 1: zoznam produktov (DummyJSON)

## Čo obrazovka robí

`GET https://dummyjson.com/products?limit=20&skip=0&select=title,brand,price,discountPercentage,thumbnail`
→ zoznam produktov: **obrázok, názov, značka, cena, zľava**.

## Rozdelenie kódu

| Súbor | Zodpovednosť |
|---|---|
| `lib/api/dummyjson_api.dart` | **jediná trieda, ktorá komunikuje so serverom** – URL, HTTP, stavový kód, JSON → model / `ApiException` |
| `lib/model/product.dart` | model `Product` + `ProductPage` (`total`, `skip`, `limit`) |
| `lib/ui/products_screen.dart` | stav obrazovky: načítavam / chyba / dáta |
| `lib/ui/product_tile.dart` | jedna položka zoznamu |

UI nevie nič o HTTP ani o JSON – dostane hotový model alebo chybovú hlášku.

## Analýza API v prehliadači (čo tam je a čo chýba)

Odpoveď `/products` má na vrchu `products`, `total` (194), `skip`, `limit`.

Polia jedného produktu, ktoré používame:

| Pole | Typ v JSON | Poznámka |
|---|---|---|
| `id` | int | vracia sa vždy, aj pri `select` |
| `title` | String | |
| `thumbnail` | String (URL, `.webp`) | |
| `brand` | String **alebo chýba** | **chýba pri 92 z 194 produktov** (napr. celá kategória `groceries`) → v modeli `String?`, v UI „Bez značky" |
| `price` | číslo (int aj double) | preto sa parsuje cez `num` |
| `discountPercentage` | číslo | v dátach 0.04 – 19.61 |

Ďalšie polia (`description`, `rating`, `stock`, `tags`, `dimensions`, `reviews`, `meta`, `images`, …)
zoznam nepotrebuje, preto sa sťahujú len vybrané polia cez `?select=`.

Cena po zľave sa počíta: `price * (1 - discountPercentage / 100)`,
pôvodná cena sa zobrazuje preškrtnutá + odznak `-X %`.

## Stavy obrazovky

- **načítavam** – `CircularProgressIndicator` + text „Načítavam produkty…"
- **chyba bez dát** – ikona, hláška zo servera a tlačidlo **Skúsiť znova**
- **chyba pri obnove** – staré dáta zostanú, chyba sa ukáže ako `SnackBar` s akciou „Znova"
- **obnovenie potiahnutím** – `RefreshIndicator`; počas obnovy sa `_page` **nemaže**,
  takže staré dáta zostanú na obrazovke (hore beží `LinearProgressIndicator`)

## Ako som testoval stavy

V `AppBar` je ikona chrobáka → testovací režim:

- *Normálne*
- *Pomalá odpoveď* → `?delay=2000` (vidno načítavanie)
- *Chyba servera* → `/http/503` (vidno chybový stav)

V ostrej aplikácii by toto menu nebolo.

## Screenshoty

| Súbor | Stav |
|---|---|
| `screenshot-1-zoznam.jpg` | zoznam produktov |
| `screenshot-2-chyba-503.jpg` | chybový stav (`/http/503`) |
| `screenshot-3-nacitavanie.jpg` | načítavanie (`?delay=2000`) |

## Spustenie

Projekt v repozitári obsahuje iba `lib/`. Spustenie:

```bash
flutter create --project-name u6_app u6_app
cd u6_app && flutter pub add http
rm -rf lib && cp -R ../lib lib
flutter run
```

Závislosť: `http`.
