import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kostenkurve/core/core.dart';

import '../support/pump_app.dart';

void main() {
  setUpAll(ensureMockDependencies);

  testWidgets('Namen als Aufzählung, Mitglied ohne Namen mit Platzhalter', (tester) async {
    late BuildContext ctx;
    await pumpPage(tester, Builder(builder: (context) => (ctx = context, const SizedBox()).$2));
    expect(ctx.joinNames(['Anna']), 'Anna');
    expect(ctx.joinNames(['Anna', 'Ben', 'Carla']), 'Anna, Ben und Carla');
    expect(ctx.memberNames(const [CategoryMember(userId: 'a', name: 'Anna', role: MemberRole.editor), CategoryMember(userId: 'b', name: ' ', role: MemberRole.viewer)]), 'Anna und ${ctx.l10n.shareNoName}');
  });
}
