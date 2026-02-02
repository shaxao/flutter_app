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
  
  // 初始化 Hive
  await Hive.initFlutter();
  
  // 初始化 API 服务
  await ApiService.instance.initialize(baseUrl: 'https://service.muhuo.site');
  
  // 初始化通知服务
  await NotificationService.instance.initialize();
  
  // 初始化语音服务
  await VoiceService.instance.initialize();
  
  // 初始化后台任务 - 只在非 Web 环境
  if (!kIsWeb) {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    
    // 注册周期性任务（每15分钟检查一次）
    await Workmanager().registerPeriodicTask(
      'voice-reminder-check',
      'voiceReminderCheck',
      frequency: const Duration(minutes: 15),
    );
  }
  
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VoiceReminderProvider()),
      ],
      child: MaterialApp(
        title: 'VoiceFlow - 智能语音助手',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomePage(),
      ),
    );
  }
}
