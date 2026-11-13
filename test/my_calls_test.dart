import 'dart:typed_data';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mornye/my_calls/dose_math.dart';
import 'package:mornye/my_calls/store.dart';
import 'package:mornye/my_calls/roster.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('dose units, daily split and maximum remain distinct', () {
    const common = DoseInput(
      drug: 'Example',
      source: 'Verified order',
      weightKg: 20,
      rateMgPerKg: 10,
      basis: DoseBasis.perDose,
      dosesPerDay: 2,
      strengthMg: 125,
      strengthMl: 5,
    );
    final perDose = DoseCalculator.calculate(common);
    expect(perDose.mgPerDose, 200);
    expect(perDose.mlPerDose, 8);
    expect(perDose.mgPerDay, 400);
    final perDay = DoseCalculator.calculate(
      const DoseInput(
        drug: 'Example',
        source: 'Verified order',
        weightKg: 20,
        rateMgPerKg: 20,
        basis: DoseBasis.perDay,
        dosesPerDay: 2,
        strengthMg: 125,
        strengthMl: 5,
      ),
    );
    expect(perDay.mgPerDose, 200);
    final capped = DoseCalculator.calculate(
      const DoseInput(
        drug: 'Example',
        source: 'Verified order',
        weightKg: 20,
        rateMgPerKg: 10,
        basis: DoseBasis.perDose,
        dosesPerDay: 2,
        strengthMg: 125,
        strengthMl: 5,
        maxMgPerDose: 150,
      ),
    );
    expect(capped.mgPerDose, 150);
    expect(capped.mlPerDose, 6);
    expect(capped.maximumApplied, isTrue);
  });
  test(
    'missing source, invalid concentration and tiny volume are rejected',
    () {
      expect(
        () => DoseCalculator.calculate(
          const DoseInput(
            drug: 'X',
            source: '',
            weightKg: 20,
            rateMgPerKg: 10,
            basis: DoseBasis.perDose,
            dosesPerDay: 1,
            strengthMg: 100,
            strengthMl: 5,
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => DoseCalculator.calculate(
          const DoseInput(
            drug: 'X',
            source: 'Order',
            weightKg: 20,
            rateMgPerKg: 10,
            basis: DoseBasis.perDose,
            dosesPerDay: 1,
            strengthMg: 0,
            strengthMl: 5,
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => DoseCalculator.calculate(
          const DoseInput(
            drug: 'X',
            source: 'Order',
            weightKg: 1,
            rateMgPerKg: 1,
            basis: DoseBasis.perDose,
            dosesPerDay: 1,
            strengthMg: 1000,
            strengthMl: 1,
          ),
        ),
        throwsFormatException,
      );
    },
  );
  test('roster names, workdays and rest days follow dated rows', () {
    final roster = RosterParser.fromRows(
      [
        ['التاريخ', 'اليوم', 'الكروب', 'Emergency', 'Ward'],
        [46000, 'Mon', 'A', 'Ali', 'Sara'],
        ['2026-11-14', 'Sat', 'B', 'Sara', 'Ali'],
        ['15/11/2026', 'Sun', 'C', '', 'Sara'],
        ['not a date', '', '', 'Other', ''],
      ],
      'calls.xlsx',
      'November',
    );
    expect(roster.employees, ['Ali', 'Sara']);
    expect(roster.days.length, 3);
    expect(roster.workDaysFor('Ali').length, 2);
    expect(roster.days.last.departmentFor('Ali'), isNull);
    expect(roster.days.last.departmentFor('Sara'), 'Ward');
    expect(
      ImportedRoster.fromJson(roster.toJson())!.employees,
      roster.employees,
    );
  });
  test('xlsx workbook decodes names and dates', () {
    final book = Excel.createExcel();
    final sheet = book['Sheet1'];
    for (final entry in <String, CellValue>{
      'A1': TextCellValue('التاريخ'),
      'B1': TextCellValue('اليوم'),
      'C1': TextCellValue('الكروب'),
      'D1': TextCellValue('ER'),
      'A2': DateCellValue(year: 2026, month: 11, day: 14),
      'B2': TextCellValue('Sat'),
      'C2': TextCellValue('A'),
      'D2': TextCellValue('Ali'),
    }.entries) {
      sheet.updateCell(CellIndex.indexByString(entry.key), entry.value);
    }
    final roster = RosterParser.fromWorkbook(
      Uint8List.fromList(book.save()!),
      'roster.xlsx',
    );
    expect(roster.employees, ['Ali']);
    expect(roster.days.single.date, '2026-11-14');
    expect(roster.days.single.departmentFor('Ali'), 'ER');
  });
  test('shift and note remain in local store', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MyCallsStore.instance;
    await store.putShift(
      const DutyShift(
        id: 'shift',
        date: '2026-11-14',
        start: '08:00',
        end: '16:00',
        title: 'Clinic',
        place: 'A',
        note: '',
        completed: false,
      ),
    );
    await store.putNote(
      const CallNote(
        id: 'note',
        title: 'Handover',
        body: 'Check labs',
        items: [],
        colorIndex: 2,
        updatedAt: '2026-11-14',
      ),
    );
    expect(store.shifts.single.title, 'Clinic');
    expect(store.notes.single.title, 'Handover');
    expect(
      (await SharedPreferences.getInstance()).getString('my_calls_data_v1'),
      contains('Handover'),
    );
  });
}
