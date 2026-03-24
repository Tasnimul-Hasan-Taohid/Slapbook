import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var slapDetector: SlapDetector!
    var overlayWindowController: OverlayWindowController?
    var slapCount = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "👋"
            button.toolTip = "SlapBook — dare to slap"
        }

        let menu = NSMenu()
        let header = NSMenuItem(title: "SlapBook  💥", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Slap Counter: 0", action: nil, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Preferences…", action: #selector(openPrefs), keyEquivalent: ",")
        menu.addItem(withTitle: "Test a Slap 👋", action: #selector(testSlap), keyEquivalent: "t")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit SlapBook", action: #selector(quitApp), keyEquivalent: "q")
        statusItem.menu = menu

        slapDetector = SlapDetector()
        slapDetector.onSlap = { [weak self] intensity in
            DispatchQueue.main.async {
                self?.handleSlap(intensity: intensity)
            }
        }
        slapDetector.start()
    }

    func handleSlap(intensity: SlapIntensity) {
        slapCount += 1
        if let menu = statusItem.menu, menu.items.count > 2 {
            menu.items[2].title = "Slap Counter: \(slapCount)"
        }
        let emojis = ["😱", "💥", "😵", "🤕", "😤", "😭", "🙀"]
        statusItem.button?.title = emojis.randomElement()!
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.statusItem.button?.title = "👋"
        }
        showBrokenScreen(intensity: intensity)
    }

    func showBrokenScreen(intensity: SlapIntensity = .medium) {
        overlayWindowController?.dismiss()
        overlayWindowController = OverlayWindowController(intensity: intensity)
        overlayWindowController?.showWindow(nil)
    }

    @objc func testSlap() { handleSlap(intensity: .medium) }
    @objc func openPrefs() {
        PreferencesWindowController.shared.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    @objc func quitApp() { NSApp.terminate(nil) }
}
