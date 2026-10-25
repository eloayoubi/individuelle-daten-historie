import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../account/cubit/account_cubit.dart';
import '../../plus/view/paywall_page.dart';
import '../cubit/storage_cubit.dart';

/// In der Cloud, aber das Abo ist beendet: Die Daten sind sicher und lesbar, ändern sperrt der
/// Server. Verlängern, kostenlos aufs Gerät holen oder abmelden.
class CloudPausedPage extends StatelessWidget {
  const CloudPausedPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    final l10n = context.l10n;
    final account = context.read<AccountCubit>();
    final ok = await AppDialog.confirm(context, title: l10n.accountSignOutTitle, message: l10n.accountSignOutBody, confirmLabel: l10n.accountSignOut, destructive: true);
    if (ok) await account.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final busy = context.select((StorageCubit s) => s.state.busy) || context.select((AccountCubit a) => a.state.busy);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xxxl, Spacing.l, Spacing.l),
          children: [
            Center(child: AppIconTile(icon: CupertinoIcons.pause_circle_fill, color: c.warning, size: 72)),
            const SizedBox(height: Spacing.xl),
            AppText(l10n.cloudPausedTitle, style: (t) => t.title1, align: TextAlign.center),
            const SizedBox(height: Spacing.s),
            AppText(l10n.cloudPausedBody, style: (t) => t.body, color: c.textSecondary, align: TextAlign.center),
            const SizedBox(height: Spacing.xxl),
            AppButton(label: l10n.cloudPausedRenew, icon: CupertinoIcons.cloud_fill, onPressed: busy ? null : () => PaywallPage.open(context)),
            const SizedBox(height: Spacing.s),
            AppButton(
              label: l10n.cloudPausedMove,
              icon: CupertinoIcons.device_phone_portrait,
              variant: AppButtonVariant.tinted,
              onPressed: busy ? null : context.read<StorageCubit>().moveToLocal,
            ),
            const SizedBox(height: Spacing.s),
            AppButton(label: l10n.accountSignOut, variant: AppButtonVariant.plain, onPressed: busy ? null : () => _signOut(context)),
          ],
        ),
      ),
    );
  }
}
