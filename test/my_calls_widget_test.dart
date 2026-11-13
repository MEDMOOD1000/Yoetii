import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mornye/my_calls/my_calls_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('four tabs and floating settings fit a phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MyCallsShell())),
    );
    await tester.pump();
    expect(find.text('MY CALLS'), findsWidgets);
    expect(find.byTooltip('Settings'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Your Excel roster, made clear.'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('A clear calculation from a verified order.'),
      findsOneWidget,
    );
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Capture what matters on every call.'), findsOneWidget);
  });
}
