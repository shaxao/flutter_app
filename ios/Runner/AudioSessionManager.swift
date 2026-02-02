import Foundation
import AVFoundation
import MediaPlayer

/// iOS音频会话管理器 - 支持后台和锁屏音频播放
@objc class AudioSessionManager: NSObject {
    
    static let shared = AudioSessionManager()
    private var audioSession: AVAudioSession
    private var speechSynthesizer: AVSpeechSynthesizer?
    
    override init() {
        self.audioSession = AVAudioSession.sharedInstance()
        super.init()
        setupAudioSession()
    }
    
    /// 设置音频会话为后台播放模式
    private func setupAudioSession() {
        do {
            // 设置音频类别为播放模式，支持后台播放
            try audioSession.setCategory(AVAudioSession.Category.playback, 
                                       mode: .voicePrompt,
                                       options: [.allowBluetooth, 
                                               .allowBluetoothA2DP,
                                               .defaultToSpeaker,
                                               .mixWithOthers])
            
            // 激活音频会话
            try audioSession.setActive(true)
            
            print("✅ iOS音频会话已设置为后台播放模式")
            
            // 设置媒体播放信息（用于锁屏控制）
            setupNowPlayingInfo()
            
        } catch {
            print("❌ 设置iOS音频会话失败: \(error)")
        }
    }
    
    /// 激活音频会话
    @objc func activateAudioSession() -> Bool {
        do {
            try audioSession.setActive(true)
            print("✅ 音频会话已激活")
            return true
        } catch {
            print("❌ 激活音频会话失败: \(error)")
            return false
        }
    }
    
    /// 停用音频会话
    @objc func deactivateAudioSession() -> Bool {
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            print("✅ 音频会话已停用")
            return true
        } catch {
            print("❌ 停用音频会话失败: \(error)")
            return false
        }
    }
    
    /// 检查后台音频播放权限
    @objc func checkBackgroundAudioPermission() -> Bool {
        // 检查应用是否有后台音频播放权限
        let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]
        let hasAudioBackground = backgroundModes?.contains("audio") ?? false
        
        print("后台音频权限: \(hasAudioBackground)")
        return hasAudioBackground
    }
    
    /// 请求后台音频播放权限（实际上是检查配置）
    @objc func requestBackgroundAudioPermission() -> Bool {
        // iOS的后台音频权限是通过Info.plist配置的，不需要运行时请求
        // 这里主要是检查配置是否正确
        return checkBackgroundAudioPermission()
    }
    
    /// 在后台播放语音
    @objc func speakInBackground(_ text: String) {
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
        
        // 更新锁屏媒体信息
        updateNowPlayingInfo(title: "语音提醒", artist: "VoiceFlow", text: text)
        
        // 播放语音
        speechSynthesizer?.speak(utterance)
        
        print("✅ 后台语音播放已开始")
    }
    
    /// 停止语音播放
    @objc func stopSpeaking() {
        speechSynthesizer?.stopSpeaking(at: .immediate)
        print("✅ 语音播放已停止")
    }
    
    /// 暂停语音播放
    @objc func pauseSpeaking() {
        speechSynthesizer?.pauseSpeaking(at: .immediate)
        print("✅ 语音播放已暂停")
    }
    
    /// 继续语音播放
    @objc func continueSpeaking() {
        speechSynthesizer?.continueSpeaking()
        print("✅ 语音播放已继续")
    }
    
    /// 设置锁屏媒体播放信息
    private func setupNowPlayingInfo() {
        // 设置媒体播放控制中心信息
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "VoiceFlow 语音助手"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "语音提醒系统"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "智能提醒"
        
        // 设置播放时间信息
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 30 // 预估30秒
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        // 设置远程控制事件处理
        setupRemoteCommandCenter()
    }
    
    /// 更新锁屏媒体信息
    private func updateNowPlayingInfo(title: String, artist: String, text: String) {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = text
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = Double(text.count) * 0.5 // 估算播放时长
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    /// 设置远程控制中心（锁屏控制）
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 播放按钮
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.continueSpeaking()
            return .success
        }
        
        // 暂停按钮
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pauseSpeaking()
            return .success
        }
        
        // 停止按钮
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.stopSpeaking()
            return .success
        }
        
        print("✅ 远程控制中心已设置")
    }
    
    /// 处理音频会话中断
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("⚠️ 音频会话被中断")
            pauseSpeaking()
            
        case .ended:
            print("✅ 音频会话中断结束")
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    continueSpeaking()
                }
            }
            
        @unknown default:
            break
        }
    }
    
    /// 处理音频路由变化
    @objc private func handleAudioSessionRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .newDeviceAvailable:
            print("✅ 新音频设备可用")
            
        case .oldDeviceUnavailable:
            print("⚠️ 音频设备不可用")
            
        default:
            break
        }
    }
    
    deinit {
        // 移除通知监听
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - 通知监听设置
extension AudioSessionManager {
    func startObservingAudioSessionNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
}