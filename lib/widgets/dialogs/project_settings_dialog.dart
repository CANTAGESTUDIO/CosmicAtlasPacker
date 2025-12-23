import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/project_settings.dart';
import '../../providers/project_settings_provider.dart';
import '../../theme/editor_colors.dart';
import '../common/draggable_dialog.dart';

/// Dialog for configuring project-wide settings
class ProjectSettingsDialog extends ConsumerStatefulWidget {
  const ProjectSettingsDialog({super.key});

  /// Show project settings dialog
  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => const ProjectSettingsDialog(),
    );
  }

  @override
  ConsumerState<ProjectSettingsDialog> createState() =>
      _ProjectSettingsDialogState();
}

class _ProjectSettingsDialogState extends ConsumerState<ProjectSettingsDialog> {
  late TextEditingController _projectNameController;
  late TextEditingController _maxWidthController;
  late TextEditingController _maxHeightController;
  late TextEditingController _paddingController;

  late bool _powerOfTwo;
  late bool _trimTransparent;
  late bool _autoSaveEnabled;
  late int _autoSaveInterval;
  late bool _rememberLastProject;
  late bool _showGridByDefault;

  String? _validationError;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(projectSettingsProvider);

    _projectNameController =
        TextEditingController(text: settings.defaultProjectName);
    _maxWidthController = TextEditingController(
        text: settings.defaultAtlasSettings.maxWidth.toString());
    _maxHeightController = TextEditingController(
        text: settings.defaultAtlasSettings.maxHeight.toString());
    _paddingController = TextEditingController(
        text: settings.defaultAtlasSettings.padding.toString());

    _powerOfTwo = settings.defaultAtlasSettings.powerOfTwo;
    _trimTransparent = settings.defaultAtlasSettings.trimTransparent;
    _autoSaveEnabled = settings.autoSaveEnabled;
    _autoSaveInterval = settings.autoSaveIntervalSeconds;
    _rememberLastProject = settings.rememberLastProject;
    _showGridByDefault = settings.showGridByDefault;
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _maxWidthController.dispose();
    _maxHeightController.dispose();
    _paddingController.dispose();
    super.dispose();
  }

  void _validate() {
    final projectName = _projectNameController.text;
    final maxWidth = int.tryParse(_maxWidthController.text);
    final maxHeight = int.tryParse(_maxHeightController.text);
    final padding = int.tryParse(_paddingController.text);

    setState(() {
      if (projectName.isEmpty) {
        _validationError = '프로젝트명을 입력해주세요';
      } else if (projectName.length > 100) {
        _validationError = '프로젝트명은 100자 이내로 입력해주세요';
      } else if (maxWidth == null || maxWidth < 64 || maxWidth > 8192) {
        _validationError = '최대 너비는 64 ~ 8192 사이여야 합니다';
      } else if (maxHeight == null || maxHeight < 64 || maxHeight > 8192) {
        _validationError = '최대 높이는 64 ~ 8192 사이여야 합니다';
      } else if (padding == null || padding < 0 || padding > 32) {
        _validationError = '패딩은 0 ~ 32 사이여야 합니다';
      } else {
        _validationError = null;
      }
    });
  }

  void _applySettings() {
    if (_validationError != null) return;

    final notifier = ref.read(projectSettingsProvider.notifier);

    // Update default project name
    notifier.updateDefaultProjectName(_projectNameController.text);

    // Update atlas settings
    notifier.updateDefaultMaxWidth(
        int.tryParse(_maxWidthController.text) ?? 2048);
    notifier.updateDefaultMaxHeight(
        int.tryParse(_maxHeightController.text) ?? 2048);
    notifier.updateDefaultPadding(int.tryParse(_paddingController.text) ?? 2);

    // Update current state values
    final currentSettings = ref.read(projectSettingsProvider);
    if (currentSettings.defaultAtlasSettings.powerOfTwo != _powerOfTwo) {
      notifier.toggleDefaultPowerOfTwo();
    }
    if (currentSettings.defaultAtlasSettings.trimTransparent !=
        _trimTransparent) {
      notifier.toggleDefaultTrimTransparent();
    }

    // Update auto-save settings
    notifier.setAutoSaveEnabled(_autoSaveEnabled);
    notifier.updateAutoSaveInterval(_autoSaveInterval);

    // Update other settings
    if (currentSettings.rememberLastProject != _rememberLastProject) {
      notifier.toggleRememberLastProject();
    }
    if (currentSettings.showGridByDefault != _showGridByDefault) {
      notifier.toggleShowGridByDefault();
    }

    Navigator.of(context).pop();
  }

  void _resetToDefaults() {
    setState(() {
      _projectNameController.text = 'Untitled';
      _maxWidthController.text = '2048';
      _maxHeightController.text = '2048';
      _paddingController.text = '2';
      _powerOfTwo = true;
      _trimTransparent = true;
      _autoSaveEnabled = false;
      _autoSaveInterval = 60;
      _rememberLastProject = true;
      _showGridByDefault = true;
      _validationError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableDialog(
      header: _buildHeader(),
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project settings section
                  _buildSectionCard(
                    title: '프로젝트',
                    icon: Icons.folder_outlined,
                    children: [
                      _buildProjectNameField(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Default atlas settings section
                  _buildSectionCard(
                    title: '기본 아틀라스 설정',
                    icon: Icons.grid_view_outlined,
                    children: [
                      _buildAtlasSizeInputs(),
                      const SizedBox(height: 12),
                      _buildPaddingInput(),
                      const SizedBox(height: 12),
                      _buildAtlasOptions(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Auto-save section
                  _buildSectionCard(
                    title: '자동 저장',
                    icon: Icons.save_outlined,
                    children: [
                      _buildAutoSaveToggle(),
                      if (_autoSaveEnabled) ...[
                        const SizedBox(height: 12),
                        _buildAutoSaveInterval(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Editor defaults section
                  _buildSectionCard(
                    title: '에디터 기본값',
                    icon: Icons.settings_outlined,
                    children: [
                      _buildEditorDefaults(),
                    ],
                  ),

                  // Validation error
                  if (_validationError != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(),
                  ],
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _resetToDefaults,
                    child: const Text('초기화'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  FilledButton(
                    onPressed: _validationError == null ? _applySettings : null,
                    child: const Text('저장'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: EditorColors.panelBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: const Row(
        children: [
          Text(
            '프로젝트 설정',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: EditorColors.iconDefault,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: EditorColors.panelBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EditorColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: EditorColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
              border: Border(
                bottom: BorderSide(color: EditorColors.border),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: EditorColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: EditorColors.iconDefault,
                  ),
                ),
              ],
            ),
          ),
          // Section content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '기본 프로젝트명',
          style: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled,
          ),
        ),
        const SizedBox(height: 4),
        Focus(
          onKeyEvent: (node, event) => KeyEventResult.skipRemainingHandlers,
          child: TextField(
            controller: _projectNameController,
            decoration: const InputDecoration(
              isDense: true,
              hintText: '새 프로젝트 생성 시 기본 이름',
            ),
            onChanged: (_) => _validate(),
          ),
        ),
      ],
    );
  }

  Widget _buildAtlasSizeInputs() {
    return Row(
      children: [
        Expanded(
          child: _NumberField(
            label: '최대 너비',
            controller: _maxWidthController,
            suffix: 'px',
            hint: '64 - 8192',
            onChanged: (_) => _validate(),
          ),
        ),
        const SizedBox(width: 16),
        const Text('×', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 16),
        Expanded(
          child: _NumberField(
            label: '최대 높이',
            controller: _maxHeightController,
            suffix: 'px',
            hint: '64 - 8192',
            onChanged: (_) => _validate(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaddingInput() {
    return _NumberField(
      label: '패딩',
      controller: _paddingController,
      suffix: 'px',
      hint: '0 - 32',
      tooltip: '스프라이트 사이 간격',
      onChanged: (_) => _validate(),
    );
  }

  Widget _buildAtlasOptions() {
    return Column(
      children: [
        _OptionRow(
          label: 'Power of Two',
          description: '아틀라스 크기를 2의 제곱으로 강제',
          value: _powerOfTwo,
          onChanged: (value) => setState(() => _powerOfTwo = value),
        ),
        const SizedBox(height: 8),
        _OptionRow(
          label: '투명 영역 제거',
          description: '스프라이트 가장자리 투명 픽셀 제거',
          value: _trimTransparent,
          onChanged: (value) => setState(() => _trimTransparent = value),
        ),
      ],
    );
  }

  Widget _buildAutoSaveToggle() {
    return _OptionRow(
      label: '자동 저장 활성화',
      description: '작업 중 프로젝트를 자동으로 저장',
      value: _autoSaveEnabled,
      onChanged: (value) => setState(() => _autoSaveEnabled = value),
    );
  }

  Widget _buildAutoSaveInterval() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '저장 간격',
          style: TextStyle(
            fontSize: 11,
            color: EditorColors.iconDisabled,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: AutoSaveIntervals.values.map((interval) {
            final isSelected = _autoSaveInterval == interval;
            return ChoiceChip(
              label: Text(AutoSaveIntervals.label(interval)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _autoSaveInterval = interval);
                }
              },
              selectedColor: EditorColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected
                    ? EditorColors.primary
                    : EditorColors.iconDefault,
                fontSize: 12,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEditorDefaults() {
    return Column(
      children: [
        _OptionRow(
          label: '마지막 프로젝트 기억',
          description: '앱 시작 시 마지막 프로젝트 경로 기억',
          value: _rememberLastProject,
          onChanged: (value) => setState(() => _rememberLastProject = value),
        ),
        const SizedBox(height: 8),
        _OptionRow(
          label: '그리드 기본 표시',
          description: '새 프로젝트에서 그리드 오버레이 표시',
          value: _showGridByDefault,
          onChanged: (value) => setState(() => _showGridByDefault = value),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: EditorColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: EditorColors.error),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: EditorColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _validationError!,
              style: TextStyle(
                color: EditorColors.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? suffix;
  final String? hint;
  final String? tooltip;
  final ValueChanged<String>? onChanged;

  const _NumberField({
    required this.label,
    required this.controller,
    this.suffix,
    this.hint,
    this.tooltip,
    this.onChanged,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 11,
                color: EditorColors.iconDisabled,
              ),
            ),
            if (widget.tooltip != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: widget.tooltip!,
                child: const Icon(
                  Icons.info_outline,
                  size: 12,
                  color: EditorColors.iconDisabled,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Focus(
          onKeyEvent: (node, event) {
            if (_focusNode.hasFocus) {
              return KeyEventResult.skipRemainingHandlers;
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              isDense: true,
              suffixText: widget.suffix,
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: 12,
                color: EditorColors.iconDisabled.withValues(alpha: 0.5),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: widget.onChanged,
          ),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OptionRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: value
                          ? EditorColors.primary
                          : EditorColors.iconDefault,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 10,
                      color: EditorColors.iconDisabled,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
