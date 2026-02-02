import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/voice_service.dart';
import 'core/services/api_service.dart';
import 'core/services/network_service.dart';
import 'core/services/reminder_scheduler_service.dart';
import 'core/services/hybrid_notification_service.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/reminder/presentation/providers/voice_reminder_provider.dart';

// Conditional import for Web
import 'dart:html' as html show window, document;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // 后台任务：检查提醒并播报
    await VoiceService.checkAndPlayReminders();
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化时区数据
  try {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai')); // 设置为中国时区
    print('✅ 时区初始化成功');
  } catch (e) {
    print('❌ 时区初始化失败: $e');
  }
  
  try {
    // 初始化 Hive
    await Hive.initFlutter();
    print('✅ Hive 初始化成功');
  } catch (e) {
    print('❌ Hive 初始化失败: $e');
  }
  
  try {
    // 检查网络连接
    print('🌐 开始网络连接检查...');
    final hasNetwork = await NetworkService.instance.checkConnection();
    if (hasNetwork) {
      print('✅ 网络连接正常');
      
      // 检查服务器连接
      final hasServerConnection = await NetworkService.instance.checkServerConnection('https://service.muhuo.site');
      if (hasServerConnection) {
        print('✅ 服务器连接正常');
      } else {
        print('⚠️ 服务器连接异常');
      }
    } else {
      print('⚠️ 网络连接异常');
    }
  } catch (e) {
    print('❌ 网络检查失败: $e');
  }
  
  try {
    // 初始化 API 服务
    await ApiService.instance.initialize(baseUrl: 'https://service.muhuo.site');
    print('✅ API 服务初始化成功');
    
    // 测试 API 连接
    final isConnected = await ApiService.instance.healthCheck();
    if (isConnected) {
      print('✅ API 服务连接正常');
    } else {
      print('⚠️ API 服务连接异常，但应用将继续运行');
    }
  } catch (e) {
    print('❌ API 服务初始化失败: $e');
    print('⚠️ 应用将在离线模式下运行');
  }
  
  try {
    // 初始化混合通知服务（包含完整的 Web Push 系统）
    await HybridNotificationService.instance.initialize();
    print('✅ 混合通知服务初始化成功');
  } catch (e) {
    print('❌ 混合通知服务初始化失败: $e');
  }
  
  try {
    // 初始化通知服务
    await NotificationService.instance.initialize();
    print('✅ 通知服务初始化成功');
  } catch (e) {
    print('❌ 通知服务初始化失败: $e');
  }
  
  try {
    // 初始化语音服务
    await VoiceService.instance.initialize();
    print('✅ 语音服务初始化成功');
  } catch (e) {
    print('❌ 语音服务初始化失败: $e');
  }
  
  try {
    // 初始化提醒调度服务
    await ReminderSchedulerService.instance.initialize();
    print('✅ 提醒调度服务初始化成功');
  } catch (e) {
    print('❌ 提醒调度服务初始化失败: $e');
  }
  
  // 初始化后台任务 - 只在非 Web 环境
  if (!kIsWeb) {
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      
      // 注册周期性任务（每15分钟检查一次）
      await Workmanager().registerPeriodicTask(
        'voice-reminder-check',
        'voiceReminderCheck',
        frequency: const Duration(minutes: 15),
      );
      print('✅ 后台任务初始化成功');
    } catch (e) {
      print('❌ 后台任务初始化失败: $e');
    }
  }
  
  try {
    // 设置状态栏样式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    print('✅ 状态栏样式设置成功');
  } catch (e) {
    print('❌ 状态栏样式设置失败: $e');
  }
  
  print('🚀 应用启动中...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VoiceReminderProvider(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        title: 'VoiceFlow - 智能语音助手',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SafeHomePage(),
        builder: (context, child) {
          // 添加错误边界
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child ?? const SizedBox(),
          );
        },
      ),
    );
  }
}

class SafeHomePage extends StatefulWidget {
  const SafeHomePage({super.key});

  @override
  State<SafeHomePage> createState() => _SafeHomePageState();
}

class _SafeHomePageState extends State<SafeHomePage> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
    
    // Web 环境：处理 autoSpeak 参数
    if (kIsWeb) {
      _handleAutoSpeak();
    }
  }

  void _handleAutoSpeak() {
    try {
      final uri = Uri.parse(html.window.location.href);
      final autoSpeak = uri.queryParameters['autoSpeak'];
      
      if (autoSpeak != null && autoSpeak.isNotEmpty) {
        print('🔊 检测到 autoSpeak 参数: $autoSpeak');
        
        // 延迟播放，确保语音服务已初始化
        Future.delayed(const Duration(seconds: 2), () async {
          try {
            // 解锁语音服务
            HybridNotificationService.instance.unlockVoiceService();
            
            // 播放语音
            await HybridNotificationService.instance.speakReminder(autoSpeak);
            
            // 清除 URL 参数
            html.window.history.replaceState(null, '', '/');
          } catch (e) {
            print('❌ autoSpeak 播放失败: $e');
          }
        });
      }
    } catch (e) {
      print('❌ 处理 autoSpeak 参数失败: $e');
    }
  }

  Future<void> _initializeApp() async {
    try {
      // 延迟初始化 Provider
      final provider = Provider.of<VoiceReminderProvider>(context, listen: false);
      await provider.initialize();
      print('✅ VoiceReminderProvider 初始化成功');
      
      // Web 环境：设置用户交互监听器
      if (kIsWeb) {
        _setupWebInteractionListeners();
      }
    } catch (e) {
      print('❌ VoiceReminderProvider 初始化失败: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _setupWebInteractionListeners() {
    // 监听用户交互以解锁语音服务
    html.document.addEventListener('click', (event) {
      HybridNotificationService.instance.unlockVoiceService();
    });
    
    html.document.addEventListener('touchstart', (event) {
      HybridNotificationService.instance.unlockVoiceService();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  '应用初始化失败',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorMessage = '';
                    });
                    _initializeApp();
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const HomePage();
  }
}
