import Flutter
import UIKit
import UserNotifications
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // 设置通知代理
        UNUserNotificationCenter.current().delegate = self
        
        // 注册Flutter方法通道
        setupMethodChannels()
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    /// 设置Flutter方法通道
    private func setupMethodChannels() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }
        
        // 音频会话管理通道
        let audioSessionChannel = FlutterMethodChannel(
            name: "voiceflow/audio_session",
            binaryMessenger: controller.binaryMessenger
        )
        
        audioSessionChannel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleAudioSessionMethodCall(call, result: result)
        }
        
        // 语音播放通道
        let voiceChannel = FlutterMethodChannel(
            name: "voiceflow/voice",
            binaryMessenger: controller.binaryMessenger
        )
        
        voiceChannel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleVoiceMethodCall(call, result: result)
        }
        
        // 通知管理通道
        let notificationChannel = FlutterMethodChannel(
            name: "voiceflow/notifications",
            binaryMessenger: controller.binaryMessenger
        )
        
        notificationChannel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleNotificationMethodCall(call, result: result)
        }
    }
    
    /// 处理音频会话方法调用
    private func handleAudioSessionMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setupBackgroundAudio":
            setupBackgroundAudio()
            result(true)
            
        case "activateAudioSession":
            let success = activateAudioSession()
            result(success)
            
        case "deactivateAudioSession":
            let success = deactivateAudioSession()
            result(success)
            
        case "checkBackgroundAudioPermission":
            let hasPermission = checkBackgroundAudioPermission()
            result(hasPermission)
            
        case "requestBackgroundAudioPermission":
            let granted = requestBackgroundAudioPermission()
            result(granted)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// 处理语音播放方法调用
    private func handleVoiceMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "speakInBackground":
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing text parameter", details: nil))
                return
            }
            
            speakInBackground(text)
            result(true)
            
        case "stopSpeaking":
            stopSpeaking()
            result(true)
            
        case "pauseSpeaking":
            pauseSpeaking()
            result(true)
            
        case "continueSpeaking":
            continueSpeaking()
            result(true)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// 处理通知方法调用
    private func handleNotificationMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "showVoiceNotification":
            guard let args = call.arguments as? [String: Any],
                  let title = args["title"] as? String,
                  let body = args["body"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing notification parameters", details: nil))
                return
            }
            
            let playVoice = args["playVoice"] as? Bool ?? false
            let voiceText = args["voiceText"] as? String
            
            showVoiceNotification(title: title, body: body, playVoice: playVoice, voiceText: voiceText)
            result(true)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - 音频会话管理
    
    private func setupBackgroundAudio() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSession.Category.playback,
                                       mode: .voicePrompt,
                                       options: [.allowBluetooth,
                                               .allowBluetoothA2DP,
                                               .defaultToSpeaker,
                                               .mixWithOthers])
            try audioSession.setActive(true)
            print("✅ iOS音频会话已设置为后台播放模式")
        } catch {
            print("❌ 设置iOS音频会话失败: \(error)")
        }
    }
    
    private func activateAudioSession() -> Bool {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ 音频会话已激活")
            return true
        } catch {
            print("❌ 激活音频会话失败: \(error)")
            return false
        }
    }
    
    private func deactivateAudioSession() -> Bool {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("✅ 音频会话已停用")
            return true
        } catch {
            print("❌ 停用音频会话失败: \(error)")
            return false
        }
    }
    
    private func checkBackgroundAudioPermission() -> Bool {
        let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]
        let hasAudioBackground = backgroundModes?.contains("audio") ?? false
        print("后台音频权限: \(hasAudioBackground)")
        return hasAudioBackground
    }
    
    private func requestBackgroundAudioPermission() -> Bool {
        return checkBackgroundAudioPermission()
    }
    
    // MARK: - 语音播放
    
    private var speechSynthesizer: AVSpeechSynthesizer?
    
    private func speakInBackground(_ text: String) {
        print("🔊 开始后台语音播放: \(text)")
        
        // 确保音频会话处于活跃状态
        _ = activateAudioSession()
        
        // 初始化语音合成器（如果还没有）
        if speechSynthesizer == nil {
            speechSynthesizer = AVSpeechSynthesizer()
        }
        
        // 创建语音合成请求
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = 0.5
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0
        
        // 播放语音
        speechSynthesizer?.speak(utterance)
        
        print("✅ 后台语音播放已开始")
    }
    
    private func stopSpeaking() {
        speechSynthesizer?.stopSpeaking(at: .immediate)
        print("✅ 语音播放已停止")
    }
    
    private func pauseSpeaking() {
        speechSynthesizer?.pauseSpeaking(at: .immediate)
        print("✅ 语音播放已暂停")
    }
    
    private func continueSpeaking() {
        speechSynthesizer?.continueSpeaking()
        print("✅ 语音播放已继续")
    }
    
    /// 显示带语音播放功能的通知
    private func showVoiceNotification(title: String, body: String, playVoice: Bool, voiceText: String?) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "VOICE_REMINDER"
        
        // 如果需要播放语音，先播放语音
        if playVoice, let text = voiceText, !text.isEmpty {
            speakInBackground(text)
        }
        
        // 创建通知请求
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 立即显示
        )
        
        // 添加通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 显示通知失败: \(error)")
            } else {
                print("✅ 语音通知已显示")
            }
        }
    }
    
    // MARK: - 应用生命周期
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        print("📱 应用进入后台")
        
        // 确保音频会话保持活跃（用于后台语音播放）
        _ = activateAudioSession()
    }
    
    override func applicationWillEnterForeground(_ application: UIApplication) {
        super.applicationWillEnterForeground(application)
        print("📱 应用即将进入前台")
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        print("📱 应用已激活")
    }
    
    override func applicationWillResignActive(_ application: UIApplication) {
        super.applicationWillResignActive(application)
        print("📱 应用即将失去焦点")
    }
}

// MARK: - 通知代理
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    /// 应用在前台时收到通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📱 前台收到通知: \(notification.request.content.title)")
        
        // 在前台也显示通知
        completionHandler([.alert, .sound, .badge])
    }
    
    /// 用户点击通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📱 用户点击通知: \(response.notification.request.content.title)")
        
        let notification = response.notification
        let content = notification.request.content
        
        // 如果是语音提醒通知，播放语音
        if content.categoryIdentifier == "VOICE_REMINDER" {
            let voiceText = content.body
            if !voiceText.isEmpty {
                speakInBackground(voiceText)
            }
        }
        
        completionHandler()
    }
}
