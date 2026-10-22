import 'package:flutter_bloc/flutter_bloc.dart';

/// Die Tabs der unteren Leiste, in Anzeigereihenfolge.
enum ShellTab { overview, categories, insights, settings }

/// Hält den aktiven Tab. Reiner Zustand, daher ein Cubit.
class ShellCubit extends Cubit<ShellTab> {
  ShellCubit() : super(ShellTab.overview);

  void select(ShellTab tab) => emit(tab);
}
