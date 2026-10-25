part of 'what_if_cubit.dart';

/// Ein Tracker, dessen Preise sich durchspielen lassen.
class WhatIfOption extends Equatable {
  const WhatIfOption({required this.category, required this.tracker, required this.fields});

  final Category category;
  final Tracker tracker;
  final List<FieldDefinition> fields;

  @override
  List<Object?> get props => [category, tracker, fields];
}

class WhatIfState extends Equatable {
  const WhatIfState({this.options = const [], this.selected, this.inputs = const {}, this.result});

  /// Tracker mit Arbeitspreis oder wiederkehrenden Kosten, deren Kosten hier zählen.
  /// Steckt ein Tracker in einer Kategorie, die es hier nicht (mehr) gibt, zählen seine Kosten selbst.
  factory WhatIfState.initial(WhatIfArgs args) {
    final visible = {for (final c in args.categories) if (!c.isArchived) c.id};
    final options = [
      for (final c in args.categories)
        for (final t in c.trackers)
          if ((t.includedIn == null || t.includedIn == c.id || !visible.contains(t.includedIn)) && WhatIf.priceFields(t).isNotEmpty) WhatIfOption(category: c, tracker: t, fields: WhatIf.priceFields(t)),
    ];
    final first = options.firstOrNull;
    return WhatIfState(options: options, selected: first, result: first == null ? null : WhatIf.of(first.tracker, args.today, const {}));
  }

  final List<WhatIfOption> options;
  final WhatIfOption? selected;

  /// Eingaben je Feld-Id (leer = heutiger Preis).
  final Map<String, String> inputs;
  final WhatIf? result;

  WhatIfState copyWith({WhatIfOption? selected, Map<String, String>? inputs, WhatIf? result}) =>
      WhatIfState(options: options, selected: selected ?? this.selected, inputs: inputs ?? this.inputs, result: result ?? this.result);

  @override
  List<Object?> get props => [options, selected, inputs, result];
}
