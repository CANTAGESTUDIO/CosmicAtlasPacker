# 🔌 Flutter Desktop Platform Channels Pattern

> Native code integration for macOS, Windows, and Linux

---

## Overview

Platform channel implementation for calling native code from Flutter desktop applications.

---

## Implementation

### 1. Method Channel Setup

```dart
// core/platform/platform_service.dart
import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel = MethodChannel('com.myapp/platform');

  static Future<String> getNativeVersion() async {
    try {
      final version = await _channel.invokeMethod<String>('getNativeVersion');
      return version ?? 'Unknown';
    } on PlatformException catch (e) {
      return 'Error: ${e.message}';
    }
  }

  static Future<bool> showNativeDialog({
    required String title,
    required String message,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('showDialog', {
        'title': title,
        'message': message,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<String?> runSystemCommand(String command) async {
    try {
      final result = await _channel.invokeMethod<String>('runCommand', {
        'command': command,
      });
      return result;
    } on PlatformException catch (e) {
      return 'Error: ${e.message}';
    }
  }
}
```

### 2. macOS Native Implementation

```swift
// macos/Runner/AppDelegate.swift
import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.myapp/platform",
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "getNativeVersion":
        result(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)

      case "showDialog":
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let message = args["message"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        result(response == .alertFirstButtonReturn)

      case "runCommand":
        guard let args = call.arguments as? [String: Any],
              let command = args["command"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }

        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        result(output)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
```

### 3. Windows Native Implementation

```cpp
// windows/runner/flutter_window.cpp
#include "flutter_window.h"
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

bool FlutterWindow::OnCreate() {
  // ... existing code ...

  flutter::MethodChannel<flutter::EncodableValue> channel(
      flutter_controller_->engine()->messenger(),
      "com.myapp/platform",
      &flutter::StandardMethodCodec::GetInstance());

  channel.SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name().compare("getNativeVersion") == 0) {
          result->Success(flutter::EncodableValue("1.0.0"));
        } else if (call.method_name().compare("showDialog") == 0) {
          const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
          if (arguments) {
            auto title_it = arguments->find(flutter::EncodableValue("title"));
            auto message_it = arguments->find(flutter::EncodableValue("message"));

            if (title_it != arguments->end() && message_it != arguments->end()) {
              std::wstring title = std::get<std::string>(title_it->second);
              std::wstring message = std::get<std::string>(message_it->second);

              int msgboxID = MessageBox(
                  NULL,
                  message.c_str(),
                  title.c_str(),
                  MB_OKCANCEL
              );

              result->Success(flutter::EncodableValue(msgboxID == IDOK));
              return;
            }
          }
          result->Error("INVALID_ARGS", "Invalid arguments");
        } else {
          result->NotImplemented();
        }
      });

  return true;
}
```

---

## Best Practices

1. **Error Handling**: Always handle PlatformException
2. **Type Safety**: Validate argument types on native side
3. **Async Operations**: Use proper async patterns
4. **Platform Check**: Check platform before calling native code
5. **Fallbacks**: Provide pure Dart fallbacks when possible

---

*Generated by Archon*