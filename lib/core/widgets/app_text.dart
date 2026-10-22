import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/text_styles.dart';

/// Kurzform für `Text(text, style: context.textStyles.xyz)`.
///
/// `style` wählt den Stil aus den [AppTextStyles], `color` übersteuert die Standardfarbe:
/// `AppText('Hallo', style: (t) => t.footnote, color: context.colors.textSecondary)`
class AppText extends StatelessWidget {
  const AppText(this.text, {super.key, required this.style, this.color, this.align, this.maxLines, this.overflow});

  final String text;
  final TextStyle Function(AppTextStyles) style;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    var resolved = style(context.textStyles);
    if (color != null) resolved = resolved.withColor(color!);
    return Text(
      text,
      style: resolved,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
    );
  }
}
