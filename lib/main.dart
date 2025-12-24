import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'core/error_handling/crash_reporter.dart';
import 'providers/theme_provider.dart';
import 'screens/editor_screen.dart';
import 'theme/app_theme.dart';

/// Configure ImageCache limits to prevent memory leaks
void _configureImageCache() {
  // Limit the number of images to keep in cache (max 100 images)
  PaintingBinding.instance.imageCache.maximumSize = 100;

  // Limit total memory for images to 256MB
  PaintingBinding.instance.imageCache.maximumSizeBytes = 256 * 1024 * 1024;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure ImageCache limits before any image loading
  _configureImageCache();

  // Initialize window manager first
  await windowManager.ensureInitialized();

  // Configure window options - use hidden titlebar for custom titlebar
  const windowOptions = WindowOptions(
    minimumSize: Size(1024, 768),
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });

  // Initialize crash reporter (registers FlutterError.onError, PlatformDispatcher.onError)
  await CrashReporter.instance.initialize();

  runApp(
    const ProviderScope(
      child: CatioAtlasApp(),
    ),
  );
}

class CatioAtlasApp extends ConsumerStatefulWidget {
  const CatioAtlasApp({super.key});

  @override
  ConsumerState<CatioAtlasApp> createState() =>
      _CatioAtlasAppState();
}

class _CatioAtlasAppState extends ConsumerState<CatioAtlasApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Update theme when system brightness changes
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    ref.read(themeProvider.notifier).updatePlatformBrightness(brightness);
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final theme = AppTheme.getTheme(themeState.mode, themeState.platformBrightness);

    return MaterialApp(
      title: 'Catio Atlas',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const EditorScreen(),
    );
  }
}
