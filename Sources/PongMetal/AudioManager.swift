import AVFoundation

final class AudioManager {

    private var wallPlayer:   AVAudioPlayer?
    private var paddlePlayer: AVAudioPlayer?
    private var scorePlayer:  AVAudioPlayer?
    private let queue = DispatchQueue(label: "audio", qos: .userInteractive)

    init() {
        wallPlayer   = load("Wall")
        paddlePlayer = load("Paddle")
        scorePlayer  = load("Score")
        // Pre-warm on the audio queue so the engine is fully ready before play
        queue.async { [weak self] in
            guard let self else { return }
            [wallPlayer, paddlePlayer, scorePlayer].forEach { p in
                guard let p else { return }
                p.volume = 0
                p.play()
                p.stop()
                p.currentTime = 0
                p.volume = 1
            }
        }
    }

    func playWall()   { queue.async { [weak self] in self?.play(self?.wallPlayer)   } }
    func playPaddle() { queue.async { [weak self] in self?.play(self?.paddlePlayer) } }
    func playScore()  { queue.async { [weak self] in self?.play(self?.scorePlayer)  } }

    private func load(_ name: String) -> AVAudioPlayer? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "mov") else {
            print("AudioManager: missing \(name).mov")
            return nil
        }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        return player
    }

    private func play(_ player: AVAudioPlayer?) {
        guard let p = player else { return }
        p.currentTime = 0
        p.play()
    }
}
