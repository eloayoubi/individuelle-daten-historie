import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../cubit/account_cubit.dart';

/// E-Mail-Code: Adresse eingeben, Code aus der Mail eintippen. [link] sichert das aktuelle Konto,
/// sonst Anmeldung in ein bestehendes.
class EmailCodeSheet extends StatefulWidget {
  const EmailCodeSheet({super.key, required this.link});

  final bool link;

  static Future<void> show(BuildContext context, {required bool link}) => AppSheet.show<void>(
    context,
    title: link ? context.l10n.accountSecureEmail : context.l10n.accountSignInEmail,
    child: EmailCodeSheet(link: link),
  );

  @override
  State<EmailCodeSheet> createState() => _EmailCodeSheetState();
}

class _EmailCodeSheetState extends State<EmailCodeSheet> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  var _sent = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _emailValid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<AccountCubit>();
    return BlocConsumer<AccountCubit, AccountState>(
      listenWhen: (previous, current) => current.event != null && current.event != previous.event,
      listener: (context, state) {
        switch (state.event!.kind) {
          case AccountEventKind.codeSent:
            setState(() => _sent = true);
          case AccountEventKind.secured || AccountEventKind.signedIn:
            Navigator.of(context).pop();
          default:
            break;
        }
      },
      builder: (context, s) => Padding(
        padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spacing.m,
          children: [
            AppTextField(
              controller: _email,
              hint: l10n.accountEmailHint,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              autofocus: true,
              color: c.surfaceRaised,
              onChanged: (_) => setState(() {}),
            ),
            if (_sent) ...[
              AppText(l10n.accountCodeSent(_email.text.trim()), style: (t) => t.footnote, color: c.textSecondary),
              AppTextField(
                controller: _code,
                hint: l10n.accountCodeHint,
                keyboardType: TextInputType.number,
                maxLength: 10,
                autocorrect: false,
                color: c.surfaceRaised,
                onChanged: (_) => setState(() {}),
              ),
              AppButton(
                label: l10n.accountConfirm,
                onPressed: s.busy || _code.text.trim().length < 6 ? null : () => cubit.verifyEmailCode(_email.text, _code.text, link: widget.link),
              ),
              AppButton(
                label: l10n.accountResend,
                variant: AppButtonVariant.plain,
                onPressed: s.busy ? null : () => cubit.requestEmailCode(_email.text, link: widget.link),
              ),
            ] else
              AppButton(label: l10n.accountSendCode, onPressed: s.busy || !_emailValid ? null : () => cubit.requestEmailCode(_email.text, link: widget.link)),
          ],
        ),
      ),
    );
  }
}
