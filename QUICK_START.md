# 🚀 快速开始

## 1. 环境检查

```powershell
# 检查 Flutter
flutter doctor

# 如果未安装，下载：https://flutter.dev/docs/get-started/install
```

## 2. 项目初始化

```powershell
# 进入项目目录
cd flutter_app

# 运行初始化脚本
.\scripts\setup.ps1

# 或手动执行
flutter pub get
```

## 3. 运行应用

```powershell
# iOS 模拟器 (需要 macOS + Xcode)
flutter run

# 或指定设备
flutter devices
flutter run -d "iPhone 15 Pro"
```

## 4. 构建 IPA

```powershell
# 构建发布版本
.\scripts\build_ipa.ps1

# 或手动构建
flutter build ios --release --no-codesign
```

## 5. 安装到设备

### 方式1: Sideloadly (推荐)
1. 下载 [Sideloadly](https://sideloadly.io/)
2. 连接 iPhone
3. 拖入 `SaizeriYa-Scheduler.ipa`
4. 输入 Apple ID
5. 点击 Start

### 方式2: GitHub Actions
1. Push 代码到 GitHub
2. 配置 Secrets (证书)
3. 自动构建签名版本

## 6. 测试功能

### 语音提醒测试
1. 打开应用
2. 进入"提醒"页面
3. 点击右上角"测试语音"按钮
4. 锁屏测试后台播报

### 排班功能测试
1. 进入"排班"页面
2. 选择日期
3. 添加班次
4. 查看日历视图

## 项目结构

```
flutter_app/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── core/
│   │   ├── theme/app_theme.dart     # 主题配置
│   │   └── services/                # 核心服务
│   │       ├── voice_service.dart   # 语音合成
│   │       ├── notification_service.dart # 通知
│   │       ├── api_service.dart     # API 调用
│   │       └── storage_service.dart # 本地存储
│   └── features/
│       ├── home/                    # 首页
│       ├── schedule/                # 排班管理
│       └── reminder/                # 语音提醒
├── ios/                             # iOS 配置
├── pubspec.yaml                     # 依赖配置
└── scripts/                         # 构建脚本
```

## 核心优势

| 功能 | PWA | iOS Native |
|------|-----|-----------|
| 锁屏语音 | ❌ | ✅ |
| 后台运行 | ❌ | ✅ |
| 系统通知 | ⚠️ | ✅ |
| 性能 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

## 常见问题

### Q: 模拟器无法测试语音？
A: 语音功能需要真机测试，模拟器不支持 TTS

### Q: 如何配置后端 API？
A: 修改 `lib/core/services/api_service.dart` 中的 baseUrl

### Q: 免费账号可以安装吗？
A: 可以，使用 Sideloadly，每 7 天重新签名

### Q: 如何添加新功能？
A: 参考 `features/` 目录结构，按模块组织代码

## 下一步开发

1. ✅ 基础框架完成
2. ⏳ 完善排班功能
3. ⏳ 集成后端 API
4. ⏳ 添加数据同步
5. ⏳ 优化用户体验

---

**开发状态**: Phase 1 完成 ✅  
**下一阶段**: 核心功能开发 ⏳