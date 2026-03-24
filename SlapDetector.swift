import Foundation
import IOKit

enum SlapIntensity {
    case light
    case medium
    case hard
    case legendary

    init(delta: Double) {
        switch delta {
        case ..<150:  self = .light
        case ..<300:  self = .medium
        case ..<500:  self = .hard
        default:      self = .legendary
        }
    }

    var reactionEmoji: String {
        switch self {
        case .light:     return "😮"
        case .medium:    return "😱"
        case .hard:      return "🤯"
        case .legendary: return "💀"
        }
    }
}

struct AccelData {
    var x: Int16 = 0
    var y: Int16 = 0
    var z: Int16 = 0
}

class SlapDetector {
    var onSlap: ((SlapIntensity) -> Void)?

    var threshold: Double {
        let v = UserDefaults.standard.double(forKey: "slapThreshold")
        return v == 0 ? 200 : v
    }

    private var smsService: io_object_t = 0
    private var isRunning = false
    private var lastFiredAt: Date = .distantPast
    private var cooldown: Double = 1.2
    private var pollingTimer: DispatchSourceTimer?

    func start() {
        guard openSMS() else {
            print("[SlapBook] SMS not available — using keyboard fallback (Shift+Ctrl+S)")
            startKeyboardFallback()
            return
        }
        isRunning = true
        startPolling()
    }

    func stop() {
        isRunning = false
        pollingTimer?.cancel()
        pollingTimer = nil
        if smsService != 0 { IOObjectRelease(smsService) }
    }

    private func openSMS() -> Bool {
        smsService = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("SMCMotionSensor")
        )
        return smsService != 0
    }

    private func readAcceleration() -> AccelData? {
        guard smsService != 0 else { return nil }
        var data = AccelData()
        let size = MemoryLayout<AccelData>.size
        let kr = withUnsafeMutableBytes(of: &data) { ptr -> kern_return_t in
            IOConnectCallStructMethod(smsService, 0, nil, 0, ptr.baseAddress, [UInt(size)])
        }
        return kr == KERN_SUCCESS ? data : nil
    }

    private func startPolling() {
        let queue = DispatchQueue(label: "slapbook.accel", qos: .userInteractive)
        pollingTimer = DispatchSource.makeTimerSource(queue: queue)
        pollingTimer?.schedule(deadline: .now(), repeating: .milliseconds(16))
        var prev: Double = 0

        pollingTimer?.setEventHandler { [weak self] in
            guard let self, self.isRunning else { return }
            guard let data = self.readAcceleration() else { return }
            let x = Double(data.x), y = Double(data.y), z = Double(data.z)
            let mag = sqrt(x*x + y*y + z*z)
            let delta = abs(mag - prev)
            prev = mag
            if delta > self.threshold {
                let now = Date()
                if now.timeIntervalSince(self.lastFiredAt) > self.cooldown {
                    self.lastFiredAt = now
                    self.onSlap?(SlapIntensity(delta: delta))
                }
            }
        }
        pollingTimer?.resume()
    }

    private func startKeyboardFallback() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.shift, .control]) && event.keyCode == 1 {
                self?.onSlap?(.medium)
            }
        }
    }
}
