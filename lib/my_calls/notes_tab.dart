import 'package:flutter/material.dart';

import 'store.dart';

const _colors = <Color>[
  Color(0xFFE8E3F2),
  Color(0xFFFFD9D4),
  Color(0xFFFFE8B5),
  Color(0xFFD4EFDF),
  Color(0xFFD8E9FC),
  Color(0xFFE8DBCE),
];

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});
  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  String _query = '';
  bool _archive = false;
  @override
  void initState() {
    super.initState();
    MyCallsStore.instance.load();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: MyCallsStore.instance,
    builder: (context, _) {
      final scheme = Theme.of(context).colorScheme;
      final text = Theme.of(context).textTheme;
      final notes =
          MyCallsStore.instance.notes.where((n) {
            final q = _query.toLowerCase();
            return n.archived == _archive &&
                (q.isEmpty ||
                    n.title.toLowerCase().contains(q) ||
                    n.body.toLowerCase().contains(q) ||
                    n.items.any((i) => i.text.toLowerCase().contains(q)));
          }).toList()..sort((a, b) {
            if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
            return b.updatedAt.compareTo(a.updatedAt);
          });
      return Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 130),
                children: [
                  Text(
                    'Notes',
                    style: text.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Capture what matters on every call.',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Search your notes',
                      filled: true,
                      fillColor: scheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Notes'),
                        selected: !_archive,
                        onSelected: (_) => setState(() => _archive = false),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Archive'),
                        selected: _archive,
                        onSelected: (_) => setState(() => _archive = true),
                      ),
                      const Spacer(),
                      Text(
                        notes.length.toString(),
                        style: text.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (notes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(35),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _archive
                                ? Icons.archive_outlined
                                : Icons.lightbulb_outline,
                            size: 43,
                            color: scheme.primary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _archive
                                ? 'Nothing archived yet'
                                : _query.isEmpty
                                ? 'Your ideas start here'
                                : 'No matching notes',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (!_archive && _query.isEmpty)
                            Text(
                              'Tap New note to write a note or a checklist.',
                              textAlign: TextAlign.center,
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (notes.isNotEmpty)
                    LayoutBuilder(
                      builder: (context, c) {
                        final columns = c.maxWidth >= 650 ? 3 : 2;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var col = 0; col < columns; col++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: col == 0 ? 0 : 5,
                                    right: col == columns - 1 ? 0 : 5,
                                  ),
                                  child: Column(
                                    children: [
                                      for (
                                        var i = col;
                                        i < notes.length;
                                        i += columns
                                      )
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: _NoteCard(note: notes[i]),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
              if (!_archive)
                Positioned(
                  right: 20,
                  bottom: 18,
                  child: FilledButton.icon(
                    onPressed: () => _editNote(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'New note',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final CallNote note;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _colors[note.colorIndex.clamp(0, _colors.length - 1)];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Color.lerp(color, scheme.surfaceContainerLow, dark ? .74 : .15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _editNote(context, note: note),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.pinned)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 15,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              if (note.title.isNotEmpty)
                Text(
                  note.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (note.title.isNotEmpty &&
                  (note.body.isNotEmpty || note.items.isNotEmpty))
                const SizedBox(height: 8),
              if (note.body.isNotEmpty)
                Text(
                  note.body,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              for (final item in note.items.take(7))
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.done
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            decoration: item.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _editNote(BuildContext context, {CallNote? note}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _NoteEditor(note: note),
  );
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({this.note});
  final CallNote? note;
  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final _title = TextEditingController(text: widget.note?.title ?? '');
  late final _body = TextEditingController(text: widget.note?.body ?? '');
  final _newItem = TextEditingController();
  late final List<ChecklistItem> _items = List.of(widget.note?.items ?? []);
  late int _color = widget.note?.colorIndex ?? 0;
  late bool _pinned = widget.note?.pinned ?? false;
  late bool _archived = widget.note?.archived ?? false;
  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _newItem.dispose();
    super.dispose();
  }

  void _addItem() {
    final value = _newItem.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _items.add(ChecklistItem(value, false));
      _newItem.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .84,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.note == null ? 'New note' : 'Edit note',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _pinned ? 'Unpin' : 'Pin',
                    icon: Icon(
                      _pinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                    ),
                    onPressed: () => setState(() => _pinned = !_pinned),
                  ),
                  IconButton(
                    tooltip: _archived ? 'Unarchive' : 'Archive',
                    icon: Icon(
                      _archived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                    ),
                    onPressed: () => setState(() => _archived = !_archived),
                  ),
                  if (widget.note != null)
                    IconButton(
                      tooltip: 'Delete',
                      color: scheme.error,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await MyCallsStore.instance.removeNote(widget.note!.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                children: [
                  TextField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                    ),
                  ),
                  TextField(
                    controller: _body,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    minLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write your note…',
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _items.length; i++)
                    Row(
                      children: [
                        Checkbox(
                          value: _items[i].done,
                          onChanged: (_) =>
                              setState(() => _items[i] = _items[i].toggle()),
                        ),
                        Expanded(
                          child: Text(
                            _items[i].text,
                            style: TextStyle(
                              decoration: _items[i].done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 17),
                          onPressed: () => setState(() => _items.removeAt(i)),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newItem,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addItem(),
                          decoration: const InputDecoration(
                            hintText: 'Add checklist item',
                            prefixIcon: Icon(Icons.check_box_outline_blank),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _addItem,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'COLOR',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (var i = 0; i < _colors.length; i++)
                        InkWell(
                          borderRadius: BorderRadius.circular(99),
                          onTap: () => setState(() => _color = i),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: _colors[i],
                            child: _color == i
                                ? const Icon(Icons.check, color: Colors.black87)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 15),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Discard'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          _addItem();
                          if (_title.text.trim().isEmpty &&
                              _body.text.trim().isEmpty &&
                              _items.isEmpty) {
                            Navigator.pop(context);
                            return;
                          }
                          await MyCallsStore.instance.putNote(
                            CallNote(
                              id:
                                  widget.note?.id ??
                                  DateTime.now().microsecondsSinceEpoch
                                      .toString(),
                              title: _title.text.trim(),
                              body: _body.text.trim(),
                              items: List.of(_items),
                              colorIndex: _color,
                              pinned: _pinned,
                              archived: _archived,
                              updatedAt: DateTime.now().toIso8601String(),
                            ),
                          );
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Save note'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
