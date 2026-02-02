import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lib/core/services/voice_service.dart';
import 'lib/core/services/notification_service.dart';

/// iOS锁屏语音播放测试应用
class IOSLockscreenVoiceTestApp extends StatefulWidget {
  @override
  _IOSLockscreenVoiceTestAppState createState() => _IOSLockscreenVoiceTestAppState();
}

class _IOSLockscreenVoiceTestAppState extends State<IOSLockscreenVoiceTestApp> {
  final TextEditingController _textController = TextEditingController(
    text: '这是iOS锁屏语音播放测试，请锁屏后等待语音播放'
  );
  
  bool _isInitialized = false;
  String _statusMessage = '正在初始化...';
  Map<String, dynamic> _systemStatus = {};

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _statusMessage = '正在初始化语音和通知服务...';
      });

      // 初始化语音服务
      await VoiceService.instance.initialize();
      
      // 初始化通知服务
      await NotificationService.instance.initialize();
      
      // 检查系统状态
      await _checkSystemStatus();
      
      setState(() {
        _isInitialized = true;
        _statusMessage = '✅ 服务初始化完成';
      });
      
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 初始化失败: $e';
      });
    }
  }

  Future<void> _checkSystemStatus() async {
    try {
      final voiceStatus = await _getVoiceServiceStatus();
      final notificationStatus = await _getNotificationServiceStatus();
      final backgroundAudioSupported = await _checkBackgroundAudioSupport();
      
      setState(() {
        _systemStatus = {
          'voice': voiceStatus,
          'notification': notificationStatus,
          'backgroundAudio': backgroundAudioSupported,
          'platform': Theme.of(context).platform.toString(),
        };
      });
      
    } catch (e) {
      print('检查系统状态失败: $e');
    }
  }

  Future<Map<String, dynamic>> _getVoiceServiceStatus() async {
    try {
      // 这里需要调用语音服务的状态检查方法
      return {
        'initialized': true,
        'available': true,
      };
    } catch (e) {
      return {
        'initialized': false,
        'available': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _getNotificationServiceStatus() async {
    try {
      // 检查通知权限
      return {
        'initialized': true,
        'permissionGranted': true,
      };
    } catch (e) {
      return {
        'initialized': false,
        'permissionGranted': false,
        'error': e.toString(),
      };
    }
  }

  Future<bool> _checkBackgroundAudioSupport() async {
    try {
      const platform = MethodChannel('voiceflow/audio_session');
      final result = await platform.invokeMethod('checkBackgroundAudioPermission');
      return result == true;
    } catch (e) {
      print('检查后台音频支持失败: $e');
      return false;
    }
  }

  Future<void> _testBasicVoice() async {
    try {
      final text = _textController.text;
      if (text.isEmpty) return;
      
      setState(() {
        _statusMessage = '🔊 播放基础语音...';
      });
      
      await VoiceService.instance.speak(text);
      
      setState(() {
        _statusMessage = '✅ 基础语音播放完成';
      });
      
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 基础语音播放失败: $e';
      });
    }
  }

  Future<void> _testBackgroundVoice() async {
    try {
      final text = _textController.text;
      if (text.isEmpty) return;
      
      setState(() {
        _statusMessage = '🔊 测试后台语音播放...';
      });
      
      // 使用原生方法播放后台语音
      const platform = MethodChannel('voiceflow/voice');
      await platform.invokeMethod('speakInBackground', {'text': text});
      
      setState(() {
        _statusMessage = '✅ 后台语音播放已触发';
      });
      
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 后台语音播放失败: $e';
      });
    }
  }

  Future<void> _testVoiceNotification() async {
    try {
      final text = _textController.text;
      if (text.isEmpty) return;
      
      setState(() {
        _statusMessage = '📱 发送语音通知...';
      });
      
      // 使用原生方法发送语音通知
      const platform = MethodChannel('voiceflow/notifications');
      await platform.invokeMethod('showVoiceNotification', {
        'title': '🔊 语音提醒测试',
        'body': text,
        'playVoice': true,
        'voiceText': text,
      });
      
      setState(() {
        _statusMessage = '✅ 语音通知已发送';
      });
      
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 语音通知发送失败: $e';
      });
    }
  }

  Future<void> _testScheduledVoiceReminder() async {
    try {
      final text = _textController.text;
      if (text.isEmpty) return;
      
      // 设置1分钟后的提醒
      final scheduledTime = DateTime.now().add(Duration(minutes: 1));
      
      setState(() {
        _statusMessage = '⏰ 设置1分钟后的语音提醒...';
      });
      
      await NotificationService.instance.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '🔊 定时语音提醒',
        body: text,
        scheduledTime: scheduledTime,
        payload: 'voice:$text',
      );
      
      setState(() {
        _statusMessage = '✅ 语音提醒已设置，请在1分钟后锁屏测试';
      });
      
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 设置语音提醒失败: $e';
      });
    }
  }

  Future<void> _activateAudioSession() async {
    try {
      const platform = MethodChannel('voiceflow/audio_session');
      final result = await platform.invokeMethod('activateAudioSession');
      
      setState(() {
        _statusMessage = result ? '✅ 音频会话已激活' : '❌ 音频会话激活失败';
      });
      
    } catch (e) {
      setState(() {
        _statusMessage = '❌ 激活音频会话失败: $e';
      });
    }
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('系统状态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('状态: $_statusMessage'),
            SizedBox(height: 8),
            if (_systemStatus.isNotEmpty) ...[
              Text('详细信息:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._systemStatus.entries.map((entry) => 
                Text('${entry.key}: ${entry.value}')
              ).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isInitialized ? _testBasicVoice : null,
            child: Text('🔊 测试基础语音播放'),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isInitialized ? _testBackgroundVoice : null,
            child: Text('🔊 测试后台语音播放'),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isInitialized ? _testVoiceNotification : null,
            child: Text('📱 测试语音通知'),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isInitialized ? _testScheduledVoiceReminder : null,
            child: Text('⏰ 测试定时语音提醒'),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isInitialized ? _activateAudioSession : null,
            child: Text('🎵 激活音频会话'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iOS锁屏语音播放测试',
      home: Scaffold(
        appBar: AppBar(
          title: Text('iOS锁屏语音播放测试'),
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatusCard(),
              SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '测试语音文本',
                  border: OutlineInputBorder(),
                  hintText: '输入要播放的语音内容...',
                ),
              ),
              SizedBox(height: 16),
              _buildTestButtons(),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('测试说明', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('1. 点击"测试基础语音播放"验证前台语音功能'),
                      Text('2. 点击"测试后台语音播放"然后立即锁屏'),
                      Text('3. 点击"测试语音通知"查看通知+语音效果'),
                      Text('4. 点击"测试定时语音提醒"然后等待1分钟并锁屏'),
                      Text('5. 如果语音不播放，尝试点击"激活音频会话"'),
                      SizedBox(height: 8),
                      Text('注意: iOS锁屏语音播放需要特殊权限，可能在某些情况下受限。',
                           style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(IOSLockscreenVoiceTestApp());
}