import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/core.dart';
import '../../account/cubit/account_cubit.dart';
import '../../account/view/account_page.dart';
import '../cubit/sharing_cubit.dart';
import '../data/invite_links.dart';

/// Teilen einer Kategorie: wer dabei ist (Rollen ändern, entfernen), Person einladen (Code, QR,
/// Link teilen) – oder als Mitglied die Kategorie verlassen.
class SharePage extends StatelessWidget {
  const SharePage({super.key, required this.categoryId});

  final String categoryId;

  static Future<void> open(BuildContext context, String categoryId) =>
      Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => SharePage(categoryId: categoryId)));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => lookup<SharingCubit>(param1: categoryId)..load(), child: const _ShareView());
  }
}

class _ShareView extends StatelessWidget {
  const _ShareView();

  void _onEvent(BuildContext context, SharingState state) {
    final l10n = context.l10n;
    switch (state.event!.kind) {
      case SharingEventKind.removed:
        AppToast.show(context, l10n.shareRemoved);
      case SharingEventKind.left:
        AppToast.show(context, l10n.shareLeft);
        // Zurück bis vor die Kategorie, die es für mich nicht mehr gibt.
        Navigator.of(context).popUntil((route) => route.isFirst);
      case SharingEventKind.failed:
        AppToast.show(context, l10n.errorSave, icon: CupertinoIcons.exclamationmark_circle_fill);
    }
  }

  static String _roleLabel(BuildContext context, MemberRole role) => switch (role) {
    MemberRole.owner => context.l10n.roleOwner,
    MemberRole.editor => context.l10n.roleEditor,
    MemberRole.viewer => context.l10n.roleViewer,
  };

  Future<void> _memberOptions(BuildContext context, CategoryMember member) async {
    final l10n = context.l10n;
    final cubit = context.read<SharingCubit>();
    final choice = await AppSheet.show<String>(
      context,
      title: member.name.isEmpty ? l10n.shareNoName : member.name,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Spacing.s,
          children: [
            for (final role in [MemberRole.editor, MemberRole.viewer])
              Builder(
                builder: (context) => AppButton(
                  label: _roleLabel(context, role),
                  variant: role == member.role ? AppButtonVariant.filled : AppButtonVariant.tinted,
                  onPressed: () => Navigator.of(context).pop(role.name),
                ),
              ),
            Builder(
              builder: (context) => AppButton(label: l10n.shareRemove, variant: AppButtonVariant.destructive, onPressed: () => Navigator.of(context).pop('remove')),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'remove') {
      final ok = await AppDialog.confirm(context, title: l10n.shareRemoveTitle(member.name.isEmpty ? l10n.shareNoName : member.name), message: l10n.shareRemoveBody, confirmLabel: l10n.shareRemove, destructive: true);
      if (ok) await cubit.remove(member);
    } else {
      await cubit.setRole(member, MemberRole.values.byName(choice));
    }
  }

  Future<void> _leave(BuildContext context, Category category) async {
    final l10n = context.l10n;
    final cubit = context.read<SharingCubit>();
    final ok = await AppDialog.confirm(context, title: l10n.shareLeaveTitle(category.name), message: l10n.shareLeaveBody, confirmLabel: l10n.shareLeave, destructive: true);
    if (ok) await cubit.leave();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<SharingCubit, SharingState>(
          listenWhen: (previous, current) => current.event != null && current.event != previous.event,
          listener: _onEvent,
          builder: (context, s) {
            final category = s.category;
            if (category == null) {
              return s.loaded
                  ? Column(children: [AppHeader(title: '', onBack: () => Navigator.of(context).pop())])
                  : const Center(child: CupertinoActivityIndicator());
            }
            final account = context.watch<AccountCubit>().state.account;
            return ListView(
              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Spacing.xxl),
              children: [
                AppHeader(title: l10n.shareTitle, overline: category.name, onBack: () => Navigator.of(context).pop()),
                SectionHeader(title: l10n.shareMembers),
                AppListGroup(
                  children: [
                    AppListRow(
                      leading: AppIconTile(icon: CupertinoIcons.person_fill, color: c.accent),
                      title: account.displayName.isEmpty ? l10n.shareYou : l10n.shareYouNamed(account.displayName),
                      subtitle: _roleLabel(context, category.myRole),
                    ),
                    for (final m in category.sharedWith)
                      AppListRow(
                        leading: AppIconTile(icon: CupertinoIcons.person_fill, color: c.swatch(category.swatch)),
                        title: m.name.isEmpty ? l10n.shareNoName : m.name,
                        subtitle: _roleLabel(context, m.role),
                        onTap: category.isOwner && m.role != MemberRole.owner ? () => _memberOptions(context, m) : null,
                      ),
                  ],
                ),
                if (category.isOwner) ...[
                  SectionHeader(title: l10n.shareInvite),
                  if (account.isAnonymous)
                    Padding(
                      padding: Spacing.screen,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: Spacing.m,
                          children: [
                            AppText(l10n.shareSecureFirst, style: (t) => t.subheadline, color: c.textSecondary),
                            AppButton(label: l10n.accountSecure, icon: CupertinoIcons.checkmark_shield_fill, onPressed: () => AccountPage.open(context)),
                          ],
                        ),
                      ),
                    )
                  else
                    _InviteCard(state: s, category: category),
                ] else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xxl, Spacing.l, 0),
                    child: AppButton(label: l10n.shareLeave, variant: AppButtonVariant.destructive, onPressed: s.busy ? null : () => _leave(context, category)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.state, required this.category});

  final SharingState state;
  final Category category;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<SharingCubit>();
    final code = state.inviteCode;
    return Padding(
      padding: Spacing.screen,
      child: AppCard(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spacing.m,
          children: [
            AppSegmented<MemberRole>(
              value: state.inviteRole,
              segments: {MemberRole.editor: l10n.roleEditor, MemberRole.viewer: l10n.roleViewer},
              onChanged: cubit.setInviteRole,
            ),
            AppText(state.inviteRole == MemberRole.editor ? l10n.roleEditorHint : l10n.roleViewerHint, style: (t) => t.footnote, color: c.textSecondary),
            if (code == null)
              AppButton(label: l10n.shareCreateInvite, icon: CupertinoIcons.person_badge_plus, onPressed: state.busy ? null : cubit.createInvite)
            else ...[
              Center(child: AppText(code, style: (t) => t.code, align: TextAlign.center)),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(Spacing.m),
                  decoration: ShapeDecoration(color: c.thumb, shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Radii.l))),
                  child: QrImageView(
                    data: InviteLinks.linkFor(code),
                    size: 180,
                    eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: c.textPrimary),
                    dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: c.textPrimary),
                  ),
                ),
              ),
              Builder(
                builder: (context) => AppButton(
                  label: l10n.shareSend,
                  icon: CupertinoIcons.share,
                  onPressed: () => AppShare.text(context, l10n.shareMessage(category.name, code, InviteLinks.linkFor(code))),
                ),
              ),
              AppText(l10n.shareValidity, style: (t) => t.footnote, color: c.textSecondary, align: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
