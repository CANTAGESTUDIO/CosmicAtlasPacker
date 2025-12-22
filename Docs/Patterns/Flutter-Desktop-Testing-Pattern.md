# 🧪 Flutter Desktop Testing Pattern

> Desktop integration testing strategies

---

## Overview

Testing patterns specific to desktop applications including window testing, file operations, and platform channels.

---

## Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mocktail: ^1.0.1
  golden_toolkit: ^0.15.0
```

---

## Implementation

### 1. Window Tests

```dart
// test/window_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:window_manager/window_manager.dart';

class MockWindowManager extends Mock implements WindowManager {}

void main() {
  group('WindowController', () {
    late MockWindowManager mockWindowManager;
    late WindowController controller;

    setUp(() {
      mockWindowManager = MockWindowManager();
      controller = WindowController(windowManager: mockWindowManager);
    });

    test('minimize should call windowManager.minimize', () async {
      when(() => mockWindowManager.minimize()).thenAnswer((_) async {});

      await controller.minimize();

      verify(() => mockWindowManager.minimize()).called(1);
    });

    test('maximize should toggle maximize state', () async {
      when(() => mockWindowManager.isMaximized())
          .thenAnswer((_) async => false);
      when(() => mockWindowManager.maximize()).thenAnswer((_) async {});

      await controller.maximize();

      verify(() => mockWindowManager.maximize()).called(1);
    });
  });
}
```

### 2. File Dialog Tests

```dart
// test/file_dialog_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:file_picker/file_picker.dart';

class MockFilePicker extends Mock implements FilePicker {}

void main() {
  group('FileDialogService', () {
    late MockFilePicker mockFilePicker;

    setUp(() {
      mockFilePicker = MockFilePicker();
      FilePicker.platform = mockFilePicker;
    });

    test('pickFile returns selected file', () async {
      final mockResult = FilePickerResult([
        PlatformFile(
          name: 'test.txt',
          size: 100,
          path: '/path/to/test.txt',
        ),
      ]);

      when(() => mockFilePicker.pickFiles(
        dialogTitle: any(named: 'dialogTitle'),
        type: any(named: 'type'),
      )).thenAnswer((_) async => mockResult);

      final file = await FileDialogService.pickFile();

      expect(file, isNotNull);
      expect(file!.path, '/path/to/test.txt');
    });

    test('pickFile returns null when cancelled', () async {
      when(() => mockFilePicker.pickFiles(
        dialogTitle: any(named: 'dialogTitle'),
        type: any(named: 'type'),
      )).thenAnswer((_) async => null);

      final file = await FileDialogService.pickFile();

      expect(file, isNull);
    });
  });
}
```

### 3. Integration Tests

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('can navigate through app', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify home screen
      expect(find.text('Home'), findsOneWidget);

      // Navigate to documents
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      expect(find.text('Documents'), findsOneWidget);

      // Navigate to settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('keyboard shortcuts work', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test Cmd+N for new file
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pumpAndSettle();

      // Verify new file dialog appeared
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
```

### 4. Golden Tests

```dart
// test/golden/screens_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  group('Golden Tests', () {
    testGoldens('HomeScreen renders correctly', (tester) async {
      await loadAppFonts();

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.desktop,
          const Device(
            name: 'Desktop Large',
            size: Size(1920, 1080),
          ),
        ])
        ..addScenario(
          name: 'default',
          widget: const MaterialApp(home: HomeScreen()),
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'home_screen');
    });
  });
}
```

### 5. Platform Channel Tests

```dart
// test/platform_channel_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformService', () {
    const channel = MethodChannel('com.myapp/platform');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getNativeVersion') {
          return '1.0.0';
        }
        if (call.method == 'showDialog') {
          return true;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getNativeVersion returns version string', () async {
      final version = await PlatformService.getNativeVersion();
      expect(version, '1.0.0');
    });

    test('showNativeDialog returns result', () async {
      final result = await PlatformService.showNativeDialog(
        title: 'Test',
        message: 'Test message',
      );
      expect(result, true);
    });
  });
}
```

---

## Best Practices

1. **Mock External Dependencies**: Mock window manager, file picker, etc.
2. **Integration Tests**: Test complete user flows
3. **Golden Tests**: Catch visual regressions
4. **Platform Channel Mocks**: Mock native calls in tests
5. **Test Different Window Sizes**: Test responsive layouts

---

*Generated by Archon*