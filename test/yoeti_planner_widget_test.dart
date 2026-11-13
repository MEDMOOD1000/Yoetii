import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mornye/planner/today_plan_tab.dart';
import 'package:mornye/planner/next_days_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('plan a task from Today and open Tomorrow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: TodayPlanTab()));
    await tester.pump();
    expect(find.text('Today'), findsWidgets);
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Study');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Study'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: NextDaysTab()));
    await tester.pump();
    expect(find.text('TOMORROW'), findsWidgets);
    await tester.tap(
      find
          .ancestor(
            of: find.text('TOMORROW').first,
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(DayPlanView), findsOneWidget);
  });
}
