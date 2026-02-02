#!/bin/bash
# iOS锁屏语音播放测试命令

# 清理并获取依赖
flutter clean
flutter pub get

# 运行iOS锁屏语音测试
flutter run test_ios_lockscreen_voice.dart --target=test_ios_lockscreen_voice.dart

# 或者运行主应用
flutter run

# 构建iOS应用
flutter build ios --release
