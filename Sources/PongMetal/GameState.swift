import Foundation

// MARK: - Constants

enum C {
    static let width:        Float = 800
    static let height:       Float = 600
    static let paddleW:      Float = 14
    static let paddleH:      Float = 84
    static let ballSz:       Float = 12
    static let margin:       Float = 32      // paddle x-distance from edge
    static let ballSpeed0:   Float = 5.5     // starting speed (px/frame)
    static let ballSpeedMax: Float = 11.0
    static let playerSpeed:  Float = 7.0
    static let aiSpeedMin:   Float = 5.4     // AI speed at lowest difficulty
    static let aiSpeedMax:   Float = 6.8     // AI speed at highest difficulty
    static let winScore:     Int   = 7
    static let pauseFrames:  Int   = 90      // 1.5 s at 60 fps before next serve
}

// MARK: - Phase

enum Phase { case waiting, playing, scored, over }

// MARK: - GameState

final class GameState {

    // Positions — paddle = centre-Y, ball = centre X/Y
    var playerY: Float = C.height / 2
    var aiY:     Float = C.height / 2
    var ballX:   Float = C.width  / 2
    var ballY:   Float = C.height / 2
    var ballVX:  Float = 0
    var ballVY:  Float = 0

    var playerScore = 0
    var aiScore     = 0

    private(set) var paletteIndex = 0
    static let paletteCount = 6

    var phase: Phase = .waiting
    private(set) var pauseTimer = 0          // readable by Renderer for ball blink
    private var lastAIScored   = false       // decides serve direction after a point

    // AI human-like behaviour
    private var aiTargetY:     Float = C.height / 2  // where AI is actually aiming
    private var aiReactionTimer: Int = 0             // frames until next target update
    private var aiError:       Float = 0             // current random aiming offset

    // Sound triggers — set for one frame, read + cleared by Renderer
    var soundWall    = false
    var soundPaddle  = false
    var soundScore   = false

    // Input — written by GameView on main thread, read on Metal thread (low-risk)
    var upPressed    = false
    var downPressed  = false

    // MARK: Window title (polled each frame by Renderer)

    var windowTitle: String {
        switch phase {
        case .waiting: return "PONG  ·  W/S or ↑↓ to move  ·  SPACE to start"
        case .over:
            return playerScore >= C.winScore
                ? "PONG  ·  YOU WIN \(playerScore)-\(aiScore)!  SPACE to restart"
                : "PONG  ·  AI WINS \(aiScore)-\(playerScore)!  SPACE to restart"
        default:      return "PONG  ·  first to \(C.winScore)"
        }
    }

    // MARK: Public interface

    func pressSpace() {
        switch phase {
        case .waiting:
            serve(towardPlayer: Bool.random())
            phase = .playing
        case .over:
            reset()
        default:
            break
        }
    }

    /// Called once per Metal draw tick (~60 fps).
    func update() {
        switch phase {
        case .waiting, .over:
            break
        case .playing:
            movePaddles()
            moveBall()
        case .scored:
            pauseTimer -= 1
            if pauseTimer <= 0 {
                if playerScore >= C.winScore || aiScore >= C.winScore {
                    phase = .over
                } else {
                    serve(towardPlayer: lastAIScored)
                    phase = .playing
                }
            }
        }
    }

    // MARK: Private

    private func reset() {
        playerScore = 0; aiScore = 0
        playerY = C.height / 2; aiY = C.height / 2
        ballX   = C.width  / 2; ballY = C.height / 2
        ballVX  = 0;             ballVY = 0
        aiTargetY = C.height / 2; aiReactionTimer = 0; aiError = 0
        paletteIndex = 0
        phase   = .waiting
    }

    private func serve(towardPlayer: Bool) {
        ballX = C.width  / 2
        ballY = C.height / 2
        let angle = Float.random(in: -25...25) * (.pi / 180)
        let dir: Float = towardPlayer ? -1 : 1
        ballVX = dir * C.ballSpeed0 * cos(angle)
        ballVY =       C.ballSpeed0 * sin(angle)
    }

    private func movePaddles() {
        let half = C.paddleH / 2
        if upPressed   { playerY -= C.playerSpeed }
        if downPressed { playerY += C.playerSpeed }
        playerY = playerY.clamped(to: half...(C.height - half))

        // AI human-like tracking: delayed reactions + imperfect aim, scaled by player score
        // difficulty curve: score 0→3, 1→4, 2→5, 3→5, 4→5, 5→6, 6→7  (out of 7)
        let curve: [Float] = [3/7, 4/7, 5/7, 5/7, 5/7, 6/7, 7/7]
        let idx = playerScore.clamped(to: 0...(curve.count - 1))
        let difficulty = curve[idx]
        // Reaction delay: 8 frames (easy) → 3 frames (hard)
        let reactionDelay = Int((1 - difficulty) * 5 + 3)
        // Aiming error magnitude: ±16 px (easy) → ±4 px (hard)
        let errorRange = (1 - difficulty) * 12 + 4

        aiReactionTimer -= 1
        if aiReactionTimer <= 0 {
            aiReactionTimer = reactionDelay + Int.random(in: 0...reactionDelay / 2)
            aiError  = Float.random(in: -errorRange...errorRange)
            aiTargetY = ballY + aiError
        }

        let aiSpeed = C.aiSpeedMin + difficulty * (C.aiSpeedMax - C.aiSpeedMin)
        let diff    = aiTargetY - aiY
        let delta   = min(abs(diff), aiSpeed) * (diff >= 0 ? 1 : -1)
        aiY = (aiY + delta).clamped(to: half...(C.height - half))
    }

    private func moveBall() {
        ballX += ballVX
        ballY += ballVY

        let hb = C.ballSz / 2

        // Top / bottom walls
        if ballY - hb <= 0 {
            ballY  = hb
            ballVY = abs(ballVY)
            soundWall = true
        } else if ballY + hb >= C.height {
            ballY  = C.height - hb
            ballVY = -abs(ballVY)
            soundWall = true
        }

        // Player paddle (left side)
        let pRight = C.margin + C.paddleW
        if ballVX < 0,
           ballX - hb <= pRight, ballX + hb >= C.margin,
           ballY + hb >= playerY - C.paddleH / 2,
           ballY - hb <= playerY + C.paddleH / 2 {
            ballX = pRight + hb
            applyBounce(centreY: playerY, goRight: true)
            soundPaddle = true
        }

        // AI paddle (right side)
        let aLeft = C.width - C.margin - C.paddleW
        if ballVX > 0,
           ballX + hb >= aLeft, ballX - hb <= C.width - C.margin,
           ballY + hb >= aiY - C.paddleH / 2,
           ballY - hb <= aiY + C.paddleH / 2 {
            ballX = aLeft - hb
            applyBounce(centreY: aiY, goRight: false)
            soundPaddle = true
        }

        // Out of bounds → score
        if ballX < -hb * 4 {
            aiScore += 1
            lastAIScored = true
            soundScore = true
            beginPause()
        } else if ballX > C.width + hb * 4 {
            playerScore += 1
            lastAIScored = false
            soundScore = true
            beginPause()
        }
    }

    /// Reflect ball off a paddle; angle depends on where along the paddle it hit.
    private func applyBounce(centreY: Float, goRight: Bool) {
        let hitNorm  = (ballY - centreY) / (C.paddleH / 2)          // −1 … 1
        let angle    = hitNorm.clamped(to: -0.85...0.85) * (62 * .pi / 180)
        let speed    = min(hypot(ballVX, ballVY) + 0.3, C.ballSpeedMax)
        ballVX = (goRight ? 1 : -1) * speed * cos(angle)
        ballVY = speed * sin(angle)
    }

    private func beginPause() {
        ballVX = 0; ballVY = 0
        ballX  = C.width  / 2
        ballY  = C.height / 2
        phase  = .scored
        pauseTimer = C.pauseFrames
        paletteIndex = (paletteIndex + 1) % GameState.paletteCount
    }
}

// MARK: - Utility

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        max(range.lowerBound, min(self, range.upperBound))
    }
}
