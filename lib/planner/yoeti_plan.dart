import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const planCategories = [
  'Work / School',
  'Deep Study',
  'Workout',
  'Personal',
  'Sleep',
  'Custom',
];

class PlanBlock {
  const PlanBlock({
    required this.id,
    required this.title,
    required this.category,
    required this.start,
    required this.end,
  });
  final String id;
  final String title;
  final String category;
  final int start;
  final int end;
  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'start': start,
    'end': end,
  };
  static PlanBlock? fromJson(Object? value) {
    if (value is! Map) return null;
    final title = value['title'],
        category = value['category'],
        start = value['start'],
        end = value['end'];
    if (title is! String ||
        category is! String ||
        start is! int ||
        end is! int ||
        start < 0 ||
        end > 1440 ||
        start >= end)
      return null;
    return PlanBlock(
      id: value['id'] is String
          ? value['id'] as String
          : DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      category: category,
      start: start,
      end: end,
    );
  }
}

/// A weekday's blocks recur automatically on the same weekday next week.
class YoetiPlan extends ChangeNotifier {
  YoetiPlan._();
  static final instance = YoetiPlan._();
  static const _key = 'yoeti_weekly_plan_v1';
  final Map<int, List<PlanBlock>> _days = {};
  Future<void>? _loading;
  Future<void> load() => _loading ??= _read();
  Future<void> _read() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final data = jsonDecode(prefs.getString(_key) ?? '{}');
      if (data is Map) {
        for (var day = 1; day <= 7; day++) {
          final raw = data[day.toString()];
          if (raw is List) {
            _days[day] =
                raw.map(PlanBlock.fromJson).whereType<PlanBlock>().toList()
                  ..sort((a, b) => a.start.compareTo(b.start));
          }
        }
      }
    } catch (_) {
      // A damaged local value must not stop the planner opening.
    }
    notifyListeners();
  }

  List<PlanBlock> forDate(DateTime date) =>
      List.unmodifiable(_days[date.weekday] ?? const <PlanBlock>[]);
  bool overlaps(DateTime date, int start, int end, {String? exceptId}) =>
      forDate(
        date,
      ).any((b) => b.id != exceptId && start < b.end && end > b.start);
  Future<void> put(DateTime date, PlanBlock block) async {
    await load();
    final blocks = _days.putIfAbsent(date.weekday, () => []);
    blocks.removeWhere((b) => b.id == block.id);
    blocks.add(block);
    blocks.sort((a, b) => a.start.compareTo(b.start));
    notifyListeners();
    await _save();
  }

  Future<void> remove(DateTime date, String id) async {
    await load();
    _days[date.weekday]?.removeWhere((b) => b.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        for (var day = 1; day <= 7; day++)
          day.toString(): (_days[day] ?? const <PlanBlock>[])
              .map((b) => b.toJson())
              .toList(),
      }),
    );
  }
}

String planTime(int minutes) =>
    (minutes ~/ 60).toString().padLeft(2, '0') +
    ':' +
    (minutes % 60).toString().padLeft(2, '0');
