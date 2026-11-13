import 'dart:typed_data';
import 'package:excel_plus/excel_plus.dart';

class RosterDay {
  const RosterDay({
    required this.date,
    required this.dayLabel,
    required this.group,
    required this.assignments,
  });
  final String date, dayLabel, group;
  final Map<String, String> assignments;
  Map<String, Object> toJson() => {
    'date': date,
    'dayLabel': dayLabel,
    'group': group,
    'assignments': assignments,
  };
  static RosterDay? fromJson(Object? raw) {
    if (raw is! Map || raw['date'] is! String || raw['assignments'] is! Map)
      return null;
    return RosterDay(
      date: raw['date'] as String,
      dayLabel: raw['dayLabel'] as String? ?? '',
      group: raw['group'] as String? ?? '',
      assignments: Map<String, String>.from(raw['assignments'] as Map),
    );
  }

  String? departmentFor(String employee) {
    for (final e in assignments.entries) {
      if (e.value == employee) return e.key;
    }
    return null;
  }
}

class ImportedRoster {
  const ImportedRoster({
    required this.sourceName,
    required this.sheetName,
    required this.departments,
    required this.employees,
    required this.days,
  });
  final String sourceName, sheetName;
  final List<String> departments, employees;
  final List<RosterDay> days;
  Map<String, Object> toJson() => {
    'sourceName': sourceName,
    'sheetName': sheetName,
    'departments': departments,
    'employees': employees,
    'days': days.map((e) => e.toJson()).toList(),
  };
  static ImportedRoster? fromJson(Object? raw) {
    if (raw is! Map || raw['days'] is! List) return null;
    return ImportedRoster(
      sourceName: raw['sourceName'] as String? ?? '',
      sheetName: raw['sheetName'] as String? ?? '',
      departments: (raw['departments'] as List? ?? [])
          .whereType<String>()
          .toList(),
      employees: (raw['employees'] as List? ?? []).whereType<String>().toList(),
      days: (raw['days'] as List)
          .map(RosterDay.fromJson)
          .whereType<RosterDay>()
          .toList(),
    );
  }

  List<RosterDay> workDaysFor(String employee) =>
      days.where((d) => d.departmentFor(employee) != null).toList();
}

class RosterParser {
  static ImportedRoster fromWorkbook(Uint8List bytes, String fileName) {
    if (bytes.length > 15 * 1024 * 1024)
      throw const FormatException('The workbook is too large (15 MB maximum).');
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty)
      throw const FormatException('No worksheet found.');
    final sheetName = excel.tables.keys.first;
    final rows = excel[sheetName].rows
        .map((r) => r.map((c) => _cell(c?.value)).toList())
        .toList();
    return fromRows(rows, fileName, sheetName);
  }

  static Object? _cell(CellValue? value) => switch (value) {
    null => null,
    TextCellValue() => value.value,
    IntCellValue() => value.value,
    DoubleCellValue() => value.value,
    DateCellValue() => value.asDateTimeLocal(),
    DateTimeCellValue() => value.asDateTimeLocal(),
    BoolCellValue() => value.value,
    TimeCellValue() => value.asDuration().toString(),
    FormulaCellValue() => value.formula,
    CellErrorValue() => null,
  };

  static ImportedRoster fromRows(
    List<List<Object?>> rows,
    String fileName,
    String sheetName,
  ) {
    if (rows.isEmpty) throw const FormatException('The sheet is empty.');
    int headerIndex = -1, dateCol = -1, dayCol = -1, groupCol = -1;
    for (var i = 0; i < rows.length && i < 15; i++) {
      final headers = rows[i].map((v) => _text(v).toLowerCase()).toList();
      final d = headers.indexWhere(
        (h) => h.contains('تاريخ') || h.contains('date'),
      );
      if (d < 0) continue;
      headerIndex = i;
      dateCol = d;
      dayCol = headers.indexWhere(
        (h) => h == 'اليوم' || h == 'day' || h.contains('weekday'),
      );
      groupCol = headers.indexWhere(
        (h) => h.contains('كروب') || h.contains('group'),
      );
      break;
    }
    if (headerIndex < 0)
      throw const FormatException(
        'Date header not found. Expected التاريخ / Date.',
      );
    final headers = rows[headerIndex];
    final columns = <int, String>{};
    for (var c = 0; c < headers.length; c++) {
      if (c == dateCol || c == dayCol || c == groupCol) continue;
      final name = _text(headers[c]);
      if (name.isNotEmpty && !name.startsWith('__EMPTY')) columns[c] = name;
    }
    if (columns.isEmpty)
      throw const FormatException('No department columns found.');
    final days = <RosterDay>[];
    final employees = <String>[];
    final seen = <String>{};
    for (var i = headerIndex + 1; i < rows.length && days.length < 3660; i++) {
      final row = rows[i];
      final date = _date(_at(row, dateCol));
      if (date == null) continue;
      final assignments = <String, String>{};
      for (final entry in columns.entries) {
        final name = _text(_at(row, entry.key));
        if (name.isEmpty) continue;
        assignments[entry.value] = name;
        if (seen.add(name)) employees.add(name);
      }
      days.add(
        RosterDay(
          date: date,
          dayLabel: _text(_at(row, dayCol)),
          group: _text(_at(row, groupCol)),
          assignments: assignments,
        ),
      );
    }
    if (days.isEmpty || employees.isEmpty)
      throw const FormatException(
        'No dated assignments or employee names found.',
      );
    days.sort((a, b) => a.date.compareTo(b.date));
    return ImportedRoster(
      sourceName: fileName,
      sheetName: sheetName,
      departments: columns.values.toList(),
      employees: employees,
      days: days,
    );
  }

  static Object? _at(List<Object?> row, int index) =>
      index >= 0 && index < row.length ? row[index] : null;
  static String _text(Object? value) => value == null
      ? ''
      : value.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
  static String? _date(Object? value) {
    if (value is DateTime) return _iso(value);
    if (value is num) {
      if (value < 1 || value > 100000) return null;
      return _iso(
        DateTime.utc(1899, 12, 30).add(Duration(days: value.floor())),
      );
    }
    final text = _text(value);
    if (text.isEmpty) return null;
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(text);
    if (iso != null)
      return _checked(
        int.parse(iso[1]!),
        int.parse(iso[2]!),
        int.parse(iso[3]!),
      );
    final dmy = RegExp(
      r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2,4})$',
    ).firstMatch(text);
    if (dmy != null) {
      final year = int.parse(dmy[3]!);
      return _checked(
        year < 100 ? 2000 + year : year,
        int.parse(dmy[2]!),
        int.parse(dmy[1]!),
      );
    }
    final parsed = DateTime.tryParse(text);
    return parsed == null ? null : _iso(parsed);
  }

  static String? _checked(int y, int m, int d) {
    final value = DateTime.utc(y, m, d);
    return value.year == y && value.month == m && value.day == d
        ? _iso(value)
        : null;
  }

  static String _iso(DateTime value) =>
      value.year.toString().padLeft(4, '0') +
      '-' +
      value.month.toString().padLeft(2, '0') +
      '-' +
      value.day.toString().padLeft(2, '0');
}
