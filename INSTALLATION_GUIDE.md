# 锁屏语音播放安装指南

## 1. 服务器端部署

### 安装TTS依赖

```bash
# 安装Python TTS库
pip install pyttsx3

# 安装espeak (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install espeak espeak-data

# 安装espeak (CentOS/RHEL)
sudo yum install espeak espeak-devel
```

### 部署Web文件

将 `deploy_web/` 目录中的所有文件上传到服务器的web根目录：

```bash
# 示例：使用scp上传
scp deploy_web/* user@server:/path/to/web/root/

# 或使用rsync
rsync -av deploy_web/ user@server:/path/to/web/root/
```

### 重启后端服务

```bash
# 重启Flask应用
sudo systemctl restart your-flask-app

# 或者如果使用PM2
pm2 restart app
```

## 2. 测试部署

### 运行测试脚本

```bash
python3 test_lockscreen_voice.py
```

### 访问测试页面

打开浏览器访问：
`https://service.muhuo.site/test_background_voice.html`

### 手机端测试

1. 在手机上打开应用
2. 设置一个1分钟后的提醒
3. 锁屏等待
4. 检查是否有语音播放或通知

## 3. 故障排除

### TTS API不工作

- 检查espeak是否安装：`espeak --version`
- 检查pyttsx3是否安装：`python3 -c "import pyttsx3"`
- 查看服务器日志中的TTS错误信息

### 锁屏语音不播放

- 确认通知权限已授予
- 检查浏览器是否支持Service Worker
- 尝试点击通知播放语音
- 查看浏览器控制台错误信息

### Service Worker问题

- 清除浏览器缓存
- 重新注册Service Worker
- 检查HTTPS证书是否有效

## 4. 浏览器兼容性

- **iOS Safari**: 锁屏语音受限，主要依靠通知
- **Android Chrome**: 后台语音有时间限制
- **桌面浏览器**: 相对宽松的限制

## 5. 预期效果

部署成功后应该实现：

- ✅ 前台状态正常语音播放
- ✅ 后台状态语音播放（部分浏览器）
- ✅ 锁屏状态通知+振动提醒
- ✅ 解锁后立即播放待播语音
- ✅ 通知点击触发语音播放
