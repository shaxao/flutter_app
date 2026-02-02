#!/bin/bash

echo "🔨 构建 iOS IPA"
echo "==============="

cd "$(dirname "$0")/.."

# 清理
echo "🧹 清理旧构建..."
flutter clean
flutter pub get

# 构建 iOS (无签名)
echo ""
echo "📱 构建 iOS Release..."
flutter build ios --release --no-codesign

# 创建 IPA
echo ""
echo "📦 打包 IPA..."
cd build/ios/iphoneos
mkdir -p Payload
cp -r Runner.app Payload/
zip -r ../../../SaizeriYa-Scheduler.ipa Payload
rm -rf Payload

cd ../../..

echo ""
echo "✅ IPA 构建完成！"
echo "📍 位置: $(pwd)/SaizeriYa-Scheduler.ipa"
echo ""
echo "下一步:"
echo "1. 使用 Sideloadly 安装到设备"
echo "2. 或上传到 GitHub Actions 自动签名"
