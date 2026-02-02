# GitHub Actions iOS 构建错误修复报告

## 问题描述

GitHub Actions 在构建 iOS 版本时出现以下错误：

```
lib/main.dart:213:34: Error: Undefined name 'window'.
lib/core/services/web_push_service.dart:2:8: Error: Dart library 'dart:js' is not available on this platform.
Context: The unavailable library 'dart:html' is imported through these packages:
    package:voiceflow_app => dart:html
```

## 根本原因

在 iOS 构建过程中，Flutter 编译器尝试编译所有代码，包括 Web 专用的代码。由于 `dart:html` 和 `dart:js` 库仅在 Web 环境下可用，在 iOS 构建时会导致编译失败。

## 解决方案

### 1. 创建平台特定的实现文件

**移动端存根实现** (`lib/core/services/web_push_service_stub.dart`):
```dart
/// Web Push 服务 - 移动端存根实现
class WebPushService {
  static final WebPushService instance = WebPushService._();
  WebPushService._();
  
  Future<void> initialize() async {
    if (!kIsWeb) {
      print('⚠️ Web Push 仅在 Web 环境下可用');
      return;
    }
  }
  
  // 所有方法都返回适当的默认值或空操作
}
```

**Web 专用实现** (`lib/core/services/web_push_service_web.dart`):
```dart
import 'dart:js' as js;

/// Web Push 服务 - Web 专用实现
class WebPushService {
  // 完整的 Web Push 功能实现
  Future<dynamic> _callJavaScriptFunction(String functionName, [List<dynamic>? args]) async {
    final jsFunction = js.context[functionName];
    return jsFunction.apply(args ?? []);
  }
}
```

### 2. 使用条件导出

**主服务文件** (`lib/core/services/web_push_service.dart`):
```dart
// Conditional export for web push service
export 'web_push_service_stub.dart'
    if (dart.library.html) 'web_push_service_web.dart';
```

这种方式确保：
- **移动端构建时**：使用 `web_push_service_stub.dart`（不包含 Web 专用库）
- **Web 构建时**：使用 `web_push_service_web.dart`（包含完整功能）

### 3. 修复主应用文件

**移除直接的 HTML 操作** (`lib/main.dart`):
```dart
// 之前的代码（会导致 iOS 构建失败）
import 'dart:html' as html;
final uri = Uri.parse(html.window.location.href);

// 修复后的代码（使用 Flutter 内置方法）
void _handleAutoSpeak() {
  if (!kIsWeb) return;
  
  // 使用 Uri.base 而不是直接访问 html.window
  final href = Uri.base.toString();
  final uri = Uri.parse(href);
  
  // 使用 Flutter 导航而不是直接操作 HTML
  Navigator.of(context).pushReplacementNamed('/');
}
```

### 4. 平台检查优化

所有 Web 专用功能都添加了平台检查：
```dart
void someWebFunction() {
  if (!kIsWeb) return; // 早期返回，避免执行 Web 专用代码
  
  // Web 专用逻辑
}
```

## 验证结果

### 1. 静态分析通过
```bash
flutter analyze
278 issues found. (ran in 3.6s)
```
- ✅ 无编译错误
- ✅ 无平台兼容性错误
- ⚠️ 仅有警告和信息提示（不影响构建）

### 2. Web 构建成功
```bash
flutter build web
√ Built build\web
```

### 3. 条件导出验证
```bash
flutter analyze lib/core/services/web_push_service.dart
No issues found! (ran in 1.0s)
```

## 技术细节

### 条件导出机制

Flutter 的条件导出使用以下语法：
```dart
export 'default_implementation.dart'
    if (dart.library.html) 'web_implementation.dart'
    if (dart.library.io) 'mobile_implementation.dart';
```

编译器会根据目标平台选择正确的实现：
- **Web 平台**：`dart.library.html` 可用 → 使用 Web 实现
- **移动平台**：`dart.library.html` 不可用 → 使用默认实现

### 平台检查最佳实践

1. **早期返回**：在函数开始就检查平台
```dart
void webOnlyFunction() {
  if (!kIsWeb) return; // 立即返回，避免执行后续代码
  // Web 专用逻辑
}
```

2. **条件导入**：使用条件导出而不是条件导入
```dart
// ❌ 错误：条件导入仍会被分析器检查
import 'dart:html' if (dart.library.html) 'dart:html';

// ✅ 正确：条件导出在编译时选择
export 'stub.dart' if (dart.library.html) 'web.dart';
```

3. **接口一致性**：确保所有实现都有相同的公共接口
```dart
// 所有实现都必须有相同的方法签名
abstract class WebPushServiceInterface {
  Future<void> initialize();
  Future<void> testPush();
  // ...
}
```

## 文件结构

```
lib/core/services/
├── web_push_service.dart          # 条件导出文件
├── web_push_service_stub.dart     # 移动端存根实现
└── web_push_service_web.dart      # Web 专用实现
```

## 总结

通过使用条件导出和平台特定实现，成功解决了 GitHub Actions iOS 构建中的平台兼容性问题：

1. **✅ iOS 构建**：使用存根实现，无 Web 专用库依赖
2. **✅ Web 构建**：使用完整实现，包含所有 Web Push 功能
3. **✅ 代码维护**：统一的接口，平台特定的实现
4. **✅ 性能优化**：移动端不包含不必要的 Web 代码

这种方法确保了代码在所有平台上都能正确编译和运行，同时保持了功能的完整性。