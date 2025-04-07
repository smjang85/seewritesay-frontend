import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WritingHistoryScreen extends StatefulWidget {
  final String? imagePathFilter;

  const WritingHistoryScreen({super.key, this.imagePathFilter});

  @override
  State<WritingHistoryScreen> createState() => _WritingHistoryScreenState();
}

class _WritingHistoryScreenState extends State<WritingHistoryScreen> {
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyList =
        prefs.getStringList('writingHistory') ?? [];

    final List<Map<String, dynamic>> filtered =
        historyList.map((e) => jsonDecode(e) as Map<String, dynamic>).where((
          entry,
        ) {
          if (widget.imagePathFilter == null) return true;
          return entry['image'] == widget.imagePathFilter;
        }).toList();

    filtered.sort(
      (a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''),
    );

    setState(() {
      _history = filtered;
    });
  }

  Future<void> _deleteHistoryItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    _history.removeAt(index);
    final newList = _history.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('writingHistory', newList);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("작문 히스토리")),
      body:
          _history.isEmpty
              ? const Center(child: Text("저장된 작문이 없어요."))
              : ListView.separated(
                itemCount: _history.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return ListTile(
                    leading: const Icon(Icons.edit_note),
                    title: Text(item['sentence'] ?? ''),
                    subtitle: Text(_formatTimestamp(item['timestamp'] ?? '')),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteHistoryItem(index),
                    ),
                    onTap: () {
                      context.pop(item); // ✅ go_router pop
                    },
                  );
                },
              ),
    );
  }

  String _formatTimestamp(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return "${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)} "
          "${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}:${_twoDigits(dt.second)}";
    } catch (_) {
      return raw;
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
