import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioGenerationManager: AudioGenerationManager?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // 设置音频生成Method Channel
    setupAudioGenerationChannel()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupAudioGenerationChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    audioGenerationManager = AudioGenerationManager()
    
    let audioGenerationChannel = FlutterMethodChannel(
      name: "audio_generation/ios",
      binaryMessenger: controller.binaryMessenger
    )
    
    audioGenerationChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "generateAudioFile":
        self?.handleGenerateAudioFile(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  private func handleGenerateAudioFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let text = args["text"] as? String,
          let filePath = args["filePath"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "缺少必要参数", details: nil))
      return
    }
    
    let voice = args["voice"] as? String
    let rate = args["rate"] as? Float ?? 0.5
    let pitch = args["pitch"] as? Float ?? 1.0
    let volume = args["volume"] as? Float ?? 1.0
    let language = args["language"] as? String ?? "zh-CN"
    
    audioGenerationManager?.generateAudioFile(
      text: text,
      filePath: filePath,
      voice: voice,
      rate: rate,
      pitch: pitch,
      volume: volume,
      language: language
    ) { success, error in
      DispatchQueue.main.async {
        if success {
          result(["success": true])
        } else {
          result(["success": false, "error": error ?? "未知错误"])
        }
      }
    }
  }
}
