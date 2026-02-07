import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var eventTapManager: EventTapManager!
    private var inputEngine: InputEngine!
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        inputEngine = InputEngine()

        inputEngine.onStateChanged = { [weak self] state in
            self?.statusBarController.setActivated(state == .activated)
        }

        requestAccessibilityPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {
        eventTapManager?.stop()
        inputEngine?.movementTimer.stop()
    }

    // MARK: - Accessibility Permission

    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            setupEventTap()
            return
        }

        // Poll every 2 seconds until granted
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            if AXIsProcessTrusted() {
                self?.permissionTimer?.invalidate()
                self?.permissionTimer = nil
                self?.setupEventTap()
            }
        }
    }

    // MARK: - Event Tap Setup

    private func setupEventTap() {
        eventTapManager = EventTapManager()

        eventTapManager.onKeyEvent = { [weak self] keyCode, isDown, flags in
            guard let self = self else { return false }
            return self.inputEngine.handleKeyEvent(keyCode: keyCode, isDown: isDown, flags: flags)
        }

        eventTapManager.onFlagsChanged = { [weak self] keyCode, flags in
            guard let self = self else { return false }
            return self.inputEngine.handleFlagsChanged(keyCode: keyCode, flags: flags)
        }

        if !eventTapManager.start() {
            NSLog("Mousable: Failed to create event tap. Accessibility permission may not be granted.")
        }
    }
}
