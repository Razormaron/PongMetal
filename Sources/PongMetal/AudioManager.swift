import AVFoundation

final class AudioManager {

    private var wallPlayer:   AVAudioPlayer?
    private var paddlePlayer: AVAudioPlayer?
    private var scorePlayer:  AVAudioPlayer?

    init() {
        wallPlayer   = load("Wall")
        paddlePlayer = load("Paddle")
        scorePlayer  = load("Score")
        // Pre-warm the audio engine so the first real play has no lag
        [wallPlayer, paddlePlayer, scorePlayer].forEach { p in
            guard let p else { return }
            p.volume = 0
            p.play()
            p.stop()
            p.currentTime = 0
            p.volume = 1
        }
    }

    func playWall()   { play(wallPlayer) }
    func playPaddle() { play(paddlePlayer) }
    func playScore()  { play(scorePlayer) }

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
