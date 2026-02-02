# 真机测试指南 - VoiceFlow 智能语音助手

## 概述
本指南提供了在真实设备上测试 VoiceFlow 应用的完整方法，包括Web版本和iOS原生应用的测试步骤。

---

## 🌐 Web版本真机测试

### 方法1: 本地网络测试（推荐）

#### 步骤1: 启动本地服务器
```powershell
# 在 flutter_app/build/web 目录下
cd flutter_app/build/web
python -m http.server 8080
```

#### 步骤2: 获取本机IP地址
```powershell
# Windows
ipconfig | findstr "IPv4"

# 示例输出: IPv4 地址 . . . . . . . . . . . . : 192.168.1.100
```

#### 步骤3: 手机访问
1. 确保手机和电脑在同一WiFi网络
2. 在手机浏览器中访问: `http://192.168.1.100:8080`
3. 如果需要测试HTTPS功能，使用ngrok等工具

### 方法2: 部署到服务器测试

#### 使用现有服务器
```bash
# 将 build/web 目录内容上传到服务器
# 访问: https://service.muhuo.site/voiceflow/
```

#### 使用GitHub Pages
1. 将 `build/web` 内容推送到GitHub仓库的 `gh-pages` 分支
2. 启用GitHub Pages
3. 访问生成的URL

### 方法3: 使用ngrok（HTTPS测试）

#### 安装和使用ngrok
```powershell
# 1. 下载ngrok: https://ngrok.com/
# 2. 启动本地服务器
python -m http.server 8080

# 3. 新开终端，启动ngrok
ngrok http 8080

# 4. 使用生成的HTTPS URL在手机上测试
```

---

## 📱 iOS原生应用真机测试

### 前置条件
- macOS系统
- Xcode 14+
- iOS开发者账号（免费或付费）
- iPhone/iPad设备

### 方法1: Xcode直接安装（需要Mac）

#### 步骤1: 准备Xcode项目
```bash
cd flutter_app
flutter build ios --debug
```

#### 步骤2: 在Xcode中打开项目
```bash
open ios/Runner.xcworkspace
```

#### 步骤3: 配置签名
1. 选择 Runner 项目
2. 在 "Signing & Capabilities" 中选择你的开发团队
3. 修改 Bundle Identifier（如: com.yourname.voiceflow）

#### 步骤4: 连接设备并运行
1. 用USB连接iPhone到Mac
2. 在Xcode中选择你的设备
3. 点击运行按钮

### 方法2: 使用Sideloadly（Windows/Mac）

#### 步骤1: 构建IPA文件
```bash
cd flutter_app
flutter build ipa --export-method development
```

#### 步骤2: 使用Sideloadly安装
1. 下载Sideloadly: https://sideloadly.io/
2. 连接iPhone到电脑
3. 在Sideloadly中选择生成的IPA文件
4. 输入Apple ID和密码
5. 点击安装

#### 步骤3: 信任开发者
1. 在iPhone上: 设置 > 通用 > VPN与设备管理
2. 找到你的Apple ID，点击信任

### 方法3: TestFlight分发（推荐生产测试）

#### 步骤1: 构建发布版本
```bash
flutter build ipa --release
```

#### 步骤2: 上传到App Store Connect
1. 使用Xcode或Transporter上传IPA
2. 在App Store Connect中创建TestFlight版本
3. 添加测试用户
4. 发送测试邀请

---

## 🧪 功能测试清单

### Web版本测试项目

#### 基础功能测试
- [ ] 页面加载正常
- [ ] 导航栏功能正常
- [ ] 响应式布局适配
- [ ] 触摸操作流畅

#### 通知功能测试
- [ ] 浏览器通知权限请求
- [ ] 原生通知显示
- [ ] 备用视觉通知显示
- [ ] 通知点击响应

#### 语音功能测试
- [ ] 语音合成权限
- [ ] 中文语音播放
- [ ] 语音播放状态反馈
- [ ] 备用文本提示

#### 提醒功能测试
- [ ] 添加语音提醒
- [ ] 批量导入提醒
- [ ] 定时提醒触发
- [ ] 提醒类型切换

### iOS原生应用测试项目

#### 系统集成测试
- [ ] 后台运行
- [ ] 锁屏通知
- [ ] 系统通知中心
- [ ] 语音播放（锁屏状态）

#### 权限测试
- [ ] 通知权限请求
- [ ] 麦克风权限（如需要）
- [ ] 后台刷新权限

#### 性能测试
- [ ] 内存使用情况
- [ ] 电池消耗
- [ ] 网络请求
- [ ] 数据存储

---

## 🔧 调试工具和技巧

### Web版本调试

#### 浏览器开发者工具
```javascript
// 在浏览器控制台中测试通知
if ('Notification' in window) {
  Notification.requestPermission().then(permission => {
    if (permission === 'granted') {
      new Notification('测试通知', {
        body: '这是一个测试通知',
        icon: '/favicon.png'
      });
    }
  });
}

// 测试语音合成
if ('speechSynthesis' in window) {
  const utterance = new SpeechSynthesisUtterance('你好，这是语音测试');
  utterance.lang = 'zh-CN';
  speechSynthesis.speak(utterance);
}
```

#### 移动端调试
1. **Chrome DevTools**: 连接Android设备进行远程调试
2. **Safari Web Inspector**: 连接iOS设备进行调试
3. **Weinre**: 跨平台远程调试工具

### iOS原生应用调试

#### Xcode调试
1. 连接设备到Xcode
2. 查看控制台日志
3. 使用断点调试
4. 监控内存和性能

#### 设备日志
```bash
# 查看设备日志
xcrun simctl spawn booted log stream --predicate 'process == "Runner"'
```

---

## 📊 测试报告模板

### 测试环境信息
```
测试日期: ____
测试人员: ____
设备信息: ____
系统版本: ____
浏览器版本: ____（Web测试）
网络环境: ____
```

### 功能测试结果
```
✅ 通过  ❌ 失败  ⚠️ 部分通过

基础功能:
[ ] 应用启动
[ ] 页面导航
[ ] 数据加载

通知功能:
[ ] 权限请求
[ ] 通知显示
[ ] 通知交互

语音功能:
[ ] 语音播放
[ ] 中文支持
[ ] 错误处理

提醒功能:
[ ] 添加提醒
[ ] 定时触发
[ ] 批量操作
```

### 问题记录
```
问题1: ____
重现步骤: ____
预期结果: ____
实际结果: ____
严重程度: 高/中/低

问题2: ____
...
```

---

## 🚀 快速测试脚本

### Web版本快速测试
```html
<!-- 保存为 quick_test.html -->
<!DOCTYPE html>
<html>
<head>
    <title>VoiceFlow 快速测试</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <h1>VoiceFlow 快速功能测试</h1>
    
    <button onclick="testNotification()">测试通知</button>
    <button onclick="testVoice()">测试语音</button>
    <button onclick="testBoth()">综合测试</button>
    
    <div id="result"></div>
    
    <script>
        function testNotification() {
            if ('Notification' in window) {
                Notification.requestPermission().then(permission => {
                    if (permission === 'granted') {
                        new Notification('✅ 通知测试', {
                            body: '通知功能正常工作！'
                        });
                        document.getElementById('result').innerHTML = '✅ 通知测试通过';
                    } else {
                        document.getElementById('result').innerHTML = '❌ 通知权限被拒绝';
                    }
                });
            } else {
                document.getElementById('result').innerHTML = '❌ 浏览器不支持通知';
            }
        }
        
        function testVoice() {
            if ('speechSynthesis' in window) {
                const utterance = new SpeechSynthesisUtterance('语音测试成功');
                utterance.lang = 'zh-CN';
                speechSynthesis.speak(utterance);
                document.getElementById('result').innerHTML = '✅ 语音测试启动';
            } else {
                document.getElementById('result').innerHTML = '❌ 浏览器不支持语音合成';
            }
        }
        
        function testBoth() {
            testNotification();
            setTimeout(testVoice, 1000);
        }
    </script>
</body>
</html>
```

---

## 📞 技术支持

### 常见问题解决

#### Web版本问题
1. **通知不显示**: 检查浏览器权限设置
2. **语音不播放**: 确保页面有用户交互
3. **HTTPS要求**: 某些功能需要HTTPS环境

#### iOS应用问题
1. **安装失败**: 检查证书和Bundle ID
2. **通知不工作**: 检查通知权限
3. **后台不运行**: 检查后台刷新设置

### 联系方式
- 技术文档: 查看项目README
- 问题反馈: 创建GitHub Issue
- 紧急支持: 联系开发团队

---

**最后更新**: 2026-02-02  
**版本**: v1.0  
**适用平台**: Web, iOS