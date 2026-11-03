import 'package:flutter/material.dart';

void main() => runApp(const EshopApp());

class EshopApp extends StatelessWidget {
  const EshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Running shoes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3B6FE0),
        useMaterial3: true,
      ),
      home: const CategoryScreen(),
    );
  }
}

/// Obrazovka kategórie v e-shope.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int _selectedTab = 1; // Categories
  final PageController _bannerController = PageController();
  int _bannerPage = 0;

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Running shoes'),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: null,
                  icon: Badge(
                    label: Text('2'),
                    child: Icon(Icons.shopping_cart_outlined),
                  ),
                ),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(64),
              child: _SearchField(),
            ),
          ),

          // Bannery – dajú sa potiahnuť do strany.
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(
                  height: 140,
                  child: PageView.builder(
                    controller: _bannerController,
                    itemCount: _banners.length,
                    onPageChanged: (i) => setState(() => _bannerPage = i),
                    itemBuilder: (context, i) => BannerCard(banner: _banners[i]),
                  ),
                ),
                _PageDots(count: _banners.length, current: _bannerPage),
              ],
            ),
          ),

          // Značky – vodorovný zoznam.
          SliverToBoxAdapter(
            child: SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _brands.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, i) => BrandChip(name: _brands[i]),
              ),
            ),
          ),

          // Sekcie s produktmi – hlavička každej sa pripne, kým beží jej mriežka.
          productSection('New arrivals', _newArrivals),
          productSection('Best sellers', _bestSellers),
          productSection('Sale', _sale),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('2'),
              child: Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              label: Text('2'),
              child: Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- dáta

class BannerItem {
  const BannerItem(this.title, this.text, this.color);
  final String title;
  final String text;
  final Color color;
}

const _banners = <BannerItem>[
  BannerItem('Autumn sale', 'Up to -40 % on trail shoes', Color(0xFFE8623A)),
  BannerItem('Free delivery', 'On all orders over 50 €', Color(0xFF2E7D63)),
  BannerItem('New collection', 'Lightweight racing shoes', Color(0xFF3B6FE0)),
];

const _brands = <String>[
  'Asics',
  'Brooks',
  'Hoka',
  'Nike',
  'On',
  'Saucony',
  'Adidas',
];

class Product {
  const Product(this.name, this.price, {this.oldPrice, this.discount});
  final String name;
  final String price;
  final String? oldPrice;
  final String? discount;
}

const _newArrivals = <Product>[
  Product('Cloud Runner 5', '139.90 €'),
  Product('Trail Hawk GTX', '159.00 €'),
];

const _bestSellers = <Product>[
  Product('Daily Trainer 3', '109.90 €'),
  Product('Road Glide', '129.00 €'),
];

const _sale = <Product>[
  Product('Sprint Racer', '79.90 €', oldPrice: '119.90 €', discount: '-33 %'),
  Product('Forest Path', '89.00 €', oldPrice: '129.00 €', discount: '-31 %'),
  Product('City Jogger', '59.90 €', oldPrice: '89.90 €', discount: '-33 %'),
];

// ------------------------------------------------------------- widgety

/// Jeden banner v `PageView`. Obrázok je nahradený farebnou plochou s ikonou.
class BannerCard extends StatelessWidget {
  const BannerCard({super.key, required this.banner});

  final BannerItem banner;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: banner.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner.title,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner.text,
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            const Icon(Icons.directions_run, size: 48, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

/// Bodky pod `PageView`, ktoré ukazujú poradie banneru.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

/// Jedna sekcia = pripnutá hlavička + mriežka produktov.
///
/// `SliverMainAxisGroup` zlepí obe časti do jedného celku. Vďaka tomu hlavička
/// visí hore len dovtedy, kým je na obrazovke jej vlastná mriežka – potom ju
/// odtlačí hlavička ďalšej sekcie.
SliverMainAxisGroup productSection(String title, List<Product> products) {
  return SliverMainAxisGroup(
    slivers: [
      SliverPersistentHeader(
        pinned: true,
        delegate: SectionHeaderDelegate(title: title, count: products.length),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemCount: products.length,
          itemBuilder: (context, i) => ProductCard(product: products[i]),
        ),
      ),
    ],
  );
}

/// Hlavička sekcie: názov vľavo, počet položiek vpravo.
class SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  const SectionHeaderDelegate({required this.title, required this.count});

  final String title;
  final int count;

  static const double _height = 52;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return Container(
      height: _height,
      // Musí byť nepriehľadná, inak pod ňou presvitá scrollujúci obsah.
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$count items',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SectionHeaderDelegate oldDelegate) =>
      oldDelegate.title != title || oldDelegate.count != count;
}

/// Karta produktu. Obrázok je farebná plocha s ikonou, zľava je odznak
/// položený cez ňu pomocou `Stack` + `Positioned`.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.directions_run,
                      size: 44,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                if (product.discount != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.discount!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onError,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      product.price,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.oldPrice != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          product.oldPrice!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Značka – krúžok s prvým písmenom a názov pod ním.
class BrandChip extends StatelessWidget {
  const BrandChip({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            name.characters.first,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(name, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// Vyhľadávacie pole, ktoré sedí v `bottom` app baru.
class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SearchBar(
        hintText: 'Search shoes',
        elevation: const WidgetStatePropertyAll(0),
        leading: const Icon(Icons.search),
        trailing: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }
}
