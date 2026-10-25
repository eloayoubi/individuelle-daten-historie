import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/view/category_detail_page.dart';

/// Einladung annehmen: Code eintippen (oder aus einem Link), beitreten, Kategorie öffnen.
class JoinSheet extends StatefulWidget {
  const JoinSheet({super.key, this.code});

  final String? code;

  static Future<void> show(BuildContext context, {String? code}) async {
    final categoryId = await AppSheet.show<String>(context, title: context.l10n.joinTitle, child: JoinSheet(code: code));
    if (categoryId != null && context.mounted) await CategoryDetailPage.open(context, categoryId);
  }

  @override
  State<JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<JoinSheet> {
  late final _code = TextEditingController(text: widget.code ?? '');
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  /// Button und Enter auf der Tastatur: nicht doppelt und nicht mit zu kurzem Code.
  bool get _canJoin => !_busy && _code.text.trim().length >= 6;

  Future<void> _join() async {
    if (!_canJoin) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await lookup<CategoriesRepository>().acceptInvite(_code.text);
      if (!mounted) return;
      AppToast.show(context, context.l10n.joinDone, icon: CupertinoIcons.person_2_fill);
      Navigator.of(context).pop(id);
    } on WriteRejected catch (e) {
      if (mounted) setState(() => _error = e.message == WriteRejected.cloudRequired ? context.l10n.joinOwnerNoCloud : context.l10n.joinInvalid);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.errorSave);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.l, 0, Spacing.l, Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.m,
        children: [
          AppText(l10n.joinBody, style: (t) => t.subheadline, color: c.textSecondary),
          AppTextField(
            controller: _code,
            hint: l10n.joinHint,
            maxLength: 12,
            autofocus: widget.code == null,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]'))],
            color: c.surfaceRaised,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _join(),
          ),
          if (_error != null) AppText(_error!, style: (t) => t.footnote, color: c.danger),
          AppButton(label: l10n.joinAction, onPressed: _canJoin ? _join : null),
        ],
      ),
    );
  }
}
