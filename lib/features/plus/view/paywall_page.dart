import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/core.dart';
import '../../account/cubit/account_cubit.dart';
import '../../auth/view/auth_page.dart';
import '../../legal/data/legal_document.dart';
import '../../legal/view/legal_page.dart';
import '../../storage/cubit/storage_cubit.dart';
import '../../storage/data/storage_mode.dart';
import '../../storage/view/cloud_flow.dart';
import '../cubit/plus_cubit.dart';
import '../data/plus_store.dart';

/// Kostenkurve Cloud: macht klar, dass die App lokal kostenlos ist und die Cloud den Monatspreis
/// kostet. Nach dem Registrieren, aus den Einstellungen und überall, wo etwas die Cloud braucht.
///
/// Abonnieren geht nur mit Konto (der Kauf gehört dem Konto, nicht dem Gerät); ohne Konto führt der
/// Knopf erst zum Registrieren. Wirksam wird der Kauf erst nach der Bestätigung durch den Server.
/// Pflichtangaben nach App-Store-Regel 3.1.2: Preis und Laufzeit, Verlängerung und Kündigung,
/// Nutzungsbedingungen, Datenschutz, Apples EULA, „Käufe wiederherstellen“.
class PaywallPage extends StatefulWidget {
  /// Wie viele Paywalls offen sind. Ist keine offen, übernimmt der StartGate einen Kauf, der erst
  /// später bestätigt wird („Kaufen anfragen“, Bankfreigabe).
  static int openCount = 0;

  const PaywallPage({super.key});

  static Route<void> route() => CupertinoPageRoute<void>(fullscreenDialog: true, builder: (_) => const PaywallPage());

  static Future<void> open(BuildContext context) => Navigator.of(context).push(route());

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  @override
  void dispose() {
    PaywallPage.openCount--;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    PaywallPage.openCount++;
    final plus = context.read<PlusCubit>();
    if (plus.state.prices.isEmpty || !plus.state.checked) plus.load();
  }

  Future<void> _onEvent(BuildContext context, PlusState state) async {
    final l10n = context.l10n;
    const warn = CupertinoIcons.exclamationmark_circle_fill;
    switch (state.event!.kind) {
      case PlusStoreUpdateKind.unlocked:
        AppToast.show(context, l10n.plusWelcome, icon: CupertinoIcons.cloud_fill);
        // Lokal oder noch nicht gewählt: Daten ziehen jetzt um, der StartGate schließt die Seite.
        if (context.read<StorageCubit>().state.mode != StorageMode.cloud) {
          await CloudFlow.activate(context);
        } else {
          await Navigator.of(context).maybePop();
        }
      case PlusStoreUpdateKind.expired:
        AppToast.show(context, l10n.plusNothingToRestore, icon: warn);
      case PlusStoreUpdateKind.pending:
        AppToast.show(context, l10n.plusPending, icon: CupertinoIcons.clock_fill);
      case PlusStoreUpdateKind.failed:
        AppToast.show(context, l10n.plusFailed, icon: warn);
      case PlusStoreUpdateKind.otherAccount:
        AppToast.show(context, l10n.plusOtherAccount, icon: warn);
      case PlusStoreUpdateKind.canceled:
        break;
    }
  }

  /// „Kostenlos lokal nutzen“: auf dem Start-Weg wird lokal gewählt (der StartGate schließt alles),
  /// sonst ist die App schon lokal und die Seite geht einfach zu.
  Future<void> _stayLocal(BuildContext context) async {
    final storage = context.read<StorageCubit>();
    if (storage.state.mode == null) {
      await storage.chooseLocal();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final mode = context.select((StorageCubit s) => s.state.mode);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<PlusCubit, PlusState>(
          listenWhen: (previous, current) => current.event != null && current.event != previous.event,
          listener: _onEvent,
          builder: (context, s) {
            final price = CloudFlow.price(context, s);
            return ListView(
              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Spacing.xxl),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.s, Spacing.l, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AppIconButton(icon: CupertinoIcons.xmark, semanticLabel: l10n.actionClose, onPressed: () => Navigator.of(context).pop()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
                  child: Column(
                    spacing: Spacing.s,
                    children: [
                      AppIconTile(icon: CupertinoIcons.cloud_fill, color: c.accent, size: 64),
                      const SizedBox(height: Spacing.xs),
                      AppText(l10n.plusTitle, style: (t) => t.title1, align: TextAlign.center),
                      AppText(l10n.cloudPaywallSubtitle(price), style: (t) => t.subheadline, color: c.textSecondary, align: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                Padding(padding: Spacing.screen, child: _Comparison(price: price)),
                const SizedBox(height: Spacing.xl),
                if (s.active)
                  _Active(state: s, switchToCloud: mode != StorageMode.cloud)
                else if (!s.supported)
                  Padding(
                    padding: Spacing.screen,
                    child: AppCard(child: AppText(l10n.plusOnlyIos, style: (t) => t.subheadline, color: c.textSecondary)),
                  )
                else
                  _Purchase(state: s, price: price),
                if (mode != StorageMode.cloud && !s.active) ...[
                  const SizedBox(height: Spacing.s),
                  Padding(
                    padding: Spacing.screen,
                    child: Column(
                      spacing: Spacing.xs,
                      children: [
                        AppButton(
                          label: l10n.cloudStayLocal,
                          icon: CupertinoIcons.device_phone_portrait,
                          variant: AppButtonVariant.tinted,
                          onPressed: s.busy ? null : () => _stayLocal(context),
                        ),
                        AppText(l10n.cloudStayLocalHint, style: (t) => t.footnote, color: c.textSecondary, align: TextAlign.center),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.l),
                const _LegalLinks(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Lokal und Cloud nebeneinander: was jeweils dazugehört und was es kostet.
class _Comparison extends StatelessWidget {
  const _Comparison({required this.price});

  final String price;

  static const _column = 84.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    Widget mark(bool included) => SizedBox(
      width: _column,
      child: Icon(
        included ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.minus_circle,
        size: 20,
        color: included ? c.success : c.textTertiary,
        semanticLabel: included ? l10n.cloudIncluded : l10n.cloudNotIncluded,
      ),
    );
    Widget head(String title, String subtitle, Color color) => SizedBox(
      width: _column,
      child: Column(
        spacing: Spacing.xxs,
        children: [
          AppText(title, style: (t) => t.headline, color: color, align: TextAlign.center),
          AppText(subtitle, style: (t) => t.caption, color: c.textSecondary, align: TextAlign.center),
        ],
      ),
    );
    final rows = [
      (l10n.cloudFeatureAll, true),
      (l10n.cloudFeatureDevices, false),
      (l10n.cloudFeatureBackup, false),
      (l10n.cloudFeatureShare, false),
      (l10n.cloudFeatureReceipts, false),
    ];
    return AppCard(
      child: Column(
        spacing: Spacing.m,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              head(l10n.cloudCompareLocal, l10n.cloudCompareFree, c.textPrimary),
              head(l10n.cloudCompareCloud, l10n.plusPerMonth(price), c.accent),
            ],
          ),
          for (final (feature, local) in rows)
            MergeSemantics(
              child: Row(
                children: [
                  Expanded(child: AppText(feature, style: (t) => t.subheadline)),
                  mark(local),
                  mark(true),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Purchase extends StatelessWidget {
  const _Purchase({required this.state, required this.price});

  final PlusState state;
  final String price;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<PlusCubit>();
    final registered = context.select((AccountCubit a) => a.state.account.isRegistered);
    final available = state.prices.containsKey(PlusStore.monthly);
    return Padding(
      padding: Spacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.s,
        children: [
          if (!registered)
            AppButton(
              label: l10n.startCloudAction,
              icon: CupertinoIcons.person_crop_circle_badge_plus,
              onPressed: () => AuthPage.open(context, paywallNext: false),
            )
          else if (!available)
            AppCard(
              child: state.loaded ? AppText(l10n.plusUnavailable, style: (t) => t.subheadline, color: c.textSecondary) : const CupertinoActivityIndicator(),
            )
          else
            AppButton(label: l10n.cloudSubscribe(price), icon: CupertinoIcons.cloud_fill, onPressed: state.busy ? null : () => cubit.buy(PlusStore.monthly)),
          AppText('${l10n.plusMonthlyDetail}. ${l10n.plusFinePrint}', style: (t) => t.caption, color: c.textSecondary, align: TextAlign.center),
          if (registered) AppButton(label: l10n.plusRestore, variant: AppButtonVariant.plain, onPressed: state.busy ? null : cubit.restore),
        ],
      ),
    );
  }
}

class _Active extends StatelessWidget {
  const _Active({required this.state, required this.switchToCloud});

  final PlusState state;

  /// Abo läuft, die App ist aber noch lokal (z. B. Umzug unterbrochen).
  final bool switchToCloud;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final until = state.status.validUntil;
    return Padding(
      padding: Spacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.s,
        children: [
          AppCard(
            child: Row(
              spacing: Spacing.m,
              children: [
                AppIconTile(icon: CupertinoIcons.checkmark_seal_fill, color: c.success),
                Expanded(
                  child: AppText(until == null ? l10n.plusActive : l10n.plusActiveUntil(context.shortDate(until.toLocal())), style: (t) => t.subheadline),
                ),
              ],
            ),
          ),
          if (switchToCloud) AppButton(label: l10n.cloudContinue, icon: CupertinoIcons.cloud_upload_fill, onPressed: () => CloudFlow.activate(context)),
          if (state.supported)
            AppButton(
              label: l10n.plusManage,
              variant: AppButtonVariant.tinted,
              onPressed: () => launchUrl(Uri.parse(AppConfig.manageSubscriptionsUrl), mode: LaunchMode.externalApplication),
            ),
        ],
      ),
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    Widget link(String label, VoidCallback onTap) => AppPressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xs),
        child: AppText(label, style: (t) => t.footnote, color: c.accent),
      ),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Spacing.s,
      children: [
        link(l10n.legalTerms, () => LegalPage.open(context, LegalDocument.terms)),
        link(l10n.legalPrivacy, () => LegalPage.open(context, LegalDocument.privacy)),
        link(l10n.plusAppleEula, () => launchUrl(Uri.parse(AppConfig.appleEulaUrl), mode: LaunchMode.externalApplication)),
      ],
    );
  }
}
