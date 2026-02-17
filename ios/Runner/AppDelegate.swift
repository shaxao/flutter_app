import Flutter
import UIKit
import AVFoundation

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

/// iOS原生音频生成管理器
/// 使用AVSpeechSynthesizer配合AVAudioRecorder生成音频文件
class AudioGenerationManager: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private var speechSynthesizer: AVSpeechSynthesizer?
    private var isRecording = false
    private var completion: ((Bool, String?) -> Void)?
    
    override init() {
        super.init()
        setupAudioSession()
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer?.delegate = self
    }
    
    /// 配置音频会话
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, 
                                       mode: .default, 
                                       options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("❌ 音频会话配置失败: \(error)")
        }
    }
    
    /// 生成音频文件
    func generateAudioFile(text: String, 
                          filePath: String, 
                          voice: String?, 
                          rate: Float, 
                          pitch: Float, 
                          volume: Float, 
                          language: String,
                          completion: @escaping (Bool, String?) -> Void) {
        
        self.completion = completion
        
        // 配置录音器
        guard setupRecorder(filePath: filePath) else {
            completion(false, "录音器配置失败")
            return
        }
        
        // 配置语音合成
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume
        
        // 设置语言
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        
        // 如果指定了特定音色，尝试使用
        if let voiceName = voice, !voiceName.isEmpty {
            let availableVoices = AVSpeechSynthesisVoice.speechVoices()
            if let selectedVoice = availableVoices.first(where: { $0.name.contains(voiceName) || $0.identifier.contains(voiceName) }) {
                utterance.voice = selectedVoice
            }
        }
        
        // 开始录音
        guard startRecording() else {
            completion(false, "开始录音失败")
            return
        }
        
        // 开始语音合成
        speechSynthesizer?.speak(utterance)
    }
    
    /// 配置录音器
    private func setupRecorder(filePath: String) -> Bool {
        let url = URL(fileURLWithPath: filePath)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            return true
        } catch {
            print("❌ 录音器配置失败: \(error)")
            return false
        }
    }
    
    /// 开始录音
    private func startRecording() -> Bool {
        guard let recorder = audioRecorder else { return false }
        
        isRecording = recorder.record()
        if isRecording {
            print("✅ 开始录音")
        } else {
            print("❌ 录音启动失败")
        }
        
        return isRecording
    }
    
    /// 停止录音
    private func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        isRecording = false
        print("✅ 录音已停止")
        
        // 检查文件是否生成成功
        if let url = audioRecorder?.url, FileManager.default.fileExists(atPath: url.path) {
            completion?(true, nil)
        } else {
            completion?(false, "音频文件生成失败")
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension AudioGenerationManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("🔊 语音合成开始")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("✅ 语音合成完成")
        
        // 延迟一点时间确保录音完整
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.stopRecording()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("⚠️ 语音合成被取消")
        stopRecording()
        completion?(false, "语音合成被取消")
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioGenerationManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("📁 录音完成，成功: \(flag)")
        
        if !flag {
            completion?(false, "录音未成功完成")
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("❌ 录音编码错误: \(error?.localizedDescription ?? "未知错误")")
        completion?(false, "录音编码错误: \(error?.localizedDescription ?? "未知错误")")
    }
}
