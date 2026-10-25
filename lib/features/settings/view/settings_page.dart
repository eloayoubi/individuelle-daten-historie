import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../account/cubit/account_cubit.dart';
import '../../account/view/account_page.dart';
import '../../attachments/data/attachments_repository.dart';
import '../../auth/view/auth_page.dart';
import '../../categories/data/categories_repository.dart';
import '../../legal/data/legal_document.dart';
import '../../legal/view/legal_page.dart';
import '../../plus/cubit/plus_cubit.dart';
import '../../plus/view/paywall_page.dart';
import '../../reminders/cubit/reminders_cubit.dart';
import '../../storage/cubit/storage_cubit.dart';
import '../../storage/view/cloud_flow.dart';
import '../cubit/appearance_cubit.dart';
import '../data/data_export.dart';

/// Einstellungen: Speicherort (lokal oder Cloud, Konto, Abo), Darstellung (Automatisch / Hell /
/// Dunkel), Erinnerungen, Datenexport, Rechtliches und ein Satz zur App.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.only(bottom: Spacing.tabBarClearance),
      children: [
        AppHeader(title: l10n.tabSettings),
        SectionHeader(title: l10n.settingsStorageTitle),
        const _StorageGroup(),
        SectionHeader(title: l10n.settingsAppearance),
        Padding(
          padding: Spacing.screen,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.m,
              children: [
                BlocBuilder<AppearanceCubit, ThemeMode>(
                  builder: (context, mode) => AppSegmented<ThemeMode>(
                    value: mode,
                    segments: {
                      ThemeMode.system: l10n.appearanceSystem,
                      ThemeMode.light: l10n.appearanceLight,
                      ThemeMode.dark: l10n.appearanceDark,
                    },
                    onChanged: context.read<AppearanceCubit>().select,
                  ),
                ),
                AppText(l10n.settingsAppearanceHint, style: (t) => t.footnote, color: c.textSecondary),
              ],
            ),
          ),
        ),
        SectionHeader(title: l10n.settingsReminders),
        BlocBuilder<RemindersCubit, RemindersState>(
          builder: (context, reminders) => AppListGroup(
            footer: reminders.denied ? l10n.settingsRemindersDenied : l10n.settingsRemindersFooter,
            children: [
              AppListRow(
                leading: AppIconTile(icon: CupertinoIcons.bell_fill, color: c.danger),
                title: l10n.settingsNotifications,
                trailing: AppSwitch(
                  value: reminders.enabled,
                  semanticLabel: l10n.settingsNotifications,
                  onChanged: reminders.loaded ? context.read<RemindersCubit>().setEnabled : null,
                ),
              ),
            ],
          ),
        ),
        SectionHeader(title: l10n.settingsData),
        AppListGroup(footer: l10n.settingsExportFooter, children: const [_ExportRow()]),
        SectionHeader(title: l10n.settingsLegal),
        AppListGroup(
          children: [
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.hand_raised_fill, color: c.accent),
              title: l10n.legalPrivacy,
              onTap: () => LegalPage.open(context, LegalDocument.privacy),
            ),
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.doc_text_fill, color: c.textSecondary),
              title: l10n.legalTerms,
              onTap: () => LegalPage.open(context, LegalDocument.terms),
            ),
            AppListRow(
              leading: AppIconTile(icon: CupertinoIcons.info_circle_fill, color: c.textSecondary),
              title: l10n.legalImprint,
              onTap: () => LegalPage.open(context, LegalDocument.imprint),
            ),
          ],
        ),
        SectionHeader(title: l10n.settingsAbout),
        Padding(
          padding: Spacing.screen,
          child: AppCard(child: AppText(l10n.settingsAboutBody, style: (t) => t.subheadline, color: c.textSecondary)),
        ),
      ],
    );
  }
}

/// Speicherort: lokal (kostenlos) mit „Cloud aktivieren“ und Anmeldung, oder Cloud mit Konto, Abo
/// samt belegtem Speicher und „Auf dieses Gerät holen“.
class _StorageGroup extends StatelessWidget {
  const _StorageGroup();

  Future<void> _moveToLocal(BuildContext context) async {
    final l10n = context.l10n;
    final storage = context.read<StorageCubit>();
    final ok = await AppDialog.confirm(context, title: l10n.settingsMoveLocalTitle, message: l10n.settingsMoveLocalBody, confirmLabel: l10n.settingsMoveLocal);
    if (ok) await storage.moveToLocal();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final account = context.select((AccountCubit a) => a.state.account);
    final plus = context.watch<PlusCubit>().state;
    final cloud = context.select((StorageCubit s) => s.state.isCloud);
    final accountRow = AppListRow(
      leading: AppIconTile(icon: CupertinoIcons.person_crop_circle_fill, color: account.isRegistered ? c.success : c.warning),
      title: account.displayName.isEmpty ? l10n.accountTitle : account.displayName,
      subtitle: account.isAnonymous ? l10n.settingsAccountAnonymous : (account.email ?? l10n.accountSecuredTitle),
      onTap: () => AccountPage.open(context),
    );
    if (cloud) {
      return AppListGroup(
        footer: l10n.settingsStorageFooterCloud,
        children: [
          accountRow,
          AppListRow(
            leading: AppIconTile(icon: CupertinoIcons.cloud_fill, color: c.accent),
            title: l10n.plusTitle,
            subtitleWidget: plus.active ? const _Usage() : null,
            subtitle: plus.active ? null : l10n.settingsPlusHint,
            trailing: plus.active ? AppChip(label: l10n.plusBadgeActive, background: c.accentSoft, foreground: c.accent) : null,
            onTap: () => PaywallPage.open(context),
          ),
          AppListRow(
            leading: AppIconTile(icon: CupertinoIcons.device_phone_portrait, color: c.success),
            title: l10n.settingsMoveLocal,
            onTap: () => _moveToLocal(context),
          ),
        ],
      );
    }
    return AppListGroup(
      footer: l10n.settingsStorageFooterLocal,
      children: [
        AppListRow(
          leading: AppIconTile(icon: CupertinoIcons.device_phone_portrait, color: c.success),
          title: l10n.settingsStorageLocal,
          subtitle: l10n.settingsStorageLocalHint,
          trailing: Icon(CupertinoIcons.checkmark_alt, color: c.accent),
          chevron: false,
        ),
        AppListRow(
          leading: AppIconTile(icon: CupertinoIcons.cloud_fill, color: c.accent),
          title: l10n.settingsCloudActivate,
          subtitle: l10n.settingsCloudActivateHint(CloudFlow.price(context, plus)),
          onTap: () => plus.active && account.isRegistered ? CloudFlow.activate(context) : PaywallPage.open(context),
        ),
        if (account.isRegistered)
          accountRow
        else
          AppListRow(
            leading: AppIconTile(icon: CupertinoIcons.person_crop_circle_fill, color: c.textSecondary),
            title: l10n.accountSignIn,
            onTap: () => AuthPage.open(context, mode: AuthMode.signIn),
          ),
      ],
    );
  }
}

class _Usage extends StatelessWidget {
  const _Usage();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FutureBuilder(
      future: lookup<AttachmentsRepository>().usage(),
      builder: (context, snap) => AppText(
        context.l10n.settingsStorage(context.fileSize(snap.data ?? 0), context.fileSize(AttachmentsRepository.quotaBytes)),
        style: (t) => t.footnote,
        color: c.textSecondary,
      ),
    );
  }
}

class _ExportRow extends StatefulWidget {
  const _ExportRow();

  @override
  State<_ExportRow> createState() => _ExportRowState();
}

class _ExportRowState extends State<_ExportRow> {
  var _busy = false;

  Future<void> _export() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final labels = ExportLabels(
        header: [
          l10n.exportCategory,
          l10n.exportTracker,
          l10n.entryDate,
          l10n.exportField,
          l10n.exportValue,
          l10n.exportUnit,
          l10n.exportNote,
          l10n.entryPeriodFrom,
          l10n.entryPeriodTo,
        ],
        yes: l10n.toggleYes,
        no: l10n.toggleNo,
        decimalSeparator: context.decimalSeparator,
      );
      final files = await DataExport.files(lookup<CategoriesRepository>(), labels);
      if (mounted) await AppShare.files(context, files, subject: l10n.exportSubject);
    } catch (_) {
      if (mounted) AppToast.show(context, l10n.exportFailed, icon: CupertinoIcons.exclamationmark_circle_fill);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppListRow(
      leading: AppIconTile(icon: CupertinoIcons.square_arrow_up_fill, color: c.success),
      title: context.l10n.settingsExport,
      trailing: _busy ? const CupertinoActivityIndicator() : null,
      onTap: _busy ? null : _export,
    );
  }
}
