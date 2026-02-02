# 锁屏语音播放部署指南

## 当前问题分析

用户报告："锁屏状态下还是没有语音播报"

经过代码分析，发现以下潜在问题：

### 1. 服务器文件部署问题
新的锁屏语音服务文件可能未正确部署到服务器：
- `web/lockscreen-voice-service.js`
- `web/background-voice-service.js` 
- 更新的 `web/sw.js`
- 更新的 `web/reminder-manager.js`

### 2. TTS API 问题
后端TTS API使用`espeak`，可能在服务器上不可用：
```python
subprocess.run([
    'espeak', '-v', 'zh', '-s', '150', '-a', '100',
    '-w', temp_path, text
], check=True, capture_output=True)
```

### 3. 浏览器限制
即使有所有技术方案，浏览器对锁屏/后台音频播放仍有严格限制。

## 立即解决方案

### 步骤1: 部署新的Web文件到服务器

需要将以下文件上传到 `https://service.muhuo.site` 的web目录：

1. **lockscreen-voice-service.js** - 专门的锁屏语音服务
2. **background-voice-service.js** - 多策略后台语音服务  
3. **sw.js** - 增强的Service Worker
4. **reminder-manager.js** - 更新的提醒管理器
5. **test_background_voice.html** - 综合测试页面

### 步骤2: 修复TTS API

安装espeak或使用替代方案：

```bash
# 在服务器上安装espeak
sudo apt-get update
sudo apt-get install espeak espeak-data

# 或者使用Python TTS库
pip install pyttsx3
```

### 步骤3: 测试部署

访问测试页面验证功能：
`https://service.muhuo.site/test_background_voice.html`

### 步骤4: 验证锁屏语音

1. 在手机上打开应用
2. 设置一个1分钟后的提醒
3. 锁屏等待
4. 检查是否有语音播放

## 技术方案说明

### 多层级语音播放策略

1. **Service Worker直接播放** - 在推送事件中直接播放音频
2. **Media Session API** - 利用媒体会话保持后台活跃
3. **Keep-alive音频** - 持续播放静音音频保持权限
4. **通知点击触发** - 用户点击通知时播放语音
5. **振动+持久通知** - 作为最后备选方案

### 关键技术点

- **BroadcastChannel** - 跨页面通信唤醒
- **Wake Lock** - 防止屏幕休眠
- **Audio预加载** - 提前准备音频资源
- **多种音频API** - Web Audio, HTML Audio, Speech Synthesis

## 预期效果

部署后应该能实现：
- ✅ 前台状态正常语音播放
- ✅ 后台状态语音播放（部分浏览器）
- ✅ 锁屏状态通知+振动提醒
- ✅ 解锁后立即播放待播语音
- ✅ 通知点击触发语音播放

## 浏览器限制说明

由于浏览器安全策略，完全的锁屏语音播放在某些情况下仍然受限：

- **iOS Safari**: 锁屏时音频播放被严格限制
- **Android Chrome**: 后台音频有时间限制
- **桌面浏览器**: 相对宽松，但仍有限制

因此我们提供了多种备选方案确保用户能收到提醒。