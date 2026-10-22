import 'package:flutter/cupertino.dart';

import '../extensions/context_extensions.dart';

/// Schalter wie auf iOS (grün, wenn an).
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: context.colors.success),
    );
  }
}
