import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/core.dart';
import '../../legal/data/legal_document.dart';
import '../../legal/view/legal_page.dart';
import '../cubit/plus_cubit.dart';
import '../data/plus_store.dart';

/// Kostenkurve Plus: Vorteile, Monats- oder Jahresabo, Kaufen, Wiederherstellen, rechtliche Links
/// (App-Store-Regel 3.1.2: Laufzeit, Preis, Nutzungsbedingungen und Datenschutz auf der Seite).
class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(CupertinoPageRoute<void>(fullscreenDialog: true, builder: (_) => const PaywallPage()));

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  var _product = PlusStore.yearly;

  @override
  void initState() {
    super.initState();
    final plus = context.read<PlusCubit>();
    if (plus.state.prices.isEmpty) plus.load();
  }

  void _onEvent(BuildContext context, PlusState state) {
    final l10n = context.l10n;
    const warn = CupertinoIcons.exclamationmark_circle_fill;
    switch (state.event!.kind) {
      case PlusStoreUpdateKind.unlocked:
        AppToast.show(context, l10n.plusWelcome, icon: CupertinoIcons.sparkles);
        Navigator.of(context).maybePop();
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<PlusCubit, PlusState>(
          listenWhen: (previous, current) => current.event != null && current.event != previous.event,
          listener: _onEvent,
          builder: (context, s) => ListView(
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
                    AppIconTile(icon: CupertinoIcons.sparkles, color: c.accent, size: 64),
                    const SizedBox(height: Spacing.xs),
                    AppText(l10n.plusTitle, style: (t) => t.title1, align: TextAlign.center),
                    AppText(l10n.plusSubtitle, style: (t) => t.subheadline, color: c.textSecondary, align: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
              AppListGroup(
                children: [
                  _Benefit(icon: CupertinoIcons.paperclip, color: c.accent, title: l10n.plusBenefitReceipts, body: l10n.plusBenefitReceiptsBody),
                  _Benefit(icon: CupertinoIcons.cloud_fill, color: c.success, title: l10n.plusBenefitStorage, body: l10n.plusBenefitStorageBody),
                  _Benefit(icon: CupertinoIcons.person_2_fill, color: c.warning, title: l10n.plusBenefitShared, body: l10n.plusBenefitSharedBody),
                ],
              ),
              const SizedBox(height: Spacing.xl),
              if (s.active)
                _Active(state: s)
              else if (!s.supported)
                Padding(
                  padding: Spacing.screen,
                  child: AppCard(child: AppText(l10n.plusOnlyIos, style: (t) => t.subheadline, color: c.textSecondary)),
                )
              else
                _Purchase(state: s, product: _product, onProduct: (p) => setState(() => _product = p)),
              const SizedBox(height: Spacing.l),
              const _LegalLinks(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.color, required this.title, required this.body});

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => AppListRow(leading: AppIconTile(icon: icon, color: color), title: title, subtitle: body, chevron: false);
}

class _Purchase extends StatelessWidget {
  const _Purchase({required this.state, required this.product, required this.onProduct});

  final PlusState state;
  final String product;
  final ValueChanged<String> onProduct;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<PlusCubit>();
    final yearly = state.prices[PlusStore.yearly], monthly = state.prices[PlusStore.monthly];
    final saving = state.yearlySaving;
    final available = state.prices.containsKey(product);
    return Padding(
      padding: Spacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.s,
        children: [
          if (state.prices.isEmpty)
            AppCard(
              child: state.loaded
                  ? AppText(l10n.plusUnavailable, style: (t) => t.subheadline, color: c.textSecondary)
                  : const CupertinoActivityIndicator(),
            )
          else ...[
            if (yearly != null)
              _PlanCard(
                title: l10n.plusYearly,
                price: l10n.plusPerYear(yearly.label),
                detail: l10n.plusYearlyDetail(context.price(yearly.raw / 12, yearly.currency)),
                badge: saving != null && saving > 0.05 ? l10n.plusSave((saving * 100).floor()) : null,
                selected: product == PlusStore.yearly,
                onTap: () => onProduct(PlusStore.yearly),
              ),
            if (monthly != null)
              _PlanCard(
                title: l10n.plusMonthly,
                price: l10n.plusPerMonth(monthly.label),
                detail: l10n.plusMonthlyDetail,
                selected: product == PlusStore.monthly,
                onTap: () => onProduct(PlusStore.monthly),
              ),
          ],
          const SizedBox(height: Spacing.xs),
          AppButton(label: l10n.plusSubscribe, onPressed: state.busy || !available ? null : () => cubit.buy(product)),
          AppText(l10n.plusFinePrint, style: (t) => t.caption, color: c.textSecondary, align: TextAlign.center),
          AppButton(label: l10n.plusRestore, variant: AppButtonVariant.plain, onPressed: state.busy ? null : cubit.restore),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.title, required this.price, required this.detail, required this.selected, required this.onTap, this.badge});

  final String title;
  final String price;
  final String detail;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: AppCard(
        onTap: onTap,
        color: selected ? c.accentSoft : null,
        child: Row(
          spacing: Spacing.m,
          children: [
            Icon(selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle, color: selected ? c.accent : c.textTertiary),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spacing.xxs,
                children: [
                  Row(
                    spacing: Spacing.s,
                    children: [
                      Flexible(child: AppText(title, style: (t) => t.headline)),
                      if (badge != null) AppChip(label: badge!, background: c.accent, foreground: c.onAccent),
                    ],
                  ),
                  AppText(detail, style: (t) => t.footnote, color: c.textSecondary),
                ],
              ),
            ),
            AppText(price, style: (t) => t.numberM),
          ],
        ),
      ),
    );
  }
}

class _Active extends StatelessWidget {
  const _Active({required this.state});

  final PlusState state;

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
