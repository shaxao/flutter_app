# 萨莉亚智能排班助手 iOS

基于Flutter开发的iOS原生应用，突破PWA限制，实现真正的后台语音提醒和锁屏通知。

## 核心优势

### PWA vs iOS Native

| 功能 | PWA | iOS Native |
|------|-----|-----------|
| 锁屏语音播报 | ❌ 不支持 | ✅ 完全支持 |
| 后台运行 | ❌ 受限 | ✅ 完全支持 |
| 本地通知 | ⚠️ 受限 | ✅ 完全支持 |
| 语音合成 | ⚠️ 需前台 | ✅ 后台可用 |
| 系统集成 | ❌ 有限 | ✅ 深度集成 |

## 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Riverpod
- **本地存储**: Hive
- **网络请求**: Dio
- **语音合成**: flutter_tts
- **本地通知**: flutter_local_notifications
- **后台任务**: workmanager

## 安装方式

### 方式1: Sideloadly (推荐)
1. 下载 `.ipa` 文件
2. 使用 Sideloadly 安装到设备
3. 信任开发者证书

### 方式2: GitHub Actions 自动签发
- 每次 push 自动构建
- 使用个人证书签名
- 生成可安装的 `.ipa`

## 开发

```bash
# 安装依赖
flutter pub get

# 运行
flutter run

# 构建 iOS
flutter build ios --release
```

## 设计系统

基于 ui-ux-pro-max 生成的设计系统：
- **风格**: Exaggerated Minimalism - 小清新、高颜值
- **配色**: Fresh Blue (#3B82F6) + Clean White + Orange CTA
- **字体**: Playfair Display SC / Karla - 优雅餐饮风格
- **布局**: Minimal Single Column - 移动优先

详见 `design-system/萨莉亚智能排班助手/MASTER.md`
