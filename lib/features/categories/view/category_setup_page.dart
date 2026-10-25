import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../cubit/category_setup_cubit.dart';
import '../data/category_templates.dart';
import '../../sharing/view/join_sheet.dart';
import '../../storage/view/cloud_flow.dart';
import 'add_category_sheet.dart';
import 'category_detail_page.dart';
import 'widgets/appearance_pickers.dart';
import 'widgets/field_row.dart';

/// Neue Kategorie: Name, Symbol, Farbe und – bei einer Vorlage – welche Felder mitkommen.
/// Nach dem Anlegen geht es direkt in die Detailansicht der neuen Kategorie.
class CategorySetupPage extends StatelessWidget {
  const CategorySetupPage({super.key, this.template});

  final CategoryTemplate? template;

  /// Ganzer Ablauf: Auswahl im Sheet, dann diese Seite.
  static Future<void> start(BuildContext context) async {
    final choice = await AddCategorySheet.show(context);
    if (choice == null || !context.mounted) return;
    if (choice.join) {
      // Beitreten gibt es nur in der Cloud.
      if (await CloudFlow.require(context, context.l10n.cloudRequiredShare) && context.mounted) await JoinSheet.show(context);
      return;
    }
    await Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => CategorySetupPage(template: choice.template)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => lookup<CategorySetupCubit>(param1: template), child: const _SetupView());
  }
}

class _SetupView extends StatefulWidget {
  const _SetupView();

  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  late final _name = TextEditingController(text: context.read<CategorySetupCubit>().state.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _onEvent(BuildContext context, CategorySetupState state) {
    final event = state.event!;
    if (event.categoryId case final String id) {
      AppToast.show(context, context.l10n.setupCreated(event.name ?? ''));
      Navigator.of(context).pushReplacement(CupertinoPageRoute<void>(builder: (_) => CategoryDetailPage(categoryId: id)));
    } else {
      AppToast.show(context, context.l10n.errorSave, icon: CupertinoIcons.exclamationmark_circle_fill);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<CategorySetupCubit>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<CategorySetupCubit, CategorySetupState>(
          listenWhen: (previous, current) => current.event != null && current.event != previous.event,
          listener: _onEvent,
          builder: (context, state) {
            final template = state.template;
            return AppActionBar(
              action: AppButton(label: l10n.setupCreate, icon: CupertinoIcons.checkmark, onPressed: state.canCreate ? cubit.create : null),
              content: ListView(
                padding: EdgeInsets.only(bottom: AppActionBar.inset(context)),
                children: [
                  AppHeader(title: template?.name ?? l10n.newCategoryCustom, onBack: () => Navigator.of(context).pop()),
                  Padding(
                    padding: Spacing.screen,
                    child: Row(
                      spacing: Spacing.m,
                      children: [
                        AppIconTile(icon: state.icon.data, color: c.swatch(state.swatch), size: 52),
                        Expanded(
                          child: AppTextField(
                            controller: _name,
                            hint: l10n.setupNameHint,
                            maxLength: CategorySetupState.maxName,
                            textInputAction: TextInputAction.done,
                            onChanged: cubit.setName,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SectionHeader(title: l10n.setupSymbol),
                  Padding(
                    padding: Spacing.screen,
                    child: AppCard(child: IconPicker(selected: state.icon, swatch: state.swatch, onSelect: cubit.setIcon)),
                  ),
                  SectionHeader(title: l10n.setupColor),
                  Padding(
                    padding: Spacing.screen,
                    child: AppCard(child: SwatchPicker(selected: state.swatch, onSelect: cubit.setSwatch)),
                  ),
                  if (template == null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.l, Spacing.xl, 0),
                      child: AppText(l10n.setupCustomHint, style: (t) => t.footnote, color: c.textSecondary),
                    )
                  else ...[
                    SectionHeader(title: l10n.setupFields),
                    for (final (t, tracker) in template.trackers.indexed) ...[
                      if (template.trackers.length > 1)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.s, Spacing.xl, Spacing.xs),
                          child: AppText(tracker.name.toUpperCase(), style: (t) => t.footnoteEmphasized, color: c.textSecondary),
                        ),
                      AppListGroup(
                        footer: t == template.trackers.length - 1 ? l10n.setupFieldsHint : null,
                        children: [
                          for (final (f, field) in tracker.fields.indexed)
                            FieldRow(
                              field: field,
                              swatch: state.swatch,
                              trailing: AppSwitch(value: state.isIncluded(t, f), semanticLabel: field.name, onChanged: (_) => cubit.toggleField(t, f)),
                            ),
                        ],
                      ),
                      const SizedBox(height: Spacing.s),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
