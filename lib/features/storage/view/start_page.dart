import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../account/cubit/account_cubit.dart';
import '../../auth/view/auth_page.dart';
import '../../plus/cubit/plus_cubit.dart';
import '../../plus/view/paywall_page.dart';
import '../cubit/storage_cubit.dart';
import 'cloud_flow.dart';

/// Erster Start (und nach dem Update, solange nichts gewählt ist): Wo sollen die Daten liegen?
/// Zwei gleichwertige Karten – lokal (kostenlos, ohne Konto) oder Cloud (Preis im Monat, mit Konto) –
/// und darunter die Anmeldung für ein bestehendes Konto.
class StartPage extends StatelessWidget {
  const StartPage({super.key});

  /// Cloud: neues Konto anlegen, mit einem schon angemeldeten Konto direkt zur Paywall.
  static Future<void> _cloud(BuildContext context) {
    if (context.read<AccountCubit>().state.account.isRegistered) return PaywallPage.open(context);
    return AuthPage.open(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final busy = context.select((StorageCubit s) => s.state.busy);
    final price = CloudFlow.price(context, context.watch<PlusCubit>().state);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xxl, Spacing.l, Spacing.l),
          children: [
            Center(child: AppIconTile(icon: CupertinoIcons.chart_bar_alt_fill, color: c.accent, size: 64)),
            const SizedBox(height: Spacing.l),
            AppText(l10n.startTitle, style: (t) => t.title1, align: TextAlign.center),
            const SizedBox(height: Spacing.s),
            AppText(l10n.startBody, style: (t) => t.subheadline, color: c.textSecondary, align: TextAlign.center),
            const SizedBox(height: Spacing.xl),
            _Option(
              icon: CupertinoIcons.device_phone_portrait,
              color: c.success,
              title: l10n.startLocalTitle,
              price: l10n.startLocalPrice,
              points: [
                (true, l10n.startLocalPointFeatures),
                (true, l10n.startLocalPointPrivate),
                (false, l10n.startLocalPointLimits),
              ],
              action: AppButton(label: l10n.startLocalAction, variant: AppButtonVariant.tinted, onPressed: busy ? null : context.read<StorageCubit>().chooseLocal),
            ),
            const SizedBox(height: Spacing.m),
            _Option(
              icon: CupertinoIcons.cloud_fill,
              color: c.accent,
              title: l10n.startCloudTitle,
              price: l10n.startCloudPrice(price),
              points: [
                (true, l10n.startCloudPointDevices),
                (true, l10n.startCloudPointBackup),
                (true, l10n.startCloudPointShare),
              ],
              action: AppButton(label: l10n.startCloudAction, icon: CupertinoIcons.person_crop_circle_badge_plus, onPressed: busy ? null : () => _cloud(context)),
            ),
            const SizedBox(height: Spacing.s),
            AppButton(
              label: l10n.startSignIn,
              variant: AppButtonVariant.plain,
              onPressed: busy ? null : () => AuthPage.open(context, mode: AuthMode.signIn),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
              child: AppText(l10n.startFooter, style: (t) => t.footnote, color: c.textSecondary, align: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eine Wahl: Symbol, Name, Preis, was dazugehört (✓) und was nicht (–), Knopf.
class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.color, required this.title, required this.price, required this.points, required this.action});

  final IconData icon;
  final Color color;
  final String title;
  final String price;
  final List<(bool, String)> points;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.m,
        children: [
          Row(
            spacing: Spacing.m,
            children: [
              AppIconTile(icon: icon, color: color, size: Sizes.iconTileLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Spacing.xxs,
                  children: [
                    AppText(title, style: (t) => t.title3),
                    AppText(price, style: (t) => t.subheadlineEmphasized, color: color),
                  ],
                ),
              ),
            ],
          ),
          for (final (included, text) in points)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spacing.s,
              children: [
                Icon(
                  included ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.minus_circle,
                  size: 18,
                  color: included ? c.success : c.textTertiary,
                ),
                Expanded(child: AppText(text, style: (t) => t.subheadline, color: included ? null : c.textSecondary)),
              ],
            ),
          action,
        ],
      ),
    );
  }
}
