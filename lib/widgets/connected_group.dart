import 'package:flutter/material.dart';

import '../theme/lockout_theme.dart';

/// A column of rows that reads as one object rather than a stack of cards.
///
/// The first and last child carry large outer corners; everything between
/// them stays small on every corner, and the rows sit 3dp apart. The house
/// document's section 5.2 calls this a grouped list, and it replaces the
/// previous pattern of separate floating cards with drop shadows.
///
/// A single child is large on all four corners — it is simultaneously the
/// first and the last.
class ConnectedGroup extends StatelessWidget {
  final List<Widget> children;

  const ConnectedGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    const end = Radius.circular(LockoutTheme.radiusGroupEnd);
    const inner = Radius.circular(LockoutTheme.radiusRowRest);

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      final first = i == 0;
      final last = i == children.length - 1;

      rows.add(
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: first ? end : inner,
            topRight: first ? end : inner,
            bottomLeft: last ? end : inner,
            bottomRight: last ? end : inner,
          ),
          child: children[i],
        ),
      );

      if (!last) {
        rows.add(const SizedBox(height: LockoutTheme.groupGap));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
