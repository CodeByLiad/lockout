import '../../theme/lockout_theme.dart';
import 'package:flutter/material.dart';
import '../../data/food_library.dart';
import '../../data/food_search.dart';
import '../../theme/lockout_shapes.dart';
import 'nv_expressive.dart';
import 'nv_grouped_list.dart';
import 'nv_button.dart';

class PickedFood {
  final String name;
  final int kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final String serving;
  final String ingredients;
  const PickedFood({
    required this.name,
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    this.serving = '1 serving',
    this.ingredients = '',
  });
  factory PickedFood.fromLibrary(LibraryFood f, double servings) => PickedFood(
    name: servings == 1
        ? f.name
        : '${f.name} (${_trim(servings)}x ${f.serving})',
    kcal: (f.kcal * servings).round(),
    proteinG: _round(f.proteinG * servings),
    carbG: _round(f.carbG * servings),
    fatG: _round(f.fatG * servings),
    serving: f.serving,
    ingredients: f.ingredients,
  );
  factory PickedFood.custom(String name) =>
      PickedFood(name: name, kcal: 0, proteinG: 0, carbG: 0, fatG: 0);
  static double _round(double v) => double.parse(v.toStringAsFixed(1));
  static String _trim(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

Future<PickedFood?> showFoodPicker(BuildContext context) => Navigator.of(
  context,
).push<PickedFood>(MaterialPageRoute(builder: (_) => const NvFoodCatalog()));

class NvFoodCatalog extends StatefulWidget {
  const NvFoodCatalog({super.key});
  @override
  State<NvFoodCatalog> createState() => _NvFoodCatalogState();
}

class _NvFoodCatalogState extends State<NvFoodCatalog> {
  final _search = TextEditingController();
  String _query = '';
  String _category = 'All';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = _category == 'All'
        ? FoodLibrary.all
        : FoodLibrary.byCategory(_category);
    final matches = _query.trim().isEmpty
        ? null
        : searchFoods(_query, source: source);
    final results = matches == null
        ? source
        : matches.map((h) => h.item).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Find food')),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: NvField(
                controller: _search,
                label: 'Search foods',
                hint: 'Dish, cuisine or ingredient',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (final group in ['All', ...FoodLibrary.categories])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(group),
                        selected: group == _category,
                        onSelected: (_) => setState(() => _category = group),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '${results.length} foods',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text('No matching food. Add your own below.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 3),
                      itemBuilder: (_, i) {
                        final f = results[i];
                        final note = matches == null
                            ? null
                            : matches[i].matchedVia;
                        return NvListItem(
                          leading: NvIconBadge(
                            icon: Icons.restaurant_rounded,
                            shape:
                                LockoutShape.values[[14, 8, 11, 6, 9][i % 5]],
                            tone: NvTone.values[i % 3],
                          ),
                          title: f.name,
                          supporting:
                              '${f.serving} · ${f.kcal} kcal${note == null ? '' : '\n$note'}',
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(
                            context,
                          ).pop(PickedFood.fromLibrary(f, 1)),
                        );
                      },
                    ),
            ),
            if (_query.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(LockoutTheme.screenPadding),
                child: NvButton(
                  variant: NvButtonVariant.tonal,
                  label: 'Add custom: ${_query.trim()}',
                  icon: Icons.add_rounded,
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(PickedFood.custom(_query.trim())),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
