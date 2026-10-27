import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../cubit/update_cubit.dart';
import 'force_update_page.dart';

/// Über der ganzen App, unter der Startanimation: Ist ein neuerer Build freigegeben, liegt
/// [ForceUpdatePage] über allem – auch über Sheets, Dialogen und dem Umzugs-Hinweis. Die App darunter
/// bleibt stehen (nimmt der Server die Sperre zurück, geht es ohne Neustart weiter), ist aber still
/// und für Bedienung und VoiceOver unerreichbar.
class ForceUpdateGate extends StatelessWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final page = switch (context.select((UpdateCubit u) => u.state)) {
      UpdateState(installed: final installed?, release: final release?) => ForceUpdatePage(
        key: ValueKey(release.build),
        installed: installed,
        release: release,
      ),
      _ => null,
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: page != null,
          child: TickerMode(enabled: page == null, child: child),
        ),
        AnimatedSwitcher(duration: Motion.normal, child: page ?? const SizedBox.shrink()),
      ],
    );
  }
}
