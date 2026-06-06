import Metal
import MetalKit
import simd

// MARK: - Vertex

struct Vertex {
    var position: SIMD2<Float>
    var color:    SIMD4<Float>
}

// MARK: - Renderer

final class Renderer: NSObject, MTKViewDelegate {

    let device:       MTLDevice
    let commandQueue: MTLCommandQueue
    let pipeline:     MTLRenderPipelineState

    weak var gameState: GameState?

    /// Called on main thread whenever the window title should change.
    var onTitleChange: ((String) -> Void)?
    private var lastTitle = ""
    private let audio = AudioManager()

    // ── 7-segment digit patterns [A, B, C, D, E, F, G] ──────────────────────
    //
    //   AAA
    //  F   B
    //  F   B
    //   GGG
    //  E   C
    //  E   C
    //   DDD
    //
    private static let segPatterns: [[Bool]] = [
        [true,  true,  true,  true,  true,  true,  false], // 0
        [false, true,  true,  false, false, false, false],  // 1
        [true,  true,  false, true,  true,  false, true],   // 2
        [true,  true,  true,  true,  false, false, true],   // 3
        [false, true,  true,  false, false, true,  true],   // 4
        [true,  false, true,  true,  false, true,  true],   // 5
        [true,  false, true,  true,  true,  true,  true],   // 6
        [true,  true,  true,  false, false, false, false],  // 7
        [true,  true,  true,  true,  true,  true,  true],   // 8
        [true,  true,  true,  true,  false, true,  true],   // 9
    ]

    private let digitW:   Float = 30
    private let digitH:   Float = 48
    private let digitGap: Float = 6

    // Reusable vertex buffer — large enough for all geometry (~512 verts max)
    private let vertexBuffer: MTLBuffer

    // MARK: Init

    init(device: MTLDevice, pixelFormat: MTLPixelFormat) throws {
        self.device       = device
        self.commandQueue = device.makeCommandQueue()!

        // Compile shaders from the embedded source string
        let library = try device.makeLibrary(source: metalShaderSource, options: nil)
        let vertFn  = library.makeFunction(name: "vertex_main")!
        let fragFn  = library.makeFunction(name: "fragment_main")!

        // Vertex descriptor — position (float2) then color (float4)
        let vd = MTLVertexDescriptor()
        vd.attributes[0].format      = .float2
        vd.attributes[0].offset      = 0
        vd.attributes[0].bufferIndex = 0
        vd.attributes[1].format      = .float4
        vd.attributes[1].offset      = MemoryLayout<Vertex>.offset(of: \.color)!
        vd.attributes[1].bufferIndex = 0
        vd.layouts[0].stride         = MemoryLayout<Vertex>.stride

        let pd = MTLRenderPipelineDescriptor()
        pd.vertexFunction                  = vertFn
        pd.fragmentFunction                = fragFn
        pd.colorAttachments[0].pixelFormat = pixelFormat
        pd.vertexDescriptor                = vd

        self.pipeline = try device.makeRenderPipelineState(descriptor: pd)
        self.vertexBuffer = device.makeBuffer(length: 512 * MemoryLayout<Vertex>.stride,
                                              options: .storageModeShared)!
        super.init()
    }

    // MARK: MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let gs = gameState else { return }

        // Tick game logic
        gs.update()

        // Fire sounds for events raised this frame
        if gs.soundWall   { audio.playWall();   gs.soundWall   = false }
        if gs.soundPaddle { audio.playPaddle(); gs.soundPaddle = false }
        if gs.soundScore  { audio.playScore();  gs.soundScore  = false }

        // Sync window title (only when it changes)
        let title = gs.windowTitle
        if title != lastTitle {
            lastTitle = title
            let cb = onTitleChange
            DispatchQueue.main.async { cb?(title) }
        }

        // Build geometry directly into the reusable buffer
        var verts = UnsafeMutableBufferPointer<Vertex>(
            start: vertexBuffer.contents().assumingMemoryBound(to: Vertex.self),
            count: 512)
        var vertCount = 0
        buildGeometry(gs, into: &verts, count: &vertCount)

        guard vertCount > 0,
              let rpd    = view.currentRenderPassDescriptor,
              let cmdBuf = commandQueue.makeCommandBuffer(),
              let enc    = cmdBuf.makeRenderCommandEncoder(descriptor: rpd)
        else { return }

        enc.setRenderPipelineState(pipeline)
        enc.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertCount)
        enc.endEncoding()

        if let drawable = view.currentDrawable { cmdBuf.present(drawable) }
        cmdBuf.commit()
    }

    // MARK: Geometry

    private static let palette: [SIMD4<Float>] = [
        SIMD4<Float>(0.35, 0.75, 1.00, 1),  // blue
        SIMD4<Float>(1.00, 0.30, 0.30, 1),  // red
        SIMD4<Float>(1.00, 0.90, 0.20, 1),  // yellow
        SIMD4<Float>(0.30, 1.00, 0.45, 1),  // green
        SIMD4<Float>(1.00, 0.55, 0.10, 1),  // orange
        SIMD4<Float>(0.85, 0.35, 1.00, 1),  // purple
    ]

    private func buildGeometry(_ gs: GameState,
                               into v: inout UnsafeMutableBufferPointer<Vertex>,
                               count: inout Int) {
        let col = Renderer.palette[gs.paletteIndex]
        let dim = SIMD4<Float>(col.x * 0.35, col.y * 0.35, col.z * 0.35, 1)

        // Centre dashed line
        let dashH: Float = 18
        let gapH:  Float = 14
        var dy: Float = 0
        while dy < C.height {
            addRect(&v, &count, x: C.width / 2 - 2, y: dy, w: 4, h: min(dashH, C.height - dy), c: dim)
            dy += dashH + gapH
        }

        // Player paddle (left)
        addRect(&v, &count, x: C.margin,
                y: gs.playerY - C.paddleH / 2,
                w: C.paddleW, h: C.paddleH, c: col)

        // AI paddle (right)
        addRect(&v, &count, x: C.width - C.margin - C.paddleW,
                y: gs.aiY - C.paddleH / 2,
                w: C.paddleW, h: C.paddleH, c: col)

        // Ball — blinks during the scored pause
        let showBall: Bool
        if case .scored = gs.phase {
            showBall = (gs.pauseTimer / 6) % 2 == 0
        } else {
            showBall = true
        }
        if showBall {
            let hb = C.ballSz / 2
            addRect(&v, &count, x: gs.ballX - hb, y: gs.ballY - hb,
                    w: C.ballSz, h: C.ballSz, c: col)
        }

        // Scores
        addScore(&v, &count, score: gs.playerScore, centreX: C.width * 0.25, topY: 20, c: col)
        addScore(&v, &count, score: gs.aiScore,     centreX: C.width * 0.75, topY: 20, c: col)
    }

    // MARK: Score / digit helpers

    private func addScore(_ v: inout UnsafeMutableBufferPointer<Vertex>, _ n: inout Int,
                          score: Int, centreX: Float, topY: Float, c: SIMD4<Float>) {
        if score >= 10 {
            let totalW = digitW * 2 + digitGap
            addDigit(&v, &n, d: score / 10, x: centreX - totalW / 2,                     y: topY, c: c)
            addDigit(&v, &n, d: score % 10, x: centreX - totalW / 2 + digitW + digitGap,  y: topY, c: c)
        } else {
            addDigit(&v, &n, d: score, x: centreX - digitW / 2, y: topY, c: c)
        }
    }

    private func addDigit(_ v: inout UnsafeMutableBufferPointer<Vertex>, _ n: inout Int,
                          d: Int, x: Float, y: Float, c: SIMD4<Float>) {
        guard d >= 0, d < Renderer.segPatterns.count else { return }
        let seg = Renderer.segPatterns[d]
        let w = digitW, h = digitH
        let sw: Float = 6
        let mid = (h / 2).rounded()

        if seg[0] { addRect(&v, &n, x: x,          y: y,              w: w,  h: sw,       c: c) } // A top
        if seg[1] { addRect(&v, &n, x: x + w - sw, y: y,              w: sw, h: mid,      c: c) } // B top-right
        if seg[2] { addRect(&v, &n, x: x + w - sw, y: y + mid,        w: sw, h: h - mid,  c: c) } // C bot-right
        if seg[3] { addRect(&v, &n, x: x,          y: y + h - sw,     w: w,  h: sw,       c: c) } // D bottom
        if seg[4] { addRect(&v, &n, x: x,          y: y + mid,        w: sw, h: h - mid,  c: c) } // E bot-left
        if seg[5] { addRect(&v, &n, x: x,          y: y,              w: sw, h: mid,      c: c) } // F top-left
        if seg[6] { addRect(&v, &n, x: x,          y: y + mid - sw/2, w: w,  h: sw,       c: c) } // G middle
    }

    // MARK: Primitive helper

    private func addRect(_ v: inout UnsafeMutableBufferPointer<Vertex>, _ n: inout Int,
                         x: Float, y: Float, w: Float, h: Float, c: SIMD4<Float>) {
        let (x0, y0) = ndc(x.rounded(),       y.rounded()      )
        let (x1, y1) = ndc((x+w).rounded(),   (y+h).rounded()  )
        v[n] = Vertex(position: [x0, y0], color: c); n += 1  // TL
        v[n] = Vertex(position: [x1, y0], color: c); n += 1  // TR
        v[n] = Vertex(position: [x0, y1], color: c); n += 1  // BL
        v[n] = Vertex(position: [x1, y0], color: c); n += 1  // TR
        v[n] = Vertex(position: [x1, y1], color: c); n += 1  // BR
        v[n] = Vertex(position: [x0, y1], color: c); n += 1  // BL
    }

    /// Game coordinates (origin top-left, y down) → Metal NDC (origin centre, y up).
    @inline(__always)
    private func ndc(_ gx: Float, _ gy: Float) -> (Float, Float) {
        ( (gx / C.width)  * 2 - 1,
          1 - (gy / C.height) * 2 )
    }
}
