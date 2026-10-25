import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/core.dart';
import '../../account/cubit/account_cubit.dart';
import '../../legal/data/legal_document.dart';
import '../../legal/view/legal_page.dart';
import '../../plus/cubit/plus_cubit.dart';
import '../../plus/view/paywall_page.dart';
import '../../storage/view/cloud_flow.dart';
import '../data/auth_repository.dart';

enum AuthMode { register, signIn }

/// Registrieren und Anmelden für die Cloud – mit Apple oder einem 6-stelligen Code per E-Mail,
/// ohne Passwort. Nach dem Registrieren kommt die Paywall; wer sich mit laufendem Abo anmeldet, ist
/// sofort in der Cloud.
///
/// Sicherheit: Adresse und Code werden vor dem Senden geprüft, ein neuer Code kommt frühestens nach
/// [AuthPage.resendAfter] Sekunden; beim Anmelden ist die Antwort für bekannte und unbekannte
/// Adressen gleich.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.mode = AuthMode.register, this.paywallNext = true});

  final AuthMode mode;

  /// Danach die Paywall öffnen; `false`, wenn sie schon darunter liegt.
  final bool paywallNext;

  static const resendAfter = 60;

  static Future<void> open(BuildContext context, {AuthMode mode = AuthMode.register, bool paywallNext = true}) =>
      Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => AuthPage(mode: mode, paywallNext: paywallNext)));

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late var _mode = widget.mode;
  final _email = TextEditingController();
  final _code = TextEditingController();
  var _sent = false;
  var _cooldown = 0;
  var _continuing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    context.read<AccountCubit>().load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _register => _mode == AuthMode.register;

  /// Ein anonymes Konto aus der Testphase wird beim Registrieren verknüpft, damit seine Daten bleiben.
  bool get _link {
    final account = context.read<AccountCubit>().state.account;
    return _register && account.isSignedIn && account.isAnonymous;
  }

  bool get _emailValid => AuthInput.isEmail(_email.text.trim());

  bool get _codeValid => AuthInput.isCode(_code.text.trim());

  void _switchMode(AuthMode mode) => setState(() {
    _mode = mode;
    _sent = false;
    _code.clear();
  });

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = AuthPage.resendAfter);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _cooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldown = 0);
        return;
      }
      setState(() => _cooldown--);
    });
  }

  Future<void> _apple() {
    final cubit = context.read<AccountCubit>();
    return _link ? cubit.linkApple() : cubit.signInWithApple();
  }

  Future<void> _sendCode() => context.read<AccountCubit>().requestEmailCode(_email.text, link: _link, create: _register && !_link);

  Future<void> _verify() => context.read<AccountCubit>().verifyEmailCode(_email.text, _code.text, link: _link);

  /// Angemeldet: mit laufendem Abo direkt in die Cloud, sonst zur Paywall.
  Future<void> _continue() async {
    if (_continuing) return;
    setState(() => _continuing = true);
    final plus = context.read<PlusCubit>();
    await plus.load();
    if (!mounted) return;
    if (plus.state.active) {
      await CloudFlow.activate(context);
      if (mounted) setState(() => _continuing = false);
      return;
    }
    if (widget.paywallNext) {
      await Navigator.of(context).pushReplacement(PaywallPage.route());
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onEvent(BuildContext context, AccountState state) async {
    final l10n = context.l10n;
    const warn = CupertinoIcons.exclamationmark_circle_fill;
    switch (state.event!.kind) {
      case AccountEventKind.codeSent:
        setState(() => _sent = true);
        _startCooldown();
      case AccountEventKind.secured || AccountEventKind.signedIn:
        await _continue();
      case AccountEventKind.alreadyUsed:
        // Nur beim Verknüpfen eines Testkontos: Die E-Mail bzw. Apple-ID hat schon ein Konto.
        if (_emailValid) {
          AppToast.show(context, l10n.authEmailUsed, icon: warn);
          _switchMode(AuthMode.signIn);
          return;
        }
        final cubit = context.read<AccountCubit>();
        final signIn = await AppDialog.confirm(
          context,
          title: l10n.accountAlreadyUsedTitle,
          message: l10n.accountAlreadyUsedBody,
          confirmLabel: l10n.accountSignIn,
        );
        if (signIn) await cubit.signInWithApple();
      case AccountEventKind.invalidCode:
        AppToast.show(context, l10n.accountInvalidCode, icon: warn);
      case AccountEventKind.rateLimited:
        AppToast.show(context, l10n.authRateLimited, icon: warn);
      case AccountEventKind.network:
        AppToast.show(context, l10n.authNetwork, icon: CupertinoIcons.wifi_slash);
      case AccountEventKind.failed:
        AppToast.show(context, l10n.errorSave, icon: warn);
      case AccountEventKind.canceled || AccountEventKind.nameSaved || AccountEventKind.signedOut || AccountEventKind.deleted:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final email = _email.text.trim();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<AccountCubit, AccountState>(
          listenWhen: (previous, current) => current.event != null && current.event != previous.event,
          listener: _onEvent,
          builder: (context, s) {
            final busy = s.busy || _continuing;
            return ListView(
              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Spacing.xxl),
              children: [
                AppHeader(title: _register ? l10n.authRegisterTitle : l10n.authSignInTab, onBack: () => Navigator.of(context).pop()),
                Padding(
                  padding: Spacing.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: Spacing.m,
                    children: [
                      AppSegmented<AuthMode>(
                        value: _mode,
                        segments: {AuthMode.register: l10n.authRegisterTab, AuthMode.signIn: l10n.authSignInTab},
                        onChanged: busy ? (_) {} : _switchMode,
                      ),
                      AppText(_register ? l10n.authRegisterBody : l10n.authSignInBody, style: (t) => t.subheadline, color: c.textSecondary),
                      // Anonymes Testkonto: Wer sich in ein anderes Konto anmeldet, lässt dessen Daten zurück.
                      if (!_register && s.account.isSignedIn && s.account.isAnonymous)
                        AppText(l10n.accountSignInBody, style: (t) => t.footnote, color: c.warning),
                      if (s.appleAvailable) ...[
                        SizedBox(
                          height: Sizes.buttonHeight,
                          child: SignInWithAppleButton(
                            text: _register ? l10n.authAppleRegister : l10n.accountSignInApple,
                            style: c.dark ? SignInWithAppleButtonStyle.white : SignInWithAppleButtonStyle.black,
                            borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
                            onPressed: busy ? () {} : _apple,
                          ),
                        ),
                        AppText(l10n.authOrEmail, style: (t) => t.footnote, color: c.textSecondary, align: TextAlign.center),
                      ],
                      AppTextField(
                        controller: _email,
                        hint: l10n.accountEmailHint,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.send,
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        maxLength: AuthInput.maxEmailLength,
                        autofillHints: const [AutofillHints.email],
                        enabled: !_sent,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) {
                          if (_emailValid && !busy) _sendCode();
                        },
                      ),
                      if (!_sent) ...[
                        AppButton(label: l10n.accountSendCode, onPressed: busy || !_emailValid ? null : _sendCode),
                        AppText(l10n.authNoPassword, style: (t) => t.footnote, color: c.textSecondary, align: TextAlign.center),
                      ] else ...[
                        AppText(_register ? l10n.accountCodeSent(email) : l10n.authCodeSentSignIn(email), style: (t) => t.footnote, color: c.textSecondary),
                        AppTextField(
                          controller: _code,
                          hint: l10n.accountCodeHint,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          maxLength: AuthInput.codeLength,
                          autocorrect: false,
                          autofocus: true,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) {
                            if (_codeValid && !busy) _verify();
                          },
                        ),
                        AppButton(label: l10n.accountConfirm, onPressed: busy || !_codeValid ? null : _verify),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: _cooldown > 0 ? l10n.authResendIn(_cooldown) : l10n.accountResend,
                                variant: AppButtonVariant.plain,
                                onPressed: busy || _cooldown > 0 ? null : _sendCode,
                              ),
                            ),
                            Expanded(
                              child: AppButton(
                                label: l10n.authChangeEmail,
                                variant: AppButtonVariant.plain,
                                onPressed: busy ? null : () => setState(() => _sent = false),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_register) const _Consent(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// „Mit dem Registrieren akzeptierst du die Nutzungsbedingungen und hast die Hinweise zum Datenschutz
/// gelesen.“ – beide Begriffe öffnen den Text.
class _Consent extends StatelessWidget {
  const _Consent();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.textStyles;
    final l10n = context.l10n;
    InlineSpan link(String label, LegalDocument document) => WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: AppPressable(
        onTap: () => LegalPage.open(context, document),
        child: Semantics(link: true, child: Text(label, style: t.footnote.withColor(c.accent))),
      ),
    );
    return Text.rich(
      TextSpan(
        style: t.footnote.withColor(c.textSecondary),
        children: [
          TextSpan(text: '${l10n.authConsentPrefix} '),
          link(l10n.legalTerms, LegalDocument.terms),
          TextSpan(text: ' ${l10n.authConsentMiddle} '),
          link(l10n.legalPrivacy, LegalDocument.privacy),
          TextSpan(text: ' ${l10n.authConsentSuffix}'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
