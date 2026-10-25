import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/core.dart';
import '../../categories/data/categories_repository.dart';
import '../cubit/account_cubit.dart';
import 'email_code_sheet.dart';

/// Konto: anonym oder gesichert, sichern mit Apple oder E-Mail-Code, mit bestehendem Konto
/// anmelden, Name für geteilte Kategorien, abmelden.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  /// Abmelden bestätigen; warnt, wenn noch Einträge auf dem Gerät auf das Senden warten.
  static Future<bool> confirmSignOut(BuildContext context) {
    final l10n = context.l10n;
    final pending = lookup<CategoriesRepository>().syncState.pending;
    return AppDialog.confirm(
      context,
      title: l10n.accountSignOutTitle,
      message: pending > 0 ? '${l10n.accountSignOutBody}\n\n${l10n.accountSignOutPending(pending)}' : l10n.accountSignOutBody,
      confirmLabel: l10n.accountSignOut,
      destructive: true,
    );
  }

  static Future<void> open(BuildContext context) => Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => const AccountPage()));

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final _name = TextEditingController(text: context.read<AccountCubit>().state.account.displayName);

  @override
  void initState() {
    super.initState();
    context.read<AccountCubit>().load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _onEvent(BuildContext context, AccountState state) async {
    final l10n = context.l10n;
    final cubit = context.read<AccountCubit>();
    switch (state.event!.kind) {
      case AccountEventKind.secured:
        AppToast.show(context, l10n.accountSecuredToast, icon: CupertinoIcons.checkmark_shield_fill);
      case AccountEventKind.signedIn:
        AppToast.show(context, l10n.accountSignedInToast);
      case AccountEventKind.nameSaved:
        AppToast.show(context, l10n.accountNameSaved);
      case AccountEventKind.signedOut:
        AppToast.show(context, l10n.accountSignedOutToast);
      case AccountEventKind.alreadyUsed:
        final signIn = await AppDialog.confirm(
          context,
          title: l10n.accountAlreadyUsedTitle,
          message: l10n.accountAlreadyUsedBody,
          confirmLabel: l10n.accountSignIn,
        );
        if (signIn) await cubit.signInWithApple();
      case AccountEventKind.invalidCode:
        AppToast.show(context, l10n.accountInvalidCode, icon: CupertinoIcons.exclamationmark_circle_fill);
      case AccountEventKind.rateLimited:
        AppToast.show(context, l10n.authRateLimited, icon: CupertinoIcons.exclamationmark_circle_fill);
      case AccountEventKind.network:
        AppToast.show(context, l10n.authNetwork, icon: CupertinoIcons.wifi_slash);
      case AccountEventKind.failed:
        AppToast.show(context, l10n.errorSave, icon: CupertinoIcons.exclamationmark_circle_fill);
      case AccountEventKind.deleted:
        AppToast.show(context, l10n.accountDeletedToast, icon: CupertinoIcons.trash_fill);
        Navigator.of(context).popUntil((route) => route.isFirst);
      case AccountEventKind.codeSent || AccountEventKind.canceled:
        break;
    }
    if (state.event!.kind == AccountEventKind.signedIn || state.event!.kind == AccountEventKind.signedOut) {
      _name.text = cubit.state.account.displayName;
    }
  }

  Future<void> _signInExisting(BuildContext context, {required bool apple}) async {
    final l10n = context.l10n;
    final cubit = context.read<AccountCubit>();
    final ok = await AppDialog.confirm(context, title: l10n.accountSignInTitle, message: l10n.accountSignInBody, confirmLabel: l10n.accountSignIn);
    if (!ok || !context.mounted) return;
    if (apple) {
      await cubit.signInWithApple();
    } else {
      await EmailCodeSheet.show(context, link: false);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final cubit = context.read<AccountCubit>();
    if (await AccountPage.confirmSignOut(context)) await cubit.signOut();
  }

  /// Zweimal fragen: Löschen lässt sich nicht rückgängig machen und betrifft auch geteilte Kategorien.
  /// Noch nicht gesendete Einträge gehen mit dem Konto verloren – darauf weist die Rückfrage hin.
  Future<void> _delete(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<AccountCubit>();
    final pending = lookup<CategoriesRepository>().syncState.pending;
    final message = pending > 0 ? '${l10n.accountDeleteBody}\n\n${l10n.accountDeletePending(pending)}' : l10n.accountDeleteBody;
    final ok = await AppDialog.confirm(context, title: l10n.accountDeleteTitle, message: message, confirmLabel: l10n.accountDelete, destructive: true);
    if (ok) await cubit.deleteAccount();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<AccountCubit>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<AccountCubit, AccountState>(
          listenWhen: (previous, current) => current.event != null && current.event != previous.event,
          listener: _onEvent,
          builder: (context, s) {
            final account = s.account;
            final apple = s.appleAvailable;
            return ListView(
              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Spacing.xxl),
              children: [
                AppHeader(title: l10n.accountTitle, onBack: () => Navigator.of(context).pop()),
                Padding(
                  padding: Spacing.screen,
                  child: AppCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: Spacing.m,
                      children: [
                        AppIconTile(
                          icon: account.isAnonymous ? CupertinoIcons.device_phone_portrait : CupertinoIcons.checkmark_shield_fill,
                          color: account.isAnonymous ? c.warning : c.success,
                          size: Sizes.iconTileLarge,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: Spacing.xxs,
                            children: [
                              AppText(account.isAnonymous ? l10n.accountAnonymousTitle : l10n.accountSecuredTitle, style: (t) => t.headline),
                              AppText(
                                account.isAnonymous ? l10n.accountAnonymousBody : l10n.accountSecuredBody(account.email ?? l10n.accountApple),
                                style: (t) => t.footnote,
                                color: c.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (account.isAnonymous) ...[
                  SectionHeader(title: l10n.accountSecure),
                  Padding(
                    padding: Spacing.screen,
                    child: Column(
                      spacing: Spacing.s,
                      children: [
                        if (apple)
                          SizedBox(
                            height: Sizes.buttonHeight,
                            child: SignInWithAppleButton(
                              text: l10n.accountSecureApple,
                              style: c.dark ? SignInWithAppleButtonStyle.white : SignInWithAppleButtonStyle.black,
                              borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
                              onPressed: s.busy ? () {} : cubit.linkApple,
                            ),
                          ),
                        AppButton(
                          label: l10n.accountSecureEmail,
                          icon: CupertinoIcons.mail_solid,
                          variant: AppButtonVariant.tinted,
                          onPressed: s.busy ? null : () => EmailCodeSheet.show(context, link: true),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.s, Spacing.xl, 0),
                    child: AppText(l10n.accountSecureFooter, style: (t) => t.footnote, color: c.textSecondary),
                  ),
                  SectionHeader(title: l10n.accountExisting),
                  AppListGroup(
                    dividerIndent: Spacing.l,
                    children: [
                      if (apple) AppListRow(title: l10n.accountSignInApple, onTap: () => _signInExisting(context, apple: true)),
                      AppListRow(title: l10n.accountSignInEmail, onTap: () => _signInExisting(context, apple: false)),
                    ],
                  ),
                ],
                SectionHeader(title: l10n.accountName),
                Padding(
                  padding: Spacing.screen,
                  child: Row(
                    spacing: Spacing.s,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _name,
                          hint: l10n.accountNameHint,
                          maxLength: 60,
                          textInputAction: TextInputAction.done,
                          onSubmitted: cubit.setDisplayName,
                        ),
                      ),
                      AppIconButton(
                        icon: CupertinoIcons.checkmark_alt,
                        semanticLabel: l10n.actionSave,
                        filled: true,
                        onPressed: s.busy ? null : () => cubit.setDisplayName(_name.text),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.s, Spacing.xl, 0),
                  child: AppText(l10n.accountNameFooter, style: (t) => t.footnote, color: c.textSecondary),
                ),
                if (!account.isAnonymous)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.xxl, Spacing.l, 0),
                    child: AppButton(label: l10n.accountSignOut, variant: AppButtonVariant.tinted, onPressed: s.busy ? null : () => _signOut(context)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.l, Spacing.s, Spacing.l, 0),
                  child: AppButton(label: l10n.accountDelete, variant: AppButtonVariant.destructive, onPressed: s.busy ? null : () => _delete(context)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.s, Spacing.xl, 0),
                  child: AppText(l10n.accountDeleteFooter, style: (t) => t.footnote, color: c.textSecondary),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
