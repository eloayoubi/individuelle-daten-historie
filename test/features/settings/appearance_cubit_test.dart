import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/settings/cubit/appearance_cubit.dart';
import 'package:kostenkurve/features/settings/data/appearance_store.dart';

void main() {
  test('startet mit der Einstellung des Geräts', () => expect(AppearanceCubit(MemoryAppearanceStore()).state, ThemeMode.system));

  blocTest<AppearanceCubit, ThemeMode>(
    'lädt die gespeicherte Wahl',
    build: () => AppearanceCubit(MemoryAppearanceStore()..write(ThemeMode.dark)),
    act: (cubit) => cubit.load(),
    expect: () => [ThemeMode.dark],
  );

  final store = MemoryAppearanceStore();
  blocTest<AppearanceCubit, ThemeMode>(
    'wählt und speichert eine Darstellung',
    build: () => AppearanceCubit(store),
    act: (cubit) => cubit.select(ThemeMode.light),
    expect: () => [ThemeMode.light],
    verify: (_) async => expect(await store.read(), ThemeMode.light),
  );

  blocTest<AppearanceCubit, ThemeMode>(
    'eine Wahl während des Ladens gewinnt',
    build: () => AppearanceCubit(MemoryAppearanceStore()..write(ThemeMode.dark)),
    act: (cubit) async {
      final loading = cubit.load();
      await cubit.select(ThemeMode.light);
      await loading;
    },
    expect: () => [ThemeMode.light],
  );
}
