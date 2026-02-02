import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/voice_service.dart';
import 'core/services/api_service.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/reminder/presentation/providers/voice_reminder_provider.dart';

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
  
  try {
    // 初始化 Hive
    await Hive.initFlutter();
    print('✅ Hive 初始化成功');
  } catch (e) {
    print('❌ Hive 初始化失败: $e');
  }
  
  try {
    // 初始化 API 服务
    await ApiService.instance.initialize(baseUrl: 'https://service.muhuo.site');
    print('✅ API 服务初始化成功');
  } catch (e) {
    print('❌ API 服务初始化失败: $e');
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
  }

  Future<void> _initializeApp() async {
    try {
      // 延迟初始化 Provider
      final provider = Provider.of<VoiceReminderProvider>(context, listen: false);
      await provider.initialize();
      print('✅ VoiceReminderProvider 初始化成功');
    } catch (e) {
      print('❌ VoiceReminderProvider 初始化失败: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
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
