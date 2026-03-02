import AVFoundation
class BackgroundService {
    static let shared = BackgroundService()
    func keepAlive() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}
