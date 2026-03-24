import AppKit
import QuartzCore

class OverlayWindowController: NSWindowController {
    private var overlayWindows: [NSWindow] = []
    private let intensity: SlapIntensity

    init(intensity: SlapIntensity) {
        self.intensity = intensity
        super.init(window: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func showWindow(_ sender: Any?) {
        SoundEngine.shared.playReaction(for: intensity)
        for screen in NSScreen.screens {
            let window = makeOverlayWindow(for: screen)
            overlayWindows.append(window)
            window.makeKeyAndOrderFront(nil)
        }
        let timeout: Double
        switch intensity {
        case .light:     timeout = 3.0
        case .medium:    timeout = 5.0
        case .hard:      timeout = 7.0
        case .legendary: timeout = 10.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            self?.dismiss()
        }
    }

    func dismiss() {
        for w in overlayWindows {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.5
                w.animator().alphaValue = 0
            }, completionHandler: { w.close() })
        }
        overlayWindows.removeAll()
    }

    override func close() { dismiss() }

    private func makeOverlayWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.alphaValue = 0

        let view = CrackOverlayView(frame: screen.frame, intensity: intensity)
        window.contentView = view

        let click = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        view.addGestureRecognizer(click)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.08
            window.animator().alphaValue = 1
        }
        view.animateCracks()
        return window
    }

    @objc private func handleClick() { dismiss() }
}

class CrackOverlayView: NSView {
    private let impactPoints: [CGPoint]
    private let seed: UInt64
    private let intensity: SlapIntensity

    init(frame: NSRect, intensity: SlapIntensity) {
        self.intensity = intensity
        let count: Int
        switch intensity {
        case .light:     count = 1
        case .medium:    count = Int.random(in: 1...2)
        case .hard:      count = Int.random(in: 2...3)
        case .legendary: count = Int.random(in: 3...5)
        }
        var pts: [CGPoint] = []
        for _ in 0..<count {
            pts.append(CGPoint(
                x: CGFloat.random(in: frame.width * 0.15 ... frame.width * 0.85),
                y: CGFloat.random(in: frame.height * 0.15 ... frame.height * 0.85)
            ))
        }
        impactPoints = pts
        seed = UInt64.random(in: 1...UInt64.max)
        super.init(frame: frame)
        wantsLayer = true
        setupReactionLabel(in: frame)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupReactionLabel(in frame: NSRect) {
        let emoji: String
        let text: String
        switch intensity {
        case .light:     emoji = "😮"; text = "OW!"
        case .medium:    emoji = "😱"; text = "WHAT THE—"
        case .hard:      emoji = "🤯"; text = "MY SCREEN!!"
        case .legendary: emoji = "💀"; text = "YOU MONSTER"
        }

        let emojiLabel = NSTextField(labelWithString: emoji)
        emojiLabel.font = .systemFont(ofSize: 80)
        emojiLabel.frame = NSRect(x: 40, y: frame.height - 140, width: 120, height: 120)
        emojiLabel.drawsBackground = false
        addSubview(emojiLabel)

        let textLabel = NSTextField(labelWithString: text)
        textLabel.font = NSFont(name: "Impact", size: 52) ?? .boldSystemFont(ofSize: 52)
        textLabel.textColor = NSColor(red: 1, green: 0.2, blue: 0.1, alpha: 1)
        textLabel.frame = NSRect(x: 40, y: frame.height - 210, width: 500, height: 70)
        textLabel.drawsBackground = false
        let shadow = NSShadow()
        shadow.shadowColor = .black
        shadow.shadowOffset = NSSize(width: 3, height: -3)
        shadow.shadowBlurRadius = 4
        textLabel.shadow = shadow
        addSubview(textLabel)

        let hint = NSTextField(labelWithString: "click anywhere to dismiss  •  \(intensity.reactionEmoji)")
        hint.font = .systemFont(ofSize: 13)
        hint.textColor = NSColor.white.withAlphaComponent(0.5)
        hint.frame = NSRect(x: frame.width/2 - 150, y: 20, width: 300, height: 20)
        hint.alignment = .center
        hint.drawsBackground = false
        addSubview(hint)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        var rng = SeededRandom(seed: seed)
        let bounds = self.bounds

        let overlayAlpha: CGFloat
        switch intensity {
        case .light:     overlayAlpha = 0.35
        case .medium:    overlayAlpha = 0.5
        case .hard:      overlayAlpha = 0.65
        case .legendary: overlayAlpha = 0.78
        }
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: overlayAlpha))
        ctx.fill(bounds)

        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [CGColor(red:0,green:0,blue:0,alpha:0), CGColor(red:0,green:0,blue:0,alpha:0.7)] as CFArray,
            locations: [0.25, 1.0]
        )!
        ctx.drawRadialGradient(gradient,
            startCenter: CGPoint(x: bounds.midX, y: bounds.midY), startRadius: 0,
            endCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            endRadius: max(bounds.width, bounds.height) * 0.72,
            options: [.beforeStartExtent, .afterEndExtent])

        let multiplier: Int
        switch intensity {
        case .light: multiplier = 1; case .medium: multiplier = 2
        case .hard:  multiplier = 3; case .legendary: multiplier = 5
        }

        for impact in impactPoints {
            drawCracks(ctx: ctx, origin: impact, bounds: bounds, rng: &rng, multiplier: multiplier)
            drawShatterPolygons(ctx: ctx, origin: impact, bounds: bounds, rng: &rng)
            drawImpactCircle(ctx: ctx, origin: impact, rng: &rng)
        }

        ctx.setFillColor(CGColor(red: 0.04, green: 0.04, blue: 0.18, alpha: 0.2))
        ctx.fill(bounds)
        drawLCDBleed(ctx: ctx, bounds: bounds, rng: &rng)
        if intensity == .legendary { drawColorDistortion(ctx: ctx, bounds: bounds, rng: &rng) }
    }

    private func drawCracks(ctx: CGContext, origin: CGPoint, bounds: CGRect, rng: inout SeededRandom, multiplier: Int) {
        let crackCount = rng.nextInt(in: 10...18) * multiplier / 2 + multiplier * 3
        for i in 0..<crackCount {
            let baseAngle = (Double(i) / Double(crackCount)) * .pi * 2
            let angle = baseAngle + rng.nextDouble(in: -0.2...0.2)
            let length = rng.nextDouble(in: 60...min(bounds.width, bounds.height) * 0.6)
            let segments = rng.nextInt(in: 4...10)
            ctx.setStrokeColor(CGColor(red: 0.92, green: 0.92, blue: 1.0, alpha: rng.nextDouble(in: 0.55...0.95)))
            ctx.setLineWidth(rng.nextDouble(in: 0.5...2.0))
            ctx.setLineCap(.round)
            var current = origin
            var currentAngle = angle
            let segLen = length / Double(segments)
            ctx.beginPath()
            ctx.move(to: current)
            for _ in 0..<segments {
                currentAngle += rng.nextDouble(in: -0.4...0.4)
                let next = CGPoint(x: current.x + cos(currentAngle)*segLen, y: current.y + sin(currentAngle)*segLen)
                ctx.addLine(to: next)
                current = next
                if rng.nextDouble() < (multiplier > 2 ? 0.55 : 0.35) {
                    let bAngle = currentAngle + rng.nextDouble(in: 0.4...1.0) * (rng.nextBool() ? 1 : -1)
                    let bLen = segLen * rng.nextDouble(in: 0.25...0.7)
                    ctx.move(to: current)
                    ctx.addLine(to: CGPoint(x: current.x + cos(bAngle)*bLen, y: current.y + sin(bAngle)*bLen))
                    ctx.move(to: current)
                }
            }
            ctx.strokePath()
        }
    }

    private func drawShatterPolygons(ctx: CGContext, origin: CGPoint, bounds: CGRect, rng: inout SeededRandom) {
        for _ in 0..<rng.nextInt(in: 10...20) {
            let angle = rng.nextDouble(in: 0...(.pi*2))
            let dist = rng.nextDouble(in: 5...120)
            let center = CGPoint(x: origin.x + cos(angle)*dist, y: origin.y + sin(angle)*dist)
            let sides = rng.nextInt(in: 3...6)
            let radius = rng.nextDouble(in: 6...40)
            let rot = rng.nextDouble(in: 0...(.pi*2))
            ctx.beginPath()
            for s in 0..<sides {
                let a = rot + Double(s)/Double(sides) * .pi * 2
                let pt = CGPoint(x: center.x + cos(a)*radius, y: center.y + sin(a)*radius)
                s == 0 ? ctx.move(to: pt) : ctx.addLine(to: pt)
            }
            ctx.closePath()
            ctx.setFillColor(CGColor(red:0.7,green:0.8,blue:1.0,alpha:rng.nextDouble(in:0.05...0.25)))
            ctx.fillPath()
            ctx.setStrokeColor(CGColor(red:1,green:1,blue:1,alpha:rng.nextDouble(in:0.3...0.8)))
            ctx.setLineWidth(0.7)
            ctx.strokePath()
        }
    }

    private func drawImpactCircle(ctx: CGContext, origin: CGPoint, rng: inout SeededRandom) {
        for i in 1...5 {
            let r = Double(i) * rng.nextDouble(in: 7...14)
            ctx.setStrokeColor(CGColor(red:1,green:1,blue:1,alpha:0.75/Double(i)))
            ctx.setLineWidth(2.0/Double(i))
            ctx.strokeEllipse(in: CGRect(x:origin.x-r,y:origin.y-r,width:r*2,height:r*2))
        }
        ctx.setFillColor(CGColor(red:1,green:1,blue:1,alpha:1))
        ctx.fillEllipse(in: CGRect(x:origin.x-4,y:origin.y-4,width:8,height:8))
    }

    private func drawLCDBleed(ctx: CGContext, bounds: CGRect, rng: inout SeededRandom) {
        for _ in 0..<rng.nextInt(in: 4...12) {
            let x = rng.nextDouble(in: 0...bounds.width)
            ctx.setStrokeColor(CGColor(red:rng.nextDouble(in:0...0.3),green:rng.nextDouble(in:0...0.3),blue:rng.nextDouble(in:0.4...1.0),alpha:rng.nextDouble(in:0.04...0.15)))
            ctx.setLineWidth(rng.nextDouble(in: 1...5))
            ctx.beginPath()
            ctx.move(to: CGPoint(x:x,y:0))
            ctx.addLine(to: CGPoint(x:x,y:bounds.height))
            ctx.strokePath()
        }
    }

    private func drawColorDistortion(ctx: CGContext, bounds: CGRect, rng: inout SeededRandom) {
        let colors: [CGColor] = [
            CGColor(red:1,green:0,blue:0,alpha:0.12),
            CGColor(red:0,green:1,blue:0,alpha:0.08),
            CGColor(red:0,green:0,blue:1,alpha:0.1)
        ]
        for color in colors {
            for _ in 0..<rng.nextInt(in: 3...7) {
                ctx.setFillColor(color)
                ctx.fill(CGRect(x:0, y:rng.nextDouble(in:0...bounds.height), width:bounds.width, height:rng.nextDouble(in:2...15)))
            }
        }
    }

    func animateCracks() {
        guard let layer = self.layer else { return }
        let shakeX = CAKeyframeAnimation(keyPath: "position.x")
        shakeX.values = [0,-8,7,-6,5,-3,2,-1,0].map { layer.position.x + $0 }
        shakeX.duration = 0.45
        shakeX.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(shakeX, forKey: "shakeX")
        let shakeY = CAKeyframeAnimation(keyPath: "position.y")
        shakeY.values = [0,-5,4,-4,3,-2,1,0].map { layer.position.y + $0 }
        shakeY.duration = 0.45
        shakeY.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(shakeY, forKey: "shakeY")
        if intensity == .hard || intensity == .legendary {
            let scale = CAKeyframeAnimation(keyPath: "transform.scale")
            scale.values = [1.0,1.03,0.98,1.01,1.0]
            scale.duration = 0.4
            layer.add(scale, forKey: "scale")
        }
    }
}

struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17; return state
    }
    mutating func nextDouble(in range: ClosedRange<Double> = 0...1) -> Double {
        Double(next())/Double(UInt64.max) * (range.upperBound-range.lowerBound) + range.lowerBound
    }
    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        range.lowerBound + Int(next() % UInt64(range.upperBound-range.lowerBound+1))
    }
    mutating func nextBool() -> Bool { next() % 2 == 0 }
    mutating func nextDouble() -> Double { nextDouble(in: 0...1) }
}
