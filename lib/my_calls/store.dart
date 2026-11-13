import 'dart:convert';
import 'roster.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DutyShift {
  const DutyShift({
    required this.id,
    required this.date,
    required this.start,
    required this.end,
    required this.title,
    required this.place,
    required this.note,
    this.completed = false,
  });
  final String id, date, start, end, title, place, note;
  final bool completed;
  Map<String, Object> toJson() => {
    'id': id,
    'date': date,
    'start': start,
    'end': end,
    'title': title,
    'place': place,
    'note': note,
    'completed': completed,
  };
  static DutyShift? fromJson(Object? raw) {
    if (raw is! Map || raw['date'] is! String || raw['id'] is! String)
      return null;
    return DutyShift(
      id: raw['id'] as String,
      date: raw['date'] as String,
      start: raw['start'] as String? ?? '08:00',
      end: raw['end'] as String? ?? '16:00',
      title: raw['title'] as String? ?? 'Shift',
      place: raw['place'] as String? ?? '',
      note: raw['note'] as String? ?? '',
      completed: raw['completed'] == true,
    );
  }

  DutyShift copyWith({bool? completed}) => DutyShift(
    id: id,
    date: date,
    start: start,
    end: end,
    title: title,
    place: place,
    note: note,
    completed: completed ?? this.completed,
  );
}

class CallNote {
  const CallNote({
    required this.id,
    required this.title,
    required this.body,
    required this.items,
    required this.colorIndex,
    required this.updatedAt,
    this.pinned = false,
    this.archived = false,
  });
  final String id, title, body, updatedAt;
  final List<ChecklistItem> items;
  final int colorIndex;
  final bool pinned, archived;
  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'items': items.map((e) => e.toJson()).toList(),
    'colorIndex': colorIndex,
    'updatedAt': updatedAt,
    'pinned': pinned,
    'archived': archived,
  };
  static CallNote? fromJson(Object? raw) {
    if (raw is! Map || raw['id'] is! String) return null;
    return CallNote(
      id: raw['id'] as String,
      title: raw['title'] as String? ?? '',
      body: raw['body'] as String? ?? '',
      items: (raw['items'] is List ? raw['items'] as List : [])
          .map(ChecklistItem.fromJson)
          .whereType<ChecklistItem>()
          .toList(),
      colorIndex: raw['colorIndex'] is int ? raw['colorIndex'] as int : 0,
      updatedAt: raw['updatedAt'] as String? ?? '',
      pinned: raw['pinned'] == true,
      archived: raw['archived'] == true,
    );
  }

  CallNote copyWith({
    bool? pinned,
    bool? archived,
    List<ChecklistItem>? items,
  }) => CallNote(
    id: id,
    title: title,
    body: body,
    items: items ?? this.items,
    colorIndex: colorIndex,
    updatedAt: DateTime.now().toIso8601String(),
    pinned: pinned ?? this.pinned,
    archived: archived ?? this.archived,
  );
}

class ChecklistItem {
  const ChecklistItem(this.text, this.done);
  final String text;
  final bool done;
  Map<String, Object> toJson() => {'text': text, 'done': done};
  static ChecklistItem? fromJson(Object? raw) =>
      raw is Map && raw['text'] is String
      ? ChecklistItem(raw['text'] as String, raw['done'] == true)
      : null;
  ChecklistItem toggle() => ChecklistItem(text, !done);
}

class MyCallsStore extends ChangeNotifier {
  MyCallsStore._();
  static final instance = MyCallsStore._();
  static const _key = 'my_calls_data_v1';
  final List<DutyShift> shifts = [];
  final List<CallNote> notes = [];
  String quoteMode = 'care';
  ImportedRoster? roster;
  String selectedEmployee = '';
  Future<void>? _loading;
  Future<void> load() => _loading ??= _read();
  Future<void> _read() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = jsonDecode(prefs.getString(_key) ?? '{}');
      if (raw is Map) {
        quoteMode = raw['quoteMode'] == 'quran' ? 'quran' : 'care';
        roster = ImportedRoster.fromJson(raw['roster']);
        final selected = raw['selectedEmployee'] as String? ?? '';
        selectedEmployee = roster?.employees.contains(selected) == true
            ? selected
            : (roster?.employees.firstOrNull ?? '');
        shifts.addAll(
          (raw['shifts'] is List ? raw['shifts'] as List : [])
              .map(DutyShift.fromJson)
              .whereType<DutyShift>(),
        );
        notes.addAll(
          (raw['notes'] is List ? raw['notes'] as List : [])
              .map(CallNote.fromJson)
              .whereType<CallNote>(),
        );
      }
    } catch (_) {
      // Retain an empty usable store if local data is corrupt.
    }
    notifyListeners();
  }

  Future<void> setRoster(ImportedRoster value) async {
    await load();
    roster = value;
    selectedEmployee = value.employees.contains(selectedEmployee)
        ? selectedEmployee
        : value.employees.first;
    notifyListeners();
    await _save();
  }

  Future<void> selectEmployee(String name) async {
    await load();
    if (roster?.employees.contains(name) != true) return;
    selectedEmployee = name;
    notifyListeners();
    await _save();
  }

  Future<void> setQuoteMode(String mode) async {
    await load();
    quoteMode = mode == 'quran' ? 'quran' : 'care';
    notifyListeners();
    await _save();
  }

  Future<void> putShift(DutyShift shift) async {
    await load();
    shifts.removeWhere((e) => e.id == shift.id);
    shifts.add(shift);
    shifts.sort(
      (a, b) => a.date.compareTo(b.date) == 0
          ? a.start.compareTo(b.start)
          : a.date.compareTo(b.date),
    );
    notifyListeners();
    await _save();
  }

  Future<void> removeShift(String id) async {
    await load();
    shifts.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> putNote(CallNote note) async {
    await load();
    notes.removeWhere((e) => e.id == note.id);
    notes.add(note);
    notifyListeners();
    await _save();
  }

  Future<void> removeNote(String id) async {
    await load();
    notes.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'shifts': shifts.map((e) => e.toJson()).toList(),
        'notes': notes.map((e) => e.toJson()).toList(),
        'quoteMode': quoteMode,
        'roster': roster?.toJson(),
        'selectedEmployee': selectedEmployee,
      }),
    );
  }
}

String dayKey(DateTime day) =>
    day.year.toString().padLeft(4, '0') +
    '-' +
    day.month.toString().padLeft(2, '0') +
    '-' +
    day.day.toString().padLeft(2, '0');
