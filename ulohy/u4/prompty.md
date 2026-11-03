# História promptov – U4, skupina 2 (Kategória v e-shope)

Nástroj: **Claude Code** (model Opus 5), práca v termináli nad repozitárom.
Dátum: 3. 11. 2026

Projekt bol vytvorený ako Flutter web app (`flutter create --platforms=web`) a počas
písania bežal cez `flutter run -d web-server`, aby sa dal priebežne kontrolovať
v prehliadači pri rozmere telefónu (375×812).

---

## 1.

> pozri read.me v u4 a povedz mi čo chapeš z toho

Prečítanie zadania a zhrnutie: čo sa hodnotí (layout + scrollovanie), aké widgety
sú pre jednotlivé skupiny povinné, aké texty a dáta sú k dispozícii, čo treba odovzdať.

## 2.

> som skupina 2 čo potrebuješ na to nech to spravíme spolu, chcem to chapať priebežne

Zistenie prostredia (Flutter 3.47.7, dostupné zariadenia macOS a Chrome – iOS
simulátor ani Android emulátor na stroji nebol). Doplňujúce otázky:

- **Sú k dispozícii screenshoty zadanej obrazovky?** → *„nemam, spravme bez nich,
  ked tak prekopeme podla nich"* – layout teda vznikol len z textového popisu v README.
- **Na čom appku spúšťať?** → *Chrome*.

## 3.

> netreba riešiť uloha u1 a u3

Vynechané prezeranie predošlých úloh.

## 4.

> zrob to v inom foldery nech do u4 dame len to čo je nutne

Flutter projekt bol založený mimo repozitára (`../u4-app`); do `ulohy/u4/` sa
kopíruje len `lib/main.dart`, screenshoty a tento súbor.

---

## Postup implementácie

Kód vznikal po krokoch, po každom kroku hot restart a kontrola v prehliadači:

1. **Kostra** – `Scaffold` + `CustomScrollView`, `SliverAppBar(pinned: true)`
   s titulkom *Running shoes*, `Badge` s číslom 2 na ikone košíka, vyhľadávacie
   pole v `bottom` app baru, `NavigationBar` dole s vybranou položkou *Categories*.
   Overené, že app bar aj search ostanú pri scrolle pripnuté.
2. **Bannery a značky** – `PageView` s tromi bannermi (+ vlastné bodky
   indikátora), vodorovný `ListView.separated` so siedmimi značkami v krúžkoch.
   Oboje zabalené do `SliverToBoxAdapter`, obe s ohraničenou výškou.
3. **Sekcie s produktmi** – pre každú sekciu `SliverMainAxisGroup` obsahujúci
   `SliverPersistentHeader(pinned: true)` s názvom a počtom položiek, a pod ním
   `SliverGrid` (2 stĺpce) v `SliverPadding`. Vďaka zoskupeniu visí hlavička hore
   len dovtedy, kým je na obrazovke jej vlastná mriežka – potom ju vytlačí
   hlavička nasledujúcej sekcie.
4. **Karta produktu** – `Card` s `Stack` + `Positioned` pre zľavový odznak nad
   farebnou plochou, preškrtnutá pôvodná cena cez `TextDecoration.lineThrough`.
5. **Kontrola** – `flutter analyze` bez chýb a upozornení, vizuálna kontrola
   scrollovania, screenshoty.

## Vlastné widgety (opakujúce sa prvky)

- `BannerCard` – jeden banner v `PageView`
- `BrandChip` – krúžok so začiatočným písmenom značky
- `ProductCard` – karta produktu vrátane voliteľnej zľavy a pôvodnej ceny
- `SectionHeaderDelegate` – pripnutá hlavička sekcie
- `productSection(...)` – funkcia, ktorá zloží hlavičku a mriežku do jedného slivera
- `_PageDots` – indikátor stránky pod bannermi

## Poznámka

Obrazovka je postavená bez predlohy (screenshoty zo cvičenia neboli k dispozícii),
takže konkrétne rozostupy, farby a proporcie sú vlastná interpretácia popisu.
Všetky prvky požadované zadaním sú použité.
