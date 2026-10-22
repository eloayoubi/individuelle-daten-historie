import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../categories/view/categories_page.dart';
import '../../home/view/home_page.dart';
import '../../settings/view/settings_page.dart';
import '../cubit/shell_cubit.dart';
import 'app_tab_bar.dart';

/// Rahmen der App: Tab-Inhalt mit der schwebenden Glas-Leiste darüber.
/// Die Tabs bleiben im [IndexedStack] erhalten (Scroll-Position, geladene Daten).
class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => lookup<ShellCubit>(), child: const ShellView());
  }
}

/// Ohne eigenen [ShellCubit] – für Tests, die ihn selbst bereitstellen.
class ShellView extends StatelessWidget {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ShellCubit, ShellTab>(
      builder: (context, tab) => Scaffold(
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: tab.index,
            children: [
              const HomePage(),
              const CategoriesPage(),
              PlaceholderPage(title: l10n.tabInsights, icon: CupertinoIcons.chart_bar_alt_fill, description: l10n.placeholderInsights),
              const SettingsPage(),
            ],
          ),
        ),
        bottomNavigationBar: AppTabBar(current: tab, onSelect: context.read<ShellCubit>().select),
      ),
    );
  }
}
