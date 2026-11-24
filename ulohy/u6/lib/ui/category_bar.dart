import 'package:flutter/material.dart';

import '../model/category.dart';

/// Vodorovná lišta kategórií nad zoznamom.
///
/// Má **vlastné stavy**, nezávislé od zoznamu produktov: kým sa kategórie
/// načítavajú, sú na mieste sivé zástupné čipy; keď zlyhajú, je tam hláška
/// s možnosťou skúsiť znova a zoznam produktov funguje ďalej bez filtra.
class CategoryBar extends StatelessWidget {
  final List<Category> categories;
  final bool loading;
  final String? error;

  /// `null` = vybrané *Všetko*.
  final String? selectedSlug;

  final ValueChanged<String?> onSelect;
  final VoidCallback onRetry;

  const CategoryBar({
    super.key,
    required this.categories,
    required this.loading,
    required this.error,
    required this.selectedSlug,
    required this.onSelect,
    required this.onRetry,
  });

  static const double _height = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return SizedBox(
        height: _height,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: 5,
          itemBuilder: (context, index) => Container(
            width: 86,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return SizedBox(
        height: _height,
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Kategórie sa nenačítali',
                style: theme.textTheme.bodySmall,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Znova')),
            const SizedBox(width: 4),
          ],
        ),
      );
    }

    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          // prvý čip je „Všetko“ – zruší filter
          final slug = index == 0 ? null : categories[index - 1].slug;
          final label = index == 0 ? 'Všetko' : categories[index - 1].name;

          return ChoiceChip(
            label: Text(label),
            selected: slug == selectedSlug,
            onSelected: (_) => onSelect(slug),
          );
        },
      ),
    );
  }
}
