import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/tracking.dart';
import '../../../core/utils/numbers.dart';
import '../data/what_if.dart';

part 'what_if_state.dart';

/// Wofür durchgespielt wird: Kategorien der Prognose, heutiger Tag, Dezimaltrenner der Eingabe.
class WhatIfArgs {
  const WhatIfArgs({required this.categories, required this.today, this.decimalSeparator = ','});

  final List<Category> categories;
  final DateTime today;
  final String decimalSeparator;
}

/// Was wäre wenn: Tracker wählen, neue Preise eintippen, Prognose vorher/nachher sehen.
class WhatIfCubit extends Cubit<WhatIfState> {
  WhatIfCubit(this.args) : super(WhatIfState.initial(args));

  final WhatIfArgs args;

  void select(String trackerId) {
    final option = state.options.where((o) => o.tracker.id == trackerId).firstOrNull;
    if (option == null || trackerId == state.selected?.tracker.id) return;
    emit(state.copyWith(selected: option, inputs: const {}, result: WhatIf.of(option.tracker, args.today, const {})));
  }

  void setInput(String fieldId, String text) {
    final option = state.selected;
    if (option == null) return;
    final inputs = {...state.inputs, fieldId: text};
    final prices = <String, double>{
      for (final MapEntry(:key, :value) in inputs.entries)
        if (parseNumber(value, decimalSeparator: args.decimalSeparator) case final num n) key: n.toDouble(),
    };
    emit(state.copyWith(inputs: inputs, result: WhatIf.of(option.tracker, args.today, prices)));
  }
}
