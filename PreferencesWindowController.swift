import AppKit

class PreferencesWindowController: NSWindowController {
    static let shared = PreferencesWindowController()
    private var slider: NSSlider!
    private var label: NSTextField!
    private var soundToggle: NSButton!

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "SlapBook Preferences"
        window.center()
        super.init(window: window)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildUI() {
        guard let v = window?.contentView else { return }

        let title = NSTextField(labelWithString: "Slap Sensitivity")
        title.frame = NSRect(x: 20, y: 158, width: 280, height: 22)
        title.font = .boldSystemFont(ofSize: 13)
        v.addSubview(title)

        let hint = NSTextField(labelWithString: "Lower = easier to trigger")
        hint.frame = NSRect(x: 20, y: 140, width: 280, height: 18)
        hint.font = .systemFont(ofSize: 10)
        hint.textColor = .secondaryLabelColor
        v.addSubview(hint)

        slider = NSSlider(value: threshold, minValue: 50, maxValue: 500, target: self, action: #selector(sliderChanged))
        slider.frame = NSRect(x: 20, y: 110, width: 240, height: 24)
        v.addSubview(slider)

        label = NSTextField(labelWithString: sensitivityLabel)
        label.frame = NSRect(x: 268, y: 112, width: 80, height: 20)
        label.alignment = .right
        v.addSubview(label)

        soundToggle = NSButton(checkboxWithTitle: "Enable voice reactions (Talking Tom mode 🎙️)", target: self, action: #selector(toggleSound))
        soundToggle.frame = NSRect(x: 20, y: 78, width: 320, height: 22)
        soundToggle.state = soundEnabled ? .on : .off
        v.addSubview(soundToggle)

        let sep = NSBox()
        sep.frame = NSRect(x: 20, y: 60, width: 320, height: 1)
        sep.boxType = .separator
        v.addSubview(sep)

        let test = NSButton(title: "👋 Test a Slap", target: self, action: #selector(testSlap))
        test.frame = NSRect(x: 20, y: 18, width: 130, height: 32)
        test.bezelStyle = .rounded
        v.addSubview(test)

        let done = NSButton(title: "Done", target: self, action: #selector(close))
        done.frame = NSRect(x: 260, y: 18, width: 80, height: 32)
        done.bezelStyle = .rounded
        done.keyEquivalent = "\r"
        v.addSubview(done)
    }

    private var threshold: Double {
        let v = UserDefaults.standard.double(forKey: "slapThreshold")
        return v == 0 ? 200 : v
    }
    private var soundEnabled: Bool {
        UserDefaults.standard.object(forKey: "soundEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "soundEnabled")
    }
    private var sensitivityLabel: String {
        let v = slider?.doubleValue ?? threshold
        switch v {
        case ..<100: return "🪶 Hair trigger"
        case ..<200: return "✋ Light"
        case ..<300: return "👋 Normal"
        case ..<400: return "💪 Hard"
        default:     return "💥 Bonk mode"
        }
    }

    @objc private func sliderChanged() {
        UserDefaults.standard.set(slider.doubleValue, forKey: "slapThreshold")
        label.stringValue = sensitivityLabel
    }
    @objc private func toggleSound() {
        UserDefaults.standard.set(soundToggle.state == .on, forKey: "soundEnabled")
    }
    @objc private func testSlap() {
        (NSApp.delegate as? AppDelegate)?.handleSlap(intensity: .medium)
    }
}
