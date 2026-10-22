import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/features/shell/cubit/shell_cubit.dart';

void main() {
  test('startet auf der Übersicht', () => expect(ShellCubit().state, ShellTab.overview));

  blocTest<ShellCubit, ShellTab>(
    'wechselt den Tab',
    build: ShellCubit.new,
    act: (cubit) => cubit
      ..select(ShellTab.settings)
      ..select(ShellTab.categories),
    expect: () => [ShellTab.settings, ShellTab.categories],
  );
}
