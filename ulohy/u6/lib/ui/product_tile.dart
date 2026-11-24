import 'package:flutter/material.dart';

import '../model/product.dart';
import '../model/product_slot.dart';

/// Výška obrázka = výška obsahu karty.
///
/// Skeleton aj hotová karta ju musia mať rovnakú, inak by zoznam
/// pri dopĺňaní dát poskakoval pod prstom.
const double _kTileHeight = 80;

/// Obal karty – rovnaké okraje a výplň pre všetky tri stavy položky.
class _TileFrame extends StatelessWidget {
  final Widget child;

  const _TileFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          height: _kTileHeight,
          child: child,
        ),
      ),
    );
  }
}

/// Vykreslí položku podľa jej stavu: skeleton / chyba / dáta.
class ProductSlotTile extends StatelessWidget {
  final ProductSlot slot;
  final VoidCallback onRetry;

  const ProductSlotTile({
    super.key,
    required this.slot,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final product = slot.product;
    if (product != null) return ProductTile(product: product);
    if (slot.error != null) {
      return _ErrorTile(message: slot.error!, onRetry: onRetry);
    }
    return const ProductSkeletonTile();
  }
}

/// Jedna položka zoznamu: obrázok, názov, značka, cena, zľava.
class ProductTile extends StatelessWidget {
  final Product product;

  const ProductTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _TileFrame(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumbnail(url: product.thumbnail),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                // značka v API často chýba -> zástupný text
                Text(
                  product.brand ?? 'Bez značky',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: product.brand == null ? FontStyle.italic : null,
                  ),
                ),
                const Spacer(),
                _PriceRow(product: product),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Položka, ktorá ešte nemá dáta – sivé plochy v tvare karty.
class ProductSkeletonTile extends StatelessWidget {
  const ProductSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return _TileFrame(
      child: _Pulse(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Bone(width: _kTileHeight, height: _kTileHeight, radius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Bone(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  const _Bone(width: 90, height: 12),
                  const Spacer(),
                  Row(
                    children: const [
                      _Bone(width: 70, height: 18),
                      SizedBox(width: 8),
                      _Bone(width: 50, height: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Položka, ktorej dáta sa nepodarilo stiahnuť – s možnosťou skúsiť znova.
class _ErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorTile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _TileFrame(
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Znova')),
        ],
      ),
    );
  }
}

/// Sivý obdĺžnik skeletonu.
class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _Bone({
    required this.width,
    required this.height,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Jemné pulzovanie, aby bolo vidieť, že sa na položke pracuje.
class _Pulse extends StatefulWidget {
  final Widget child;

  const _Pulse({required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: widget.child,
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;

  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: _kTileHeight,
      height: _kTileHeight,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image_not_supported_outlined),
    );

    if (url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: _kTileHeight,
        height: _kTileHeight,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _Bone(
            width: _kTileHeight,
            height: _kTileHeight,
            radius: 8,
          );
        },
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final Product product;

  const _PriceRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!product.hasDiscount) {
      return Text(
        '${product.price.toStringAsFixed(2)} \$',
        style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      );
    }

    return Row(
      children: [
        Text(
          '${product.discountedPrice.toStringAsFixed(2)} \$',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${product.price.toStringAsFixed(2)} \$',
          style: theme.textTheme.bodySmall?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '-${product.discountPercentage.toStringAsFixed(0)} %',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
