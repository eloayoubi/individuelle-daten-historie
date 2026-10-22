import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../cubit/what_if_cubit.dart';
import '../data/what_if.dart';

/// Was wäre wenn: neue Preise eines Trackers eintippen und die Prognose fürs nächste Jahr
/// vorher/nachher vergleichen – z. B. vor einem Anbieterwechsel.
class WhatIfSheet extends StatelessWidget {
  const WhatIfSheet({super.key});

  static Future<void> show(BuildContext context, {required List<Category> categories, required DateTime today}) {
    final args = WhatIfArgs(categories: categories, today: today, decimalSeparator: context.decimalSeparator);
    return AppSheet.show<void>(
      context,
      title: context.l10n.whatIfTitle,
      child: BlocProvider(create: (_) => lookup<WhatIfCubit>(param1: args), child: const WhatIfSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<WhatIfCubit>();
    final today = cubit.args.today;
    return BlocBuilder<WhatIfCubit, WhatIfState>(
      builder: (context, s) {
        final selected = s.selected;
        if (selected == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.xl, Spacing.xl),
            child: AppText(l10n.whatIfEmpty, style: (t) => t.subheadline, color: c.textSecondary),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Spacing.m,
            children: [
              AppText(l10n.whatIfBody('${today.year + 1}'), style: (t) => t.subheadline, color: c.textSecondary),
              if (s.options.length > 1)
                Wrap(
                  spacing: Spacing.s,
                  runSpacing: Spacing.s,
                  children: [
                    for (final o in s.options)
                      AppPressable(
                        onTap: () => cubit.select(o.tracker.id),
                        child: AppChip(
                          label: o.category.trackers.length > 1 ? context.joinParts([o.category.name, o.tracker.name]) : o.category.name,
                          icon: o.category.icon.data,
                          background: o == selected ? c.accentSoft : null,
                          foreground: o == selected ? c.accent : null,
                        ),
                      ),
                  ],
                ),
              for (final field in selected.fields)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: Spacing.xs,
                  children: [
                    AppTextField(
                      key: ValueKey('${selected.tracker.id}-${field.id}'),
                      label: field.name,
                      color: c.surfaceRaised,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffix: field.unit == null ? null : AppText(field.unit!, style: (t) => t.body, color: c.textSecondary),
                      onChanged: (text) => cubit.setInput(field.id, text),
                    ),
                    if (WhatIf.current(selected.tracker, field, today) case final double now)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
                        child: AppText(l10n.whatIfCurrent(context.fieldValue(field, now)), style: (t) => t.footnote, color: c.textSecondary),
                      ),
                  ],
                ),
              if (s.result case final WhatIf r) _Result(result: r, year: today.year + 1),
            ],
          ),
        );
      },
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.result, required this.year});

  final WhatIf result;
  final int year;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final delta = result.delta;
    final changed = delta.abs() >= 0.5;
    return AppCard(
      color: c.spotlight,
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.xs,
        children: [
          AppText(l10n.homeForecastTitle('$year').toUpperCase(), style: (t) => t.footnoteEmphasized, color: c.onSpotlightSecondary),
          AppText(context.euros(result.after), style: (t) => t.numberXL, color: c.onSpotlight),
          AppText(
            changed ? l10n.whatIfDelta('${delta > 0 ? '+' : '−'}${context.euros(delta.abs())}', context.euros(result.before)) : l10n.whatIfSame,
            style: (t) => t.subheadlineEmphasized,
            color: !changed ? c.onSpotlightSecondary : (delta > 0 ? c.spotlightDanger : c.spotlightSuccess),
          ),
        ],
      ),
    );
  }
}
