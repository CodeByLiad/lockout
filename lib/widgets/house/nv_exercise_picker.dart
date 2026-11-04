import '../../theme/lockout_theme.dart';
import 'package:flutter/material.dart';
import '../../data/exercise_library.dart';
import '../../data/food_search.dart';
import '../../theme/lockout_shapes.dart';
import 'nv_expressive.dart';
import 'nv_grouped_list.dart';
import 'nv_button.dart';

class PickedExercise {
  final String name;
  final String muscleGroup;
  final int sets;
  final int repsMin;
  final int repsMax;
  const PickedExercise({
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
  });
  factory PickedExercise.fromLibrary(LibraryExercise e) => PickedExercise(
    name: e.name,
    muscleGroup: e.muscleGroup,
    sets: e.defaultSets,
    repsMin: e.defaultRepsMin,
    repsMax: e.defaultRepsMax,
  );
  factory PickedExercise.custom(String name) => PickedExercise(
    name: name,
    muscleGroup: '',
    sets: 3,
    repsMin: 10,
    repsMax: 12,
  );
}

Future<PickedExercise?> showExercisePicker(BuildContext context) =>
    Navigator.of(context).push<PickedExercise>(
      MaterialPageRoute(builder: (_) => const NvExerciseCatalog()),
    );

Future<List<PickedExercise>?> showExercisesPicker(BuildContext context) =>
    Navigator.of(context).push<List<PickedExercise>>(
      MaterialPageRoute(
        builder: (_) => const NvExerciseCatalog(multiSelect: true),
      ),
    );

class NvExerciseCatalog extends StatefulWidget {
  final bool multiSelect;
  const NvExerciseCatalog({super.key, this.multiSelect = false});
  @override
  State<NvExerciseCatalog> createState() => _NvExerciseCatalogState();
}

class _NvExerciseCatalogState extends State<NvExerciseCatalog> {
  final _search = TextEditingController();
  String _query = '';
  String _group = 'All';
  final Map<String, PickedExercise> _selected = {};
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = _group == 'All'
        ? ExerciseLibrary.all
        : ExerciseLibrary.byGroup(_group);
    final results = _query.trim().isEmpty
        ? source
        : searchExercises(_query, source: source).map((h) => h.item).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Add exercises')),
      bottomNavigationBar: widget.multiSelect && _selected.isNotEmpty
          ? SafeArea(
              top: false,
              minimum: const EdgeInsets.all(LockoutTheme.screenPadding),
              child: NvButton(
                variant: NvButtonVariant.filled,
                label:
                    'Add ${_selected.length} ${_selected.length == 1 ? 'exercise' : 'exercises'}',
                onPressed: () =>
                    Navigator.of(context).pop(_selected.values.toList()),
              ),
            )
          : null,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: NvField(
                controller: _search,
                label: 'Search exercises',
                hint: 'Name, muscle or equipment',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (final group in ['All', ...ExerciseLibrary.muscleGroups])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(group),
                        selected: group == _group,
                        onSelected: (_) => setState(() => _group = group),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '${results.length} exercises',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching exercises. Create your own below.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 3),
                      itemBuilder: (_, i) {
                        final e = results[i];
                        return NvListItem(
                          leading: NvIconBadge(
                            icon: Icons.fitness_center_rounded,
                            shape:
                                LockoutShape.values[[11, 8, 14, 6, 9][i % 5]],
                            tone: NvTone.values[i % 3],
                          ),
                          title: e.name,
                          supporting: '${e.muscleGroup} · ${e.equipment}',
                          trailing: Icon(
                            _selected.containsKey(e.name)
                                ? Icons.check_circle_rounded
                                : Icons.add_rounded,
                          ),
                          onTap: () {
                            if (!widget.multiSelect) {
                              Navigator.of(
                                context,
                              ).pop(PickedExercise.fromLibrary(e));
                              return;
                            }
                            setState(() {
                              if (_selected.containsKey(e.name)) {
                                _selected.remove(e.name);
                              } else {
                                _selected[e.name] = PickedExercise.fromLibrary(
                                  e,
                                );
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            if (_query.trim().isNotEmpty &&
                ExerciseLibrary.findByName(_query) == null)
              Padding(
                padding: const EdgeInsets.all(LockoutTheme.screenPadding),
                child: NvButton(
                  variant: NvButtonVariant.tonal,
                  label: 'Create custom: ${_query.trim()}',
                  icon: Icons.add_rounded,
                  onPressed: () {
                    final picked = PickedExercise.custom(_query.trim());
                    if (!widget.multiSelect) {
                      Navigator.of(context).pop(picked);
                      return;
                    }
                    setState(() {
                      _selected[picked.name] = picked;
                      _search.clear();
                      _query = '';
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
