#!/bin/bash

echo "🚀 萨莉亚智能排班助手 - 项目初始化"
echo "=================================="

# 检查 Flutter 是否安装
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安装"
    echo "请访问: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter 已安装"
flutter --version

# 检查 iOS 开发环境
echo ""
echo "检查 iOS 开发环境..."
flutter doctor --ios

# 安装依赖
echo ""
echo "📦 安装依赖..."
cd "$(dirname "$0")/.."
flutter pub get

# 创建必要的目录
echo ""
echo "📁 创建目录结构..."
mkdir -p assets/icons
mkdir -p assets/images
mkdir -p lib/features/schedule/data
mkdir -p lib/features/schedule/domain
mkdir -p lib/features/schedule/presentation
mkdir -p lib/features/reminder/data
mkdir -p lib/features/reminder/domain
mkdir -p lib/features/reminder/presentation
mkdir -p lib/features/profile/data
mkdir -p lib/features/profile/domain
mkdir -p lib/features/profile/presentation

echo ""
echo "✅ 项目初始化完成！"
echo ""
echo "下一步:"
echo "1. 运行应用: flutter run"
echo "2. 查看文档: cat SETUP_GUIDE.md"
echo "3. 查看计划: cat PROJECT_PLAN.md"
