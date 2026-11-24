# U6 – použitie AI nástrojov

**Nástroj:** Claude Code (Opus) v Claude desktop app.

## Kľúčové prompty

1. Vložené zadanie etapy 1 (zoznam produktov z DummyJSON: názov, obrázok, značka, cena, zľava;
   komunikácia so serverom v jednej triede, dáta v modeli; stavy načítavania, chyby s možnosťou
   skúsiť znova, obnovenie potiahnutím so zachovaním starých dát; dôkaz = screenshot zoznamu
   a chybového stavu `/http/503`).
2. „nerob nič, len čo sa po mne chce?" – najprv rozpis požiadaviek, až potom implementácia.
3. „zbuchaj to" – implementácia.

## Čo robil model

- `curl` na `https://dummyjson.com/products` a analýza polí a typov; zistil, že **`brand` chýba
  pri 92 z 194 produktov** → v modeli nullable (toto bola najdôležitejšia vec z analýzy API),
- rozdelenie na `api/` (jedna trieda pre server), `model/`, `ui/`,
- obrazovka so stavmi + `RefreshIndicator`,
- build Flutter web a screenshoty troch stavov v emulovanom mobilnom okne.

## Čo som riešil sám / upravil

- kontrola, že `?select=` naozaj vracia `id` aj `thumbnail`,
- prepínač testovacieho režimu v `AppBar` (normálne / `delay=2000` / `503`), aby sa stavy dali
  odskúšať a odfotiť bez zásahu do kódu,
- overenie kódu cez `flutter analyze` (bez chýb).
