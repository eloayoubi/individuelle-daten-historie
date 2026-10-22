import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../extensions/context_extensions.dart';
import '../theme/dimensions.dart';
import '../theme/text_styles.dart';

/// Eingabefeld im iOS-Stil: gefüllte, abgerundete Fläche ohne Rahmen. In Sheets
/// `color: context.colors.surfaceRaised`, sonst `surface` (Standard).
///
/// Mit [label] wie eine Zeile in den iOS-Einstellungen: Beschriftung links, Wert rechtsbündig.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofocus = false,
    this.maxLength,
    this.color,
    this.suffix,
    this.label,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;

  /// Obergrenze wie in der Datenbank (Namen 60, Einheiten 20); ohne Zähler darunter.
  final int? maxLength;
  final Color? color;

  /// Rechts im Feld, z. B. die Einheit.
  final Widget? suffix;

  /// Beschriftung links im Feld; bleibt sichtbar, wenn ein Wert drinsteht.
  final String? label;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.textStyles;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ...?inputFormatters,
      ],
      autofocus: autofocus,
      textAlign: label == null ? TextAlign.start : TextAlign.end,
      style: t.body,
      cursorColor: c.accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: t.body.withColor(c.textTertiary),
        filled: true,
        fillColor: color ?? c.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.l, vertical: Spacing.m + 2),
        prefixIcon: label == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: Spacing.l, right: Spacing.s),
                child: Text(label!, style: t.body.withColor(c.textSecondary)),
              ),
        prefixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
        suffixIcon: suffix == null ? null : Padding(padding: const EdgeInsets.only(right: Spacing.l), child: suffix),
        suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.m), borderSide: BorderSide.none),
      ),
    );
  }
}
