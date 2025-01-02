
import Foundation
import AVFAudio

class AudioPlayController: NSObject {
    
    public static let shared = AudioPlayController()
    public var didFinishPlaying: ((String) -> Void)? // 更新UI界面
    
    private var playingMessageID: String? // 正在播放的消息id
    private var messageID: String? // 点击的消息id
    private var audioPlayer: AVAudioPlayer?
    private var pauseMessageID: String?

    func isFocus(messageID: String) -> Bool {

        self.messageID == messageID
    }

    func focus(messageID: String) {
        self.messageID = messageID
    }
    
    func play(url: URL, messageID: String) {
        if messageID == pauseMessageID {
            audioPlayer?.play()
        } else {
            pauseMessageID = nil
            playingMessageID = messageID
            playSound(url: url)
        }
    }
    
    func isPlaying(messageID: String) -> Bool {
        playingMessageID == messageID
    }
    
    func isPausing(messageID: String) -> Bool {
        pauseMessageID == messageID
    }
    
    func pause(messageID: String) {
        pauseMessageID = messageID
        audioPlayer?.pause()
    }
    
    public func reset() {
        stop()
        playingMessageID = nil
        messageID = nil
        pauseMessageID = nil
    }
    
    private func playSound(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            
            if audioPlayer?.prepareToPlay() == true {
                audioPlayer?.play()
            }
        } catch (let e) {
            print("Failed to create audio player for URL: \(url)  --- \(e)")
        }
    }
    
    func stop() {
        noticeFinishStatus()
        audioPlayer?.stop()
    }
    
    private func noticeFinishStatus() {
        if let playingMessageID {
            didFinishPlaying?(playingMessageID)
        }
    }
}

extension AudioPlayController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        noticeFinishStatus()
        reset()
    }

    func audioPlayerDecodeErrorDidOccur(_: AVAudioPlayer, error error: Error?) {
        print("audioPlayerDecodeErrorDidOccur: \(error)")
    }
}
