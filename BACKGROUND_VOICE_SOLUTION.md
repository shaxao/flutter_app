# 🔊 锁屏/后台语音播放解决方案

## 问题描述
用户反馈：**"软件在锁屏状态或者后台状态下只能进行通知，无法进行语音播报"**

这是一个关键问题，因为语音提醒的核心价值就是在用户无法看到屏幕时提供音频提醒。

## 技术挑战

### 浏览器限制
1. **Web Audio API** - 在后台/锁屏时被暂停
2. **SpeechSynthesis** - 在后台时被禁用
3. **HTML Audio** - 播放受到严格限制
4. **用户交互要求** - 音频播放需要用户交互激活

### 移动端特殊限制
- iOS Safari 对后台音频播放有严格限制
- Android Chrome 的后台策略不断收紧
- PWA 应用的后台执行能力有限

## 🛠️ 完整解决方案

### 1. 多层次音频播放策略

我实现了一个**BackgroundVoiceService**，使用多种策略确保音频播放：

```javascript
playbackStrategies = [
  'mediaSessionAudio',    // 最高优先级：Media Session API
  'keepAliveAudio',       // 保活音频
  'webAudioAPI',          // Web Audio API
  'htmlAudio',            // HTML Audio
  'speechSynthesis',      // 语音合成（最后备选）
]
```

### 2. Media Session API 集成

**关键技术**：使用Media Session API让应用表现得像音乐播放器

```javascript
navigator.mediaSession.metadata = new MediaMetadata({
  title: '食材过期提醒',
  artist: 'VoiceFlow智能助手',
  album: '语音提醒系统',
  artwork: [{ src: '/icons/Icon-192.png', sizes: '192x192' }]
});

navigator.mediaSession.playbackState = 'playing';
```

**优势**：
- ✅ 在锁屏界面显示媒体控制
- ✅ 系统认为这是合法的音频播放
- ✅ 可以在后台保持活跃状态

### 3. 保活音频机制

**核心思路**：使用极低音量的循环音频保持音频上下文活跃

```javascript
// 创建静音保活音频
this.keepAliveAudio = new Audio(silentAudioData);
this.keepAliveAudio.loop = true;
this.keepAliveAudio.volume = 0.01; // 极低音量
```

**工作原理**：
- 🔄 持续播放静音音频保持音频权限
- 🔊 需要播放语音时临时切换音频源
- 🔄 播放完成后恢复保活状态

### 4. Service Worker 音频播放

**突破性方案**：在Service Worker中直接播放音频

```javascript
// 在推送事件中直接播放音频
const audioPlayPromise = (async () => {
  const ttsResponse = await fetch('/api/v1/tts', {
    method: 'POST',
    body: JSON.stringify({ text: data.body })
  });
  
  const audioBlob = await ttsResponse.blob();
  const audio = new Audio(URL.createObjectURL(audioBlob));
  await audio.play(); // 在Service Worker中播放
})();
```

### 5. 后端TTS API

**服务端支持**：提供TTS音频生成API

```python
@app.post('/api/v1/tts')
def text_to_speech():
    # 使用系统TTS或第三方API生成音频
    # 返回音频文件供前端播放
```

### 6. Wake Lock 保持屏幕活跃

```javascript
// 请求屏幕唤醒锁，防止系统休眠
this.wakeLock = await navigator.wakeLock.request('screen');
```

## 📁 文件结构

### 新增文件
- `web/background-voice-service.js` - 后台语音服务核心
- `web/test_background_voice.html` - 功能测试页面
- `backend/app.py` - 新增TTS API端点

### 修改文件
- `web/sw.js` - 增强Service Worker音频播放
- `web/reminder-manager.js` - 集成后台语音服务
- `web/index.html` - 加载后台语音服务

## 🧪 测试方法

### 1. 基础测试
访问：`http://localhost:8080/test_background_voice.html`

### 2. 锁屏测试步骤
1. 打开应用并允许通知权限
2. 创建1-2分钟后的提醒
3. **锁定屏幕或切换到后台**
4. 等待提醒时间到达
5. 观察是否收到：
   - ✅ 推送通知
   - ✅ 语音播报
   - ✅ 锁屏媒体控制显示

### 3. 验证要点
- [ ] 锁屏状态下能听到语音
- [ ] 后台状态下能听到语音
- [ ] 锁屏界面显示媒体控制
- [ ] 通知点击能触发语音播放
- [ ] 多种播放策略都能工作

## 🎯 预期效果

### 成功标准
1. **锁屏语音播放** ✅
   - 用户锁屏后仍能听到语音提醒
   - 锁屏界面显示媒体播放控制

2. **后台语音播放** ✅
   - 应用在后台时仍能播放语音
   - 不需要用户切换回应用

3. **多重保障** ✅
   - 即使某种播放方式失败，其他方式仍能工作
   - 提供多种音频播放策略

4. **用户体验** ✅
   - 无需额外操作
   - 语音播放及时、清晰
   - 系统集成良好

## 🚀 部署步骤

1. **更新前端文件**：
   ```bash
   # 确保所有新文件都已部署
   - web/background-voice-service.js
   - web/test_background_voice.html
   ```

2. **重启后端服务**：
   ```bash
   cd /opt/saliya
   pkill -f "python.*app.py"
   nohup python3 app.py > run.log 2>&1 &
   ```

3. **测试验证**：
   ```bash
   # 访问测试页面
   https://service.muhuo.site/test_background_voice.html
   ```

## 🔧 故障排除

### 如果仍然无法播放语音

1. **检查权限**：
   - 通知权限是否已授予
   - 音频播放权限是否激活

2. **检查Service Worker**：
   - 是否正确注册
   - 推送事件是否正常接收

3. **检查后端**：
   - TTS API是否正常工作
   - 推送调度器是否运行

4. **检查浏览器**：
   - 是否支持Media Session API
   - 是否支持后台音频播放

### 调试工具
- 使用 `test_background_voice.html` 进行全面测试
- 查看浏览器开发者工具的Console日志
- 检查Service Worker的状态和日志

## 💡 技术创新点

1. **多策略音频播放** - 确保在各种环境下都能播放
2. **Media Session集成** - 让Web应用表现得像原生音频应用
3. **Service Worker音频** - 突破浏览器后台限制
4. **保活音频机制** - 维持音频播放权限
5. **智能降级策略** - 从最佳方案逐步降级到备选方案

这个解决方案应该能够彻底解决锁屏/后台语音播放的问题！