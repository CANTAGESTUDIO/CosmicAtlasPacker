import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/error_handling/crash_reporter.dart';
import 'providers/theme_provider.dart';
import 'screens/editor_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runAppWithCrashReporting(
    const ProviderScope(
      child: CosmicAtlasPackerApp(),
    ),
  );
}

class CosmicAtlasPackerApp extends ConsumerStatefulWidget {
  const CosmicAtlasPackerApp({super.key});

  @override
  ConsumerState<CosmicAtlasPackerApp> createState() =>
      _CosmicAtlasPackerAppState();
}

class _CosmicAtlasPackerAppState extends ConsumerState<CosmicAtlasPackerApp>
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
      title: 'CosmicAtlasPacker',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const EditorScreen(),
    );
  }
}
