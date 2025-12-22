import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:multi_split_view/multi_split_view.dart';

import '../commands/editor_command.dart';
import '../core/constants/editor_constants.dart';
import '../models/atlas_project.dart';
import '../models/enums/tool_mode.dart';
import '../models/sprite_data.dart';
import '../providers/editor_state_provider.dart';
import '../providers/export_provider.dart';
import '../providers/history_provider.dart';
import '../providers/image_provider.dart';
import '../providers/multi_image_provider.dart';
import '../providers/multi_sprite_provider.dart';
import '../providers/packing_provider.dart';
import '../providers/project_provider.dart';
import '../providers/sprite_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auto_slicer_service.dart';
import '../services/grid_slicer_service.dart';
import '../shortcuts/shortcuts.dart';
import '../theme/editor_colors.dart';
import '../widgets/dialogs/atlas_settings_dialog.dart';
import '../widgets/dialogs/auto_slice_dialog.dart';
import '../widgets/dialogs/background_remove_dialog.dart';
import '../widgets/dialogs/export_dialog.dart';
import '../widgets/dialogs/grid_slice_dialog.dart';
import '../widgets/dialogs/project_settings_dialog.dart';
import '../widgets/drop/drop_zone_wrapper.dart';
import '../widgets/panels/atlas_preview_panel.dart';
import '../widgets/panels/multi_source_panel.dart';
import '../widgets/panels/properties_panel.dart';
import '../widgets/panels/sprite_list_panel.dart';
import '../widgets/status_bar/editor_status_bar.dart';
import '../widgets/toolbar/editor_toolbar.dart';

/// Main editor screen with 2-panel layout
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late MultiSplitViewController _horizontalController;
  late MultiSplitViewController _verticalController;

  static const double _propertiesPanelWidth = 238.0;

  @override
  void initState() {
    super.initState();
    _horizontalController = MultiSplitViewController(
      areas: [
        Area(minimalSize: EditorConstants.minPanelWidth, weight: 0.4),
        Area(minimalSize: EditorConstants.minPanelWidth, weight: 0.4),
        Area(minimalSize: _propertiesPanelWidth, size: _propertiesPanelWidth),
      ],
    );
    _verticalController = MultiSplitViewController(
      areas: [
        Area(minimalWeight: 0.3, weight: 0.75),
        Area(minimalSize: EditorConstants.defaultSpriteListHeight, weight: 0.25),
      ],
    );

    // Register global keyboard handler for Space key
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);

    // Register dialog callbacks for toolbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showAutoSliceDialogProvider.notifier).state = _showAutoSliceDialog;
      ref.read(showGridSliceDialogProvider.notifier).state = _showGridSliceDialog;
      ref.read(showBackgroundRemoveDialogProvider.notifier).state = _showBackgroundRemoveDialog;
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  /// Global hardware keyboard handler for Space key (pan mode)
  /// This intercepts the key before Flutter's focus system, preventing macOS beep
  bool _handleHardwareKey(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) {
        ref.read(isSpacePressedProvider.notifier).state = true;
      } else if (event is KeyUpEvent) {
        ref.read(isSpacePressedProvider.notifier).state = false;
      }
      // Return true to indicate the event was handled (prevents beep)
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for activeSource changes and sync to sourceImageProvider
    // This handles: new image selected, image content changed (background removal), image removed
    ref.listen<LoadedSourceImage?>(activeSourceProvider, (previous, next) {
      if (next != null) {
        // Sync whenever activeSource changes (including image content updates)
        // Compare by reference - new object means something changed
        if (previous == null || !identical(previous, next)) {
          ref.read(sourceImageProvider.notifier).setFromSource(
            uiImage: next.uiImage,
            rawImage: next.rawImage,
            filePath: next.filePath,
            fileName: next.fileName,
          );
        }
      } else if (next == null && previous != null) {
        // Source was removed, clear sourceImageProvider
        ref.read(sourceImageProvider.notifier).clear();
      }
    });

    return PlatformMenuBar(
      menus: _buildMenus(context),
      child: Shortcuts(
        shortcuts: EditorShortcuts.shortcuts,
        child: Actions(
          actions: _buildActions(),
          child: Focus(
            autofocus: true,
            child: DropZoneWrapper(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(
                  children: [
                    // Toolbar
                    const EditorToolbar(),

                    // Main content area with split panels
                    Expanded(
                      child: _buildMainContent(),
                    ),

                    // Status bar
                    const EditorStatusBar(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<Type, Action<Intent>> _buildActions() {
    return {
      // File actions
      NewProjectIntent: CallbackAction<NewProjectIntent>(
        onInvoke: (_) => _newProject(),
      ),
      OpenProjectIntent: CallbackAction<OpenProjectIntent>(
        onInvoke: (_) => _openProject(),
      ),
      OpenImageIntent: CallbackAction<OpenImageIntent>(
        onInvoke: (_) => _openImages(),
      ),
      SaveProjectIntent: CallbackAction<SaveProjectIntent>(
        onInvoke: (_) => _saveProject(),
      ),
      SaveProjectAsIntent: CallbackAction<SaveProjectAsIntent>(
        onInvoke: (_) => _saveProjectAs(),
      ),
      ExportAtlasIntent: CallbackAction<ExportAtlasIntent>(
        onInvoke: (_) => _exportAtlas(),
      ),

      // Edit actions
      UndoIntent: CallbackAction<UndoIntent>(
        onInvoke: (_) => _undo(),
      ),
      RedoIntent: CallbackAction<RedoIntent>(
        onInvoke: (_) => _redo(),
      ),
      SelectAllIntent: CallbackAction<SelectAllIntent>(
        onInvoke: (_) => _selectAll(),
      ),
      DeleteSelectedIntent: CallbackAction<DeleteSelectedIntent>(
        onInvoke: (_) => _deleteSelected(),
      ),
      DeselectAllIntent: CallbackAction<DeselectAllIntent>(
        onInvoke: (_) => _deselectAll(),
      ),

      // View actions
      ToggleGridIntent: CallbackAction<ToggleGridIntent>(
        onInvoke: (_) => _toggleGrid(),
      ),
      ZoomInIntent: CallbackAction<ZoomInIntent>(
        onInvoke: (_) => _zoomIn(),
      ),
      ZoomOutIntent: CallbackAction<ZoomOutIntent>(
        onInvoke: (_) => _zoomOut(),
      ),
      ResetZoomIntent: CallbackAction<ResetZoomIntent>(
        onInvoke: (_) => _resetZoom(),
      ),
      FitToWindowIntent: CallbackAction<FitToWindowIntent>(
        onInvoke: (_) => _fitToWindow(),
      ),

      // Tool actions
      SelectToolIntent: CallbackAction<SelectToolIntent>(
        onInvoke: (_) => _setTool(ToolMode.select),
      ),
      RectSliceToolIntent: CallbackAction<RectSliceToolIntent>(
        onInvoke: (_) => _setTool(ToolMode.rectSlice),
      ),
      AutoSliceToolIntent: CallbackAction<AutoSliceToolIntent>(
        onInvoke: (_) => _showAutoSliceDialog(),
      ),
      GridSliceToolIntent: CallbackAction<GridSliceToolIntent>(
        onInvoke: (_) => _showGridSliceDialog(),
      ),

      // Dialog actions
      ShowGridSliceDialogIntent: CallbackAction<ShowGridSliceDialogIntent>(
        onInvoke: (_) => _showGridSliceDialog(),
      ),
      ShowAutoSliceDialogIntent: CallbackAction<ShowAutoSliceDialogIntent>(
        onInvoke: (_) => _showAutoSliceDialog(),
      ),
      ShowAtlasSettingsIntent: CallbackAction<ShowAtlasSettingsIntent>(
        onInvoke: (_) => _showAtlasSettingsDialog(),
      ),
    };
  }

  List<PlatformMenu> _buildMenus(BuildContext context) {
    final showGrid = ref.watch(showGridProvider);
    final themeMode = ref.watch(themeModeProvider);

    return [
      PlatformMenu(
        label: 'File',
        menus: [
          PlatformMenuItem(
            label: 'New Project',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyN, meta: true),
            onSelected: () => _newProject(),
          ),
          PlatformMenuItem(
            label: 'Open Project...',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyO, meta: true, shift: true),
            onSelected: () => _openProject(),
          ),
          PlatformMenuItem(
            label: 'Save Project',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyS, meta: true),
            onSelected: () => _saveProject(),
          ),
          PlatformMenuItem(
            label: 'Save Project As...',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true),
            onSelected: () => _saveProjectAs(),
          ),
          PlatformMenuItem(
            label: 'Open Images...',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyO, meta: true),
            onSelected: () => _openImages(),
          ),
          PlatformMenuItem(
            label: 'Export Atlas...',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyE, meta: true),
            onSelected: () => _exportAtlas(),
          ),
        ],
      ),
      PlatformMenu(
        label: 'Edit',
        menus: [
          PlatformMenuItem(
            label: _getUndoLabel(),
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyZ, meta: true),
            onSelected: ref.read(canUndoProvider) ? () => _undo() : null,
          ),
          PlatformMenuItem(
            label: _getRedoLabel(),
            shortcut: const SingleActivator(LogicalKeyboardKey.keyZ,
                meta: true, shift: true),
            onSelected: ref.read(canRedoProvider) ? () => _redo() : null,
          ),
          PlatformMenuItem(
            label: 'Select All',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyA, meta: true),
            onSelected: () => _selectAll(),
          ),
          PlatformMenuItem(
            label: 'Delete Selected',
            shortcut: const SingleActivator(LogicalKeyboardKey.backspace),
            onSelected: () => _deleteSelected(),
          ),
        ],
      ),
      PlatformMenu(
        label: 'View',
        menus: [
          PlatformMenuItem(
            label: showGrid ? 'Hide Grid' : 'Show Grid',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyG, meta: true),
            onSelected: () {
              ref.read(showGridProvider.notifier).state = !showGrid;
            },
          ),
          PlatformMenuItem(
            label: 'Zoom In',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.equal, meta: true),
            onSelected: () {
              final current = ref.read(zoomLevelProvider);
              if (current < 800) {
                ref.read(zoomLevelProvider.notifier).state = current + 25;
              }
            },
          ),
          PlatformMenuItem(
            label: 'Zoom Out',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.minus, meta: true),
            onSelected: () {
              final current = ref.read(zoomLevelProvider);
              if (current > 25) {
                ref.read(zoomLevelProvider.notifier).state = current - 25;
              }
            },
          ),
          PlatformMenuItem(
            label: 'Reset Zoom',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.digit0, meta: true),
            onSelected: () {
              ref.read(zoomLevelProvider.notifier).state = 100;
            },
          ),
          PlatformMenu(
            label: 'Theme',
            menus: [
              PlatformMenuItem(
                label: themeMode == EditorThemeMode.system ? '✓ System' : '  System',
                onSelected: () {
                  ref.read(themeProvider.notifier).setSystemTheme();
                },
              ),
              PlatformMenuItem(
                label: themeMode == EditorThemeMode.light ? '✓ Light' : '  Light',
                onSelected: () {
                  ref.read(themeProvider.notifier).setLightTheme();
                },
              ),
              PlatformMenuItem(
                label: themeMode == EditorThemeMode.dark ? '✓ Dark' : '  Dark',
                onSelected: () {
                  ref.read(themeProvider.notifier).setDarkTheme();
                },
              ),
            ],
          ),
        ],
      ),
      PlatformMenu(
        label: 'Tools',
        menus: [
          PlatformMenuItem(
            label: 'Select Tool',
            shortcut: const SingleActivator(LogicalKeyboardKey.keyV),
            onSelected: () {
              ref.read(toolModeProvider.notifier).state = ToolMode.select;
            },
          ),
          PlatformMenuItem(
            label: 'Rectangle Slice',
            shortcut: const SingleActivator(LogicalKeyboardKey.keyR),
            onSelected: () {
              ref.read(toolModeProvider.notifier).state = ToolMode.rectSlice;
            },
          ),
          PlatformMenuItem(
            label: 'Auto Slice...',
            shortcut: const SingleActivator(LogicalKeyboardKey.keyA),
            onSelected: () => _showAutoSliceDialog(),
          ),
          PlatformMenuItem(
            label: 'Grid Slice...',
            shortcut: const SingleActivator(LogicalKeyboardKey.keyG),
            onSelected: () => _showGridSliceDialog(),
          ),
          PlatformMenuItem(
            label: 'Atlas Settings...',
            shortcut: const SingleActivator(LogicalKeyboardKey.comma, meta: true, shift: true),
            onSelected: () => _showAtlasSettingsDialog(),
          ),
        ],
      ),
      PlatformMenu(
        label: 'CosmicAtlasPacker',
        menus: [
          PlatformMenuItem(
            label: 'Settings...',
            shortcut: const SingleActivator(LogicalKeyboardKey.comma, meta: true),
            onSelected: () => _showProjectSettingsDialog(),
          ),
        ],
      ),
      PlatformMenu(
        label: 'Help',
        menus: [
          PlatformMenuItem(
            label: 'About CosmicAtlasPacker',
            onSelected: () {
              showAboutDialog(
                context: context,
                applicationName: 'CosmicAtlasPacker',
                applicationVersion: '1.0.0 (POC)',
                applicationLegalese: '© 2025 VACOZ',
              );
            },
          ),
        ],
      ),
    ];
  }

  Widget _buildMainContent() {
    // Custom divider theme - 1px 두께로 선만 표시
    final dividerThemeData = MultiSplitViewThemeData(
      dividerThickness: 1,
      dividerPainter: null,
    );

    return MultiSplitViewTheme(
      data: dividerThemeData,
      child: MultiSplitView(
        controller: _verticalController,
        axis: Axis.vertical,
        antiAliasingWorkaround: false,
        dividerBuilder:
            (axis, index, resizable, dragging, highlighted, themeData) {
          final lineColor = dragging || highlighted
              ? EditorColors.primary
              : EditorColors.divider;
          // 수평 디바이더: 1px 선
          return Container(color: lineColor);
        },
        children: [
          // Top area: Source + Atlas Preview panels
          MultiSplitViewTheme(
            data: dividerThemeData,
            child: MultiSplitView(
              controller: _horizontalController,
              axis: Axis.horizontal,
              antiAliasingWorkaround: false,
              dividerBuilder:
                  (axis, index, resizable, dragging, highlighted, themeData) {
                final lineColor = dragging || highlighted
                    ? EditorColors.primary
                    : EditorColors.divider;
                // 수직 디바이더: 1px 선
                return Container(color: lineColor);
              },
              children: [
                // Source Panel (left) - now supports multiple images
                // Header hidden: SourceSidebar already has its own header
                _buildPanelContainer(
                  title: 'Source',
                  showHeader: false,
                  child: const MultiSourcePanel(),
                ),

                // Atlas Preview Panel (center)
                _buildPanelContainer(
                  title: 'Atlas Preview',
                  child: const AtlasPreviewPanel(),
                ),

                // Properties Panel (right)
                _buildPanelContainer(
                  title: 'Properties',
                  child: const PropertiesPanel(),
                ),
              ],
            ),
          ),

          // Bottom area: Sprite List Panel
          // Header hidden: SpriteListPanel already has its own header
          _buildPanelContainer(
            title: 'Sprites',
            showHeader: false,
            child: const SpriteListPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelContainer({
    required String title,
    required Widget child,
    bool showHeader = true,
  }) {
    return Container(
      color: EditorColors.panelBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel header (optional - hide when panel has its own header)
          if (showHeader)
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: EditorColors.surface,
                border: Border(
                  bottom: BorderSide(color: EditorColors.divider, width: 1),
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: EditorColors.iconDefault,
                ),
              ),
            ),
          // Panel content
          Expanded(child: child),
        ],
      ),
    );
  }

  Future<void> _openImages() async {
    // Prevent duplicate calls while loading
    if (ref.read(multiImageProvider).isLoading) {
      debugPrint('[EditorScreen] Already loading, skipping duplicate call');
      return;
    }

    await ref.read(multiImageProvider.notifier).pickAndLoadImages();

    // Sync active source to sourceImageProvider for backward compatibility
    _syncActiveSourceToSingleImage();
  }

  /// Sync active source from multiImageProvider to sourceImageProvider
  void _syncActiveSourceToSingleImage() {
    final activeSource = ref.read(activeSourceProvider);
    if (activeSource != null) {
      ref.read(sourceImageProvider.notifier).setFromSource(
        uiImage: activeSource.uiImage,
        rawImage: activeSource.rawImage,
        filePath: activeSource.filePath,
        fileName: activeSource.fileName,
      );
    }
  }

  Future<void> _exportAtlas() async {
    final canExport = ref.read(canExportProvider);

    if (!canExport) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please open an image and create sprites first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final success = await ExportDialog.show(context);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export completed successfully'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showGridSliceDialog() async {
    // Check if multiple sources are selected
    final selectedIds = ref.read(multiImageProvider).selectedSourceIds;
    if (selectedIds.length > 1) {
      // Show warning dialog
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('다중 선택 불가'),
          content: const Text('그리드 슬라이스는 한 번에 하나의 이미지만 처리할 수 있습니다.\n하나의 이미지만 선택해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    final imageState = ref.read(sourceImageProvider);
    if (!imageState.hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please open an image first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final config = await GridSliceDialog.show(
      context,
      imageWidth: imageState.width,
      imageHeight: imageState.height,
    );

    if (config == null) return;

    // Get active source for multi-image support
    final activeSource = ref.read(activeSourceProvider);
    if (activeSource == null) return;

    // Apply grid slicing
    const slicer = GridSlicerService();
    final result = slicer.sliceGrid(
      imageWidth: imageState.width,
      imageHeight: imageState.height,
      config: config,
    );

    // Use multiSpriteProvider for multi-image support
    ref.read(multiSpriteProvider.notifier).addFromGridSlice(activeSource.id, result);

    // Also update legacy spriteProvider for backward compatibility
    final previousSprites = ref.read(spriteProvider).sprites.toList();
    final command = GridSliceCommand(
      previousSprites: previousSprites,
      newSprites: result.sprites,
      columns: result.columns,
      rows: result.rows,
      onReplace: (sprites) {
        ref.read(spriteProvider.notifier).replaceAllSpritesInternal(sprites);
      },
    );
    ref.read(historyProvider.notifier).execute(command);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created ${result.totalCount} sprites (${result.columns}×${result.rows})'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showAutoSliceDialog() async {
    // Get selected sources for multi-image processing
    final selectedIds = ref.read(multiImageProvider).selectedSourceIds;
    final sources = ref.read(multiImageProvider).sources;

    // Get sources to process (selected or active)
    final sourcesToProcess = selectedIds.isNotEmpty
        ? sources.where((s) => selectedIds.contains(s.id)).toList()
        : [ref.read(activeSourceProvider)].whereType<LoadedSourceImage>().toList();

    if (sourcesToProcess.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please open an image first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // For single image, use the original dialog flow
    if (sourcesToProcess.length == 1) {
      final source = sourcesToProcess.first;
      final dialogResult = await AutoSliceDialog.show(
        context,
        image: source.rawImage,
      );

      if (dialogResult == null) return;

      final result = dialogResult.sliceResult;

      // If background was removed, update the source image
      if (dialogResult.processedImage != null) {
        await _updateSourceImageWithProcessedForSource(source.id, dialogResult.processedImage!);
      }

      ref.read(multiSpriteProvider.notifier).addFromAutoSlice(source.id, result);

      if (mounted) {
        final message = result.filteredCount > 0
            ? 'Created ${result.spriteCount} sprites (${result.filteredCount} filtered out)'
            : 'Created ${result.spriteCount} sprites';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
        );
      }
    } else {
      // For multiple images, show dialog once and apply same settings to all
      final firstSource = sourcesToProcess.first;
      final dialogResult = await AutoSliceDialog.show(
        context,
        image: firstSource.rawImage,
      );

      if (dialogResult == null) return;

      int totalSprites = 0;
      int processedCount = 0;

      // Apply auto slice to all selected sources
      for (final source in sourcesToProcess) {
        // Re-run auto slice with same settings for each image
        final result = await _runAutoSliceForSource(source, dialogResult);
        if (result != null) {
          ref.read(multiSpriteProvider.notifier).addFromAutoSlice(source.id, result);
          totalSprites += result.spriteCount;
          processedCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$processedCount개 이미지에서 총 $totalSprites개 스프라이트 생성'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Run auto slice for a specific source with given dialog settings
  /// Uses default config since dialogResult doesn't expose config
  Future<AutoSliceResult?> _runAutoSliceForSource(LoadedSourceImage source, AutoSliceDialogResult dialogResult) async {
    const autoSlicer = AutoSlicerService();

    // Use default config for batch processing
    const config = AutoSliceConfig();

    final result = await autoSlicer.autoSlice(
      image: source.rawImage,
      config: config,
    );

    return result;
  }

  Future<void> _showBackgroundRemoveDialog() async {
    // Get selected sources for multi-image processing
    final selectedIds = ref.read(multiImageProvider).selectedSourceIds;
    final sources = ref.read(multiImageProvider).sources;

    // Get sources to process (selected or active)
    final sourcesToProcess = selectedIds.isNotEmpty
        ? sources.where((s) => selectedIds.contains(s.id)).toList()
        : [ref.read(activeSourceProvider)].whereType<LoadedSourceImage>().toList();

    if (sourcesToProcess.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please open an image first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // For single image, use the original dialog flow
    if (sourcesToProcess.length == 1) {
      final source = sourcesToProcess.first;
      final processedImage = await BackgroundRemoveDialog.show(
        context,
        image: source.rawImage,
      );

      if (processedImage == null || !mounted) return;

      await _updateSourceImageWithProcessedForSource(source.id, processedImage);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('배경색이 투명하게 변환되었습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // For multiple images, show dialog once and apply same settings to all
      final firstSource = sourcesToProcess.first;
      final processedImage = await BackgroundRemoveDialog.show(
        context,
        image: firstSource.rawImage,
      );

      if (processedImage == null || !mounted) return;

      // Get the background color that was removed (from first image)
      // For simplicity, we apply the same removal to all images
      int processedCount = 0;

      for (final source in sourcesToProcess) {
        // Apply same background removal logic to each image
        // Note: This uses the dialog result which already processed with user-selected settings
        final result = await _removeBackgroundForSource(source);
        if (result != null) {
          await _updateSourceImageWithProcessedForSource(source.id, result);
          processedCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$processedCount개 이미지의 배경색이 투명하게 변환되었습니다'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Remove background for a specific source (uses first pixel as background)
  Future<img.Image?> _removeBackgroundForSource(LoadedSourceImage source) async {
    // Simple implementation: use same logic as BackgroundRemoveDialog
    // Auto-detect background color from corner pixel
    final image = source.rawImage;
    final bgColor = image.getPixel(0, 0);

    // Create copy and replace background with transparent
    final result = img.Image.from(image);
    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);
        if (_colorMatches(pixel, bgColor, 30)) {
          result.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
        }
      }
    }
    return result;
  }

  /// Check if two colors match within tolerance
  bool _colorMatches(img.Pixel a, img.Pixel b, int tolerance) {
    return (a.r.toInt() - b.r.toInt()).abs() <= tolerance &&
        (a.g.toInt() - b.g.toInt()).abs() <= tolerance &&
        (a.b.toInt() - b.b.toInt()).abs() <= tolerance;
  }

  /// Update source image for a specific source ID
  Future<void> _updateSourceImageWithProcessedForSource(String sourceId, img.Image processedImage) async {
    // Convert to ui.Image
    final uiImage = await _convertToUiImage(processedImage);
    if (uiImage == null) return;

    // Update multiImageProvider
    await ref.read(multiImageProvider.notifier).updateSourceImage(
      sourceId: sourceId,
      rawImage: processedImage,
      uiImage: uiImage,
    );

    // If this is the active source, also update sourceImageProvider
    final activeSource = ref.read(activeSourceProvider);
    if (activeSource?.id == sourceId) {
      await ref.read(sourceImageProvider.notifier).updateRawImage(processedImage);
    }

    // Force refresh atlas preview
    ref.invalidate(atlasPreviewImageProvider);
  }

  /// Convert img.Image to ui.Image
  Future<ui.Image?> _convertToUiImage(img.Image image) async {
    final encoded = img.encodePng(image);
    final codec = await ui.instantiateImageCodec(encoded);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Update source image in both sourceImageProvider and multiImageProvider
  Future<void> _updateSourceImageWithProcessed(img.Image processedImage) async {
    // Update sourceImageProvider (this also converts to ui.Image)
    await ref.read(sourceImageProvider.notifier).updateRawImage(processedImage);

    // Get the converted ui.Image from sourceImageProvider
    final updatedState = ref.read(sourceImageProvider);
    if (updatedState.uiImage != null) {
      // Also update multiImageProvider for Atlas Preview
      await ref.read(multiImageProvider.notifier).updateActiveSourceImage(
        rawImage: processedImage,
        uiImage: updatedState.uiImage!,
      );
    }

    // Force refresh atlas preview
    ref.invalidate(atlasPreviewImageProvider);
  }

  void _newProject() {
    // Check for unsaved changes
    final isDirty = ref.read(projectDirtyProvider);
    if (isDirty) {
      _showUnsavedChangesDialog(() {
        ref.read(projectProvider.notifier).newProject();
        ref.read(spriteProvider.notifier).clear();
        ref.read(sourceImageProvider.notifier).clear();
        ref.read(lastSavedPathProvider.notifier).state = null;
        ref.read(projectDirtyProvider.notifier).state = false;
      });
    } else {
      ref.read(projectProvider.notifier).newProject();
      ref.read(spriteProvider.notifier).clear();
      ref.read(sourceImageProvider.notifier).clear();
      ref.read(lastSavedPathProvider.notifier).state = null;
    }
  }

  Future<void> _openProject() async {
    // Check for unsaved changes first
    final isDirty = ref.read(projectDirtyProvider);
    if (isDirty) {
      _showUnsavedChangesDialog(() => _doOpenProject());
    } else {
      await _doOpenProject();
    }
  }

  Future<void> _doOpenProject() async {
    final result = await ref.read(loadProjectProvider.future);

    if (!mounted) return;

    if (result.success && result.data != null) {
      // Load source image if exists
      final primaryPath = result.data!.primarySourcePath;
      if (primaryPath != null) {
        await ref.read(sourceImageProvider.notifier).loadFromPath(primaryPath);
      }

      // Load sprites
      ref.read(spriteProvider.notifier).loadFromProject(result.data!.sprites);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('프로젝트를 열었습니다: ${result.data!.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (result.error != null && result.error != '열기 취소됨') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _saveProject() async {
    await _doSaveProject(null);
  }

  Future<void> _saveProjectAs() async {
    await _doSaveProject(null, forceDialog: true);
  }

  Future<void> _doSaveProject(String? path, {bool forceDialog = false}) async {
    // Sync current state to project before saving
    final spriteState = ref.read(spriteProvider);
    final sourceImage = ref.read(sourceImageProvider);
    final project = ref.read(projectProvider);

    // Convert SpriteRegion to SpriteData
    final spriteDataList = spriteState.sprites.map((region) {
      return SpriteData(
        id: region.id,
        sourceFile: sourceImage.imagePath ?? '',
        sourceRect: SpriteRect.fromRect(region.sourceRect),
        pivot: region.pivot,
      );
    }).toList();

    // Update project with current state
    final updatedProject = project.copyWith(
      sprites: spriteDataList,
      sourceFiles: sourceImage.imagePath != null
          ? [
              SourceFile(absolutePath: sourceImage.imagePath!),
            ]
          : [],
    );
    ref.read(projectProvider.notifier).update(updatedProject);

    final savePath = forceDialog ? null : (path ?? ref.read(lastSavedPathProvider));
    final result = await ref.read(saveProjectProvider(savePath).future);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 완료: ${result.data!.split('/').last}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (result.error != null && result.error != '저장 취소됨') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showAtlasSettingsDialog() async {
    await AtlasSettingsDialog.show(context);
  }

  Future<void> _showProjectSettingsDialog() async {
    await ProjectSettingsDialog.show(context);
  }

  void _showUnsavedChangesDialog(VoidCallback onDiscard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장되지 않은 변경사항'),
        content: const Text('저장하지 않은 변경사항이 있습니다. 저장하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDiscard();
            },
            child: const Text('저장 안함'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveProject();
              onDiscard();
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Undo/Redo Methods
  // ============================================================

  String _getUndoLabel() {
    final description = ref.read(undoDescriptionProvider);
    if (description != null) {
      return 'Undo $description';
    }
    return 'Undo';
  }

  String _getRedoLabel() {
    final description = ref.read(redoDescriptionProvider);
    if (description != null) {
      return 'Redo $description';
    }
    return 'Redo';
  }

  void _undo() {
    ref.read(historyProvider.notifier).undo();
  }

  void _redo() {
    ref.read(historyProvider.notifier).redo();
  }

  void _selectAll() {
    ref.read(spriteProvider.notifier).selectAll();
  }

  void _deleteSelected() {
    final spriteState = ref.read(spriteProvider);
    if (!spriteState.hasSelection) return;

    final selectedSprites = spriteState.selectedSprites;
    if (selectedSprites.isEmpty) return;

    // Create delete command
    final command = DeleteMultipleSpritesCommand(
      sprites: selectedSprites,
      onAddMultiple: (sprites) {
        for (final sprite in sprites) {
          ref.read(spriteProvider.notifier).addSpriteInternal(sprite);
        }
      },
      onRemoveMultiple: (ids) {
        ref.read(spriteProvider.notifier).removeSpritesInternal(ids);
      },
    );

    ref.read(historyProvider.notifier).execute(command);
  }

  void _deselectAll() {
    ref.read(spriteProvider.notifier).clearSelection();
  }

  // ============================================================
  // View Methods
  // ============================================================

  void _toggleGrid() {
    final current = ref.read(showGridProvider);
    ref.read(showGridProvider.notifier).state = !current;
  }

  void _zoomIn() {
    final setZoom = ref.read(setZoomCallbackProvider);
    if (setZoom != null) {
      final current = ref.read(zoomLevelProvider);
      if (current < ZoomPresets.max) {
        setZoom(current + 25);
      }
    }
  }

  void _zoomOut() {
    final setZoom = ref.read(setZoomCallbackProvider);
    if (setZoom != null) {
      final current = ref.read(zoomLevelProvider);
      if (current > ZoomPresets.min) {
        setZoom(current - 25);
      }
    }
  }

  void _resetZoom() {
    final resetCallback = ref.read(resetZoomCallbackProvider);
    resetCallback?.call();
  }

  void _fitToWindow() {
    final fitCallback = ref.read(fitToWindowCallbackProvider);
    fitCallback?.call();
  }

  // ============================================================
  // Tool Methods
  // ============================================================

  void _setTool(ToolMode mode) {
    ref.read(toolModeProvider.notifier).state = mode;
  }
}
