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

## Etapa 2

**Prompty**

1. „teraz budeme pridávať infinity scroll – keď prídeme na tú 20. položku, načítajú sa ďalšie
   (youtube/ig logika), ale treba pridať aj slow network mode – random položky dostanú 0–3000 ms delay,
   aby to simulovalo pomalý net. najprv mi spíš heslovito ako to chápeš."
2. Upresnenie: „chceme znázorniť, že niektoré položky sa načítavajú dlhšie ako iné" → z toho vzišlo
   riešenie s doťahovaním každej položky zvlášť cez `/products/{id}?delay=…`, nie s jedným
   oneskorením na celú dávku.

**Čo robil model**

- overenie API cez `curl` (`/products/{id}?select=`, `?select=id`, `?delay=` na detaile),
- rozdelenie na dve cesty načítania (dávka naraz vs. idčká + položky zvlášť),
- `ProductSlot` so stavom na položku, skeleton karta, pätička zoznamu,
- ochrana proti zastaraným odpovediam a dvojitým dávkam,
- odskúšanie v prehliadači: prejdených všetkých 194 produktov po dávkach + screenshoty stavov,
- recenzia kódu viacerými agentmi (súbežnosť, stránkovanie, Flutter, splnenie zadania).

**Čo som riešil sám / upravil**

- rozhodnutie, že oneskorenie má byť **skutočná sieťová latencia**, nie `Future.delayed` v appke,
- že zoznam idčiek ide naplno, aby boli skeletony na obrazovke hneď,
- overenie na telefóne cez lokálnu sieť (potiahnutie prstom, dopĺňanie dávok).
