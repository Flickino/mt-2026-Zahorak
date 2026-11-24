# U6 – zoznam produktov z DummyJSON

## Etapa 1 – zoznam

`GET https://dummyjson.com/products?limit=20&skip=0&select=title,brand,price,discountPercentage,thumbnail`
→ zoznam produktov: **obrázok, názov, značka, cena, zľava**.

## Etapa 2 – nekonečné posúvanie a pomalá sieť

- zoznam sa **dopĺňa sám**: keď sa používateľ priblíži na 600 px ku koncu, tichu sa načíta ďalšia
  dávka 20 položiek (`skip` = koľko položiek už mám). Žiadne tlačidlo „načítať viac".
- koniec je určený z `total` (194) – keď je všetko stiahnuté, dole je *Koniec zoznamu*, nie večný spinner
- **režim pomalej siete**: každá položka dostane vlastné náhodné oneskorenie 0–3000 ms, takže niektoré
  karty dobehnú skôr a iné neskôr. Dovtedy je na ich mieste **skeleton**.

## Rozdelenie kódu

| Súbor | Zodpovednosť |
|---|---|
| `lib/api/dummyjson_api.dart` | **jediná trieda, ktorá komunikuje so serverom** – URL, HTTP, stavový kód, JSON → model / `ApiException` |
| `lib/model/product.dart` | model `Product`, `ProductPage` (`total/skip/limit`), `ProductIdPage` |
| `lib/model/product_slot.dart` | jedno miesto v zozname + jeho vlastný stav (dáta / načítava sa / chyba) |
| `lib/ui/products_screen.dart` | stav obrazovky, nekonečné posúvanie, generácia požiadaviek |
| `lib/ui/product_tile.dart` | karta položky v troch stavoch: dáta / skeleton / chyba |

UI nevie nič o HTTP ani o JSON – dostane hotový model alebo chybovú hlášku.

## Analýza API v prehliadači (čo tam je a čo chýba)

Odpoveď `/products` má na vrchu `products`, `total` (194), `skip`, `limit`.

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

Cena po zľave: `price * (1 - discountPercentage / 100)`, pôvodná cena preškrtnutá + odznak `-X %`.

## Ako je spravená pomalá sieť

Oneskorenie **nie je vymyslené v appke** – je to skutočná sieťová latencia zo servera:

1. `GET /products?limit=20&skip=…&select=id` → prídu iba identifikátory, skeletony sú na obrazovke hneď
2. pre každú položku zvlášť `GET /products/{id}?select=…&delay=<náhodne 0–3000>`
3. každá odpoveď dorazí vlastným tempom → karty sa dopĺňajú v náhodnom poradí

V bežnom režime ostáva jedna požiadavka na celú dávku (`/products` aj s dátami), aby sa zbytočne
nepálilo 20 requestov.

## Stavy obrazovky

- **načítavam** – `CircularProgressIndicator` + text „Načítavam produkty…"
- **chyba bez dát** – ikona, hláška zo servera a tlačidlo **Skúsiť znova**
- **chyba pri obnove** – staré dáta zostanú, chyba sa ukáže ako `SnackBar` s akciou „Znova"
- **obnovenie potiahnutím** – `RefreshIndicator`; počas obnovy sa dáta **nemažú**
- **dopĺňanie dávky** – pätička zoznamu: spinner / chyba + *Skúsiť znova* / *Koniec zoznamu*
- **jedna položka** – skeleton, kým nemá dáta; pri chybe má vlastné *Znova* priamo na karte

## Na čo si bolo treba dať pozor

- **zastarané odpovede**: pri obnove a pri zmene režimu sa zvýši číslo generácie. Odpoveď so starým
  číslom sa zahodí – inak by pomalá odpoveď dobehla až po obnove a prepísala čerstvé dáta.
- **dvojité dávky**: `_loadingMore` sa nastaví skôr, než sa čaká na odpoveď, takže rýchle scrollovanie
  nevypáli päť requestov naraz. Navyše sa z novej dávky odfiltrujú už známe `id`.
- **chyba pri dopĺňaní zastaví automatiku**, kým používateľ nestlačí *Skúsiť znova* – inak by sa pri
  každom pohybe prstom posielal ďalší request na nefunkčný server.
- **obnova v pomalej sieti**: karta, ktorá už dáta má, sa pri obnove nevráti do skeletonu – ostane
  stará hodnota, kým nedorazí nová. Inak by potiahnutie vyprázdnilo celú obrazovku a porušilo
  požiadavku z etapy 1 (*počas obnovy zostanú staré dáta*).
- **neznáma chyba**: zachytáva sa aj výnimka, ktorú API vrstva nezabalila do `ApiException`,
  aby obrazovka neostala visieť na spinneri bez možnosti skúsiť znova.
- **skeleton má rovnakú výšku ako hotová karta**, takže zoznam pri dopĺňaní dát nepodskakuje.

## Ako som testoval stavy

V `AppBar` je ikona chrobáka → testovací režim:

- *Normálne*
- *Pomalá odpoveď* → `?delay=2000` na celú odpoveď
- *Pomalá sieť* → náhodné 0–3000 ms na každú položku
- *Chyba servera* → `/http/503`

V ostrej aplikácii by toto menu nebolo.

## Screenshoty

| Súbor | Stav |
|---|---|
| `screenshot-1-zoznam.jpg` | zoznam produktov |
| `screenshot-2-chyba-503.jpg` | chybový stav (`/http/503`) |
| `screenshot-3-nacitavanie.jpg` | načítavanie (`?delay=2000`) |
| `screenshot-4-pomala-siet.jpg` | pomalá sieť – niektoré karty hotové, iné ešte skeletony |
| `screenshot-5-doplnanie-davky.jpg` | pätička *Načítavam ďalšie…* počas dopĺňania |
| `screenshot-6-koniec-zoznamu.jpg` | *Koniec zoznamu – 194 z 194 produktov* |

## Spustenie

Projekt v repozitári obsahuje iba `lib/`. Spustenie:

```bash
flutter create --project-name u6_app u6_app
cd u6_app && flutter pub add http
rm -rf lib && cp -R ../lib lib
flutter run
```

Závislosť: `http`.
