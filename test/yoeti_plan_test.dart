import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mornye/planner/yoeti_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('weekday blocks recur and edits replace the same block', () async {
    SharedPreferences.setMockInitialValues({});
    final plan = YoetiPlan.instance;
    final sunday = DateTime(2026, 11, 15);
    const block = PlanBlock(
      id: 'study',
      title: 'Study',
      category: 'Deep Study',
      start: 540,
      end: 600,
    );
    await plan.put(sunday, block);
    expect(
      plan.forDate(sunday.add(const Duration(days: 7))).single.title,
      'Study',
    );
    expect(plan.overlaps(sunday, 570, 630), isTrue);
    expect(plan.overlaps(sunday, 570, 630, exceptId: 'study'), isFalse);
    await plan.put(
      sunday,
      const PlanBlock(
        id: 'study',
        title: 'New study',
        category: 'Deep Study',
        start: 600,
        end: 660,
      ),
    );
    expect(plan.forDate(sunday).single.title, 'New study');
    await plan.remove(sunday, 'study');
    expect(plan.forDate(sunday.add(const Duration(days: 7))), isEmpty);
  });
}
