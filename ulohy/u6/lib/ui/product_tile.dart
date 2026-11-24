import 'package:flutter/material.dart';

import '../model/product.dart';

/// Jedna položka zoznamu: obrázok, názov, značka, cena, zľava.
class ProductTile extends StatelessWidget {
  final Product product;

  const ProductTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
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
                      fontStyle:
                          product.brand == null ? FontStyle.italic : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PriceRow(product: product),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;

  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 80,
      height: 80,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image_not_supported_outlined),
    );

    if (url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 80,
            height: 80,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
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
        style: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
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
