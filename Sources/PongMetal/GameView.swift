import AppKit
import Metal
import MetalKit

// MTKView subclass — owns the GameState and handles keyboard input.
final class GameView: MTKView {

    let gameState = GameState()
    private(set) var renderer: Renderer!

    required init(coder: NSCoder) { fatalError("use init(frame:device:)") }

    init(frame: NSRect, device: MTLDevice) {
        super.init(frame: frame, device: device)

        colorPixelFormat         = .bgra8Unorm
        clearColor               = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        preferredFramesPerSecond = 60
        isPaused                 = false
        enableSetNeedsDisplay    = false   // continuous render loop
        layer?.isOpaque          = true

        do {
            renderer = try Renderer(device: device, pixelFormat: colorPixelFormat)
        } catch {
            fatalError("Renderer init failed: \(error)")
        }
        renderer.gameState = gameState
        renderer.onTitleChange = { [weak self] title in
            self?.window?.title = title
        }
        self.delegate = renderer
    }

    // ── Key handling ────────────────────────────────────────────────────────

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard !event.isARepeat else { return }
        switch event.keyCode {
        case 126, 13: gameState.upPressed   = true   // ↑  /  W
        case 125,  1: gameState.downPressed = true   // ↓  /  S
        case 49:      gameState.pressSpace()          // Space
        default:      super.keyDown(with: event)
        }
    }

    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 126, 13: gameState.upPressed   = false
        case 125,  1: gameState.downPressed = false
        default:      super.keyUp(with: event)
        }
    }
}
