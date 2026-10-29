import 'package:flutter/cupertino.dart';

import '../extensions/context_extensions.dart';
import 'app_text.dart';

/// Segment-Umschalter wie auf iOS (z. B. Automatisch / Hell / Dunkel).
class AppSegmented<T extends Object> extends StatelessWidget {
  const AppSegmented({super.key, required this.value, required this.segments, required this.onChanged});

  /// `null` = noch nichts gewählt.
  final T? value;

  /// Wert → Beschriftung, in Anzeigereihenfolge.
  final Map<T, String> segments;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: value,
        backgroundColor: c.fill,
        thumbColor: c.thumb,
        onValueChanged: (v) {
          if (v != null) onChanged(v);
        },
        children: {
          for (final MapEntry(:key, value: label) in segments.entries)
            key: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: AppText(label, style: (t) => key == value ? t.footnoteEmphasized : t.footnote, maxLines: 1),
            ),
        },
      ),
    );
  }
}
