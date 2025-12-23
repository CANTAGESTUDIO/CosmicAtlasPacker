import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_handling/crash_log_storage.dart';
import '../../core/error_handling/crash_reporter.dart';
import '../../theme/editor_colors.dart';

/// 크래시 로그 뷰어 다이얼로그
class CrashLogViewerDialog extends ConsumerStatefulWidget {
  const CrashLogViewerDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) => const CrashLogViewerDialog(),
    );
  }

  @override
  ConsumerState<CrashLogViewerDialog> createState() =>
      _CrashLogViewerDialogState();
}

class _CrashLogViewerDialogState extends ConsumerState<CrashLogViewerDialog> {
  List<String> _logFiles = [];
  String? _selectedLogPath;
  String? _logContent;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadLogFiles();
  }

  Future<void> _loadLogFiles() async {
    setState(() => _isLoading = true);

    try {
      final paths = await CrashReporter.instance.getLogFilePaths();
      final storage = CrashLogStorage.instance;
      final allPaths = await storage.getLogFilePaths();

      // 중복 제거하고 합치기
      final uniquePaths = {...paths, ...allPaths}.toList()
        ..sort((a, b) => b.compareTo(a));

      setState(() {
        _logFiles = uniquePaths;
        _isLoading = false;
      });

      // 첫 번째 로그 파일 자동 선택
      if (_logFiles.isNotEmpty) {
        _selectLogFile(_logFiles[0]);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectLogFile(String path) async {
    setState(() => _selectedLogPath = path);

    try {
      final content = await CrashReporter.instance.readLogFile(path);
      setState(() => _logContent = content ?? '로그를 읽을 수 없습니다.');
    } catch (e) {
      setState(() => _logContent = '로그를 읽는 중 오류가 발생했습니다.');
    }
  }

  Future<void> _deleteLogFile(String path) async {
    setState(() => _isDeleting = true);

    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        await _loadLogFiles();
      }
    } catch (e) {
      // 삭제 실패 시 무시
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  Future<void> _clearAllLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 로그 삭제'),
        content: const Text('모든 크래시 로그를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await CrashReporter.instance.clearLogs();
        await _loadLogFiles();
      } catch (e) {
        // 삭제 실패 시 무시
      } finally {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _copyLogContent() {
    if (_logContent != null) {
      Clipboard.setData(ClipboardData(text: _logContent!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('클립보드에 복사됨')),
      );
    }
  }

  void _openLogDirectory() {
    final path = CrashReporter.instance.logDirectoryPath;
    if (path != null) {
      // 파일 탐색기 열기 (플랫폼별)
      // Note: Flutter에서 직접 파일 탐색기를 열기는 제한적입니다
      // 사용자에게 경로를 복사하여 제공
      Clipboard.setData(ClipboardData(text: path));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그 폴더 경로가 복사됨: $path'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  String _formatFileDate(String fileName) {
    // crash_YYYYMMDD.log 형식에서 날짜 추출
    final match = RegExp(r'crash_(\d{4})(\d{2})(\d{2})\.log').firstMatch(fileName);
    if (match != null) {
      return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
    }
    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.bug_report, color: Colors.orange[300]),
          const SizedBox(width: 8),
          const Text('크래시 로그 뷰어'),
        ],
      ),
      content: SizedBox(
        width: 800,
        height: 500,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽: 로그 파일 목록
            SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '로그 파일',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_logFiles.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          tooltip: '모든 로그 삭제',
                          onPressed: _isDeleting ? null : _clearAllLogs,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _logFiles.isEmpty
                            ? const Center(
                                child: Text(
                                  '로그 파일 없음',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _logFiles.length,
                                itemBuilder: (context, index) {
                                  final path = _logFiles[index];
                                  final fileName = _getFileName(path);
                                  final isSelected =
                                      _selectedLogPath == path;

                                  return ListTile(
                                    dense: true,
                                    selected: isSelected,
                                    selectedTileColor:
                                        EditorColors.selection.withValues(alpha: 0.3),
                                    title: Text(
                                      _formatFileDate(fileName),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    subtitle: Text(
                                      fileName,
                                      style: const TextStyle(fontSize: 10),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _selectLogFile(path),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 16,
                                      ),
                                      onPressed: _isDeleting
                                          ? null
                                          : () => _deleteLogFile(path),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 오른쪽: 로그 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_selectedLogPath != null)
                        Expanded(
                          child: Text(
                            _getFileName(_selectedLogPath!),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.content_copy, size: 18),
                            tooltip: '복사',
                            onPressed: _logContent != null ? _copyLogContent : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.folder_open, size: 18),
                            tooltip: '로그 폴더 열기',
                            onPressed: _openLogDirectory,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: _logContent == null
                          ? const Center(
                              child: Text(
                                '로그를 선택하세요',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : SingleChildScrollView(
                              child: SelectableText(
                                _logContent!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
