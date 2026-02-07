import AppKit
import Carbon.HIToolbox
import ServiceManagement

/// Programmatic settings window with sliders for speed and key-recording for keybindings.
final class SettingsWindowController: NSWindowController {

    // MARK: - Slider references (for reset)

    private var cursorAccelSlider: NSSlider!
    private var cursorMaxSpeedSlider: NSSlider!
    private var cursorStartSpeedSlider: NSSlider!
    private var turboSpeedSlider: NSSlider!
    private var scrollAccelSlider: NSSlider!
    private var scrollMaxSpeedSlider: NSSlider!
    private var scrollStartSpeedSlider: NSSlider!

    // MARK: - Key recording buttons

    private var activateButton: KeyRecordButton!
    private var deactivateButton: KeyRecordButton!

    // MARK: - Launch at login

    private var launchAtLoginCheckbox: NSButton!

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 580),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Mousable Settings"
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        buildUI()
        loadValues()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showWindow() {
        loadValues()
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Build UI

    private func buildUI() {
        guard let contentView = window?.contentView else { return }

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 16
        root.edgeInsets = NSEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        root.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: contentView.topAnchor),
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            root.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        // --- Cursor Speed ---
        root.addArrangedSubview(sectionLabel("Cursor Speed"))
        cursorAccelSlider = addSliderRow(to: root, label: "Acceleration", min: 0.1, max: 5.0, tag: 1)
        cursorMaxSpeedSlider = addSliderRow(to: root, label: "Max Speed", min: 5, max: 100, tag: 2)
        cursorStartSpeedSlider = addSliderRow(to: root, label: "Start Speed", min: 0, max: 20, tag: 3)
        turboSpeedSlider = addSliderRow(to: root, label: "Turbo Speed", min: 10, max: 200, tag: 4)

        root.addArrangedSubview(separator())

        // --- Scroll Speed ---
        root.addArrangedSubview(sectionLabel("Scroll Speed"))
        scrollAccelSlider = addSliderRow(to: root, label: "Acceleration", min: 0.1, max: 20, tag: 5)
        scrollMaxSpeedSlider = addSliderRow(to: root, label: "Max Speed", min: 5, max: 200, tag: 6)
        scrollStartSpeedSlider = addSliderRow(to: root, label: "Start Speed", min: 0, max: 20, tag: 7)

        root.addArrangedSubview(separator())

        // --- Keybindings ---
        root.addArrangedSubview(sectionLabel("Keybindings"))
        activateButton = addKeyRow(to: root, label: "Activate:", tag: 100)
        deactivateButton = addKeyRow(to: root, label: "Deactivate:", tag: 101)

        root.addArrangedSubview(separator())

        // --- General ---
        root.addArrangedSubview(sectionLabel("General"))
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(launchAtLoginChanged(_:)))
        root.addArrangedSubview(launchAtLoginCheckbox)

        if #available(macOS 13.0, *) {
            // SMAppService available
        } else {
            launchAtLoginCheckbox.isEnabled = false
            launchAtLoginCheckbox.toolTip = "Requires macOS 13 or later"
        }

        root.addArrangedSubview(separator())

        // --- Reset ---
        let resetButton = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetDefaults))
        root.addArrangedSubview(resetButton)
    }

    // MARK: - Load / Save

    private func loadValues() {
        let s = Settings.shared
        cursorAccelSlider.doubleValue = s.cursorAcceleration
        cursorMaxSpeedSlider.doubleValue = s.cursorMaxSpeed
        cursorStartSpeedSlider.doubleValue = s.cursorStartSpeed
        turboSpeedSlider.doubleValue = s.turboMaxSpeed
        scrollAccelSlider.doubleValue = s.scrollAcceleration
        scrollMaxSpeedSlider.doubleValue = s.scrollMaxSpeed
        scrollStartSpeedSlider.doubleValue = s.scrollStartSpeed

        activateButton.update(keyCode: s.activateKeyCode, modifiers: s.activateModifierFlags)
        deactivateButton.update(keyCode: s.deactivateKeyCode, modifiers: s.deactivateModifierFlags)

        if #available(macOS 13.0, *) {
            launchAtLoginCheckbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
    }

    @objc private func sliderChanged(_ sender: NSSlider) {
        let s = Settings.shared
        switch sender.tag {
        case 1: s.cursorAcceleration = sender.doubleValue
        case 2: s.cursorMaxSpeed = sender.doubleValue
        case 3: s.cursorStartSpeed = sender.doubleValue
        case 4: s.turboMaxSpeed = sender.doubleValue
        case 5: s.scrollAcceleration = sender.doubleValue
        case 6: s.scrollMaxSpeed = sender.doubleValue
        case 7: s.scrollStartSpeed = sender.doubleValue
        default: break
        }
    }

    @objc private func launchAtLoginChanged(_ sender: NSButton) {
        if #available(macOS 13.0, *) {
            do {
                if sender.state == .on {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("Mousable: Failed to update launch at login: \(error)")
                // Revert checkbox to actual state
                sender.state = SMAppService.mainApp.status == .enabled ? .on : .off
            }
        }
    }

    @objc private func resetDefaults() {
        Settings.shared.resetToDefaults()
        loadValues()
    }

    // MARK: - UI helpers

    private func sectionLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .boldSystemFont(ofSize: 13)
        return label
    }

    private func separator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        box.translatesAutoresizingMaskIntoConstraints = false
        box.widthAnchor.constraint(greaterThanOrEqualToConstant: 400).isActive = true
        return box
    }

    private func addSliderRow(to stack: NSStackView, label: String, min: Double, max: Double, tag: Int) -> NSSlider {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 8

        let nameLabel = NSTextField(labelWithString: label)
        nameLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        row.addArrangedSubview(nameLabel)

        let slider = NSSlider(value: 0, minValue: min, maxValue: max, target: self, action: #selector(sliderChanged(_:)))
        slider.tag = tag
        slider.isContinuous = true
        slider.widthAnchor.constraint(equalToConstant: 250).isActive = true
        row.addArrangedSubview(slider)

        stack.addArrangedSubview(row)
        return slider
    }

    private func addKeyRow(to stack: NSStackView, label: String, tag: Int) -> KeyRecordButton {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 8

        let nameLabel = NSTextField(labelWithString: label)
        nameLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        row.addArrangedSubview(nameLabel)

        let button = KeyRecordButton(tag: tag) { [weak self] keyCode, modifiers in
            self?.keybindingRecorded(tag: tag, keyCode: keyCode, modifiers: modifiers)
        }
        button.widthAnchor.constraint(equalToConstant: 200).isActive = true
        row.addArrangedSubview(button)

        stack.addArrangedSubview(row)
        return button
    }

    private func keybindingRecorded(tag: Int, keyCode: CGKeyCode, modifiers: CGEventFlags) {
        let s = Settings.shared
        switch tag {
        case 100:
            s.activateKeyCode = keyCode
            s.activateModifierFlags = modifiers
        case 101:
            s.deactivateKeyCode = keyCode
            s.deactivateModifierFlags = modifiers
        default: break
        }
    }
}

// MARK: - KeyRecordButton

/// A button that captures the next key press as a keybinding.
final class KeyRecordButton: NSButton {
    private var recording = false
    private var onRecord: ((CGKeyCode, CGEventFlags) -> Void)?
    private var localMonitor: Any?

    private var currentKeyCode: CGKeyCode = 0
    private var currentModifiers: CGEventFlags = []

    init(tag: Int, onRecord: @escaping (CGKeyCode, CGEventFlags) -> Void) {
        self.onRecord = onRecord
        super.init(frame: .zero)
        self.tag = tag
        self.bezelStyle = .rounded
        self.target = self
        self.action = #selector(startRecording)
        self.title = "Press to record"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        currentKeyCode = keyCode
        currentModifiers = modifiers
        title = Self.displayString(keyCode: keyCode, modifiers: modifiers)
    }

    @objc private func startRecording() {
        recording = true
        title = "Press a key..."

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.finishRecording(event: event)
            return nil // consume the event
        }
    }

    private func finishRecording(event: NSEvent) {
        recording = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }

        let keyCode = CGKeyCode(event.keyCode)
        let modifiers = Self.cgEventFlags(from: event.modifierFlags)
        currentKeyCode = keyCode
        currentModifiers = modifiers
        title = Self.displayString(keyCode: keyCode, modifiers: modifiers)
        onRecord?(keyCode, modifiers)
    }

    // MARK: - Display helpers

    static func displayString(keyCode: CGKeyCode, modifiers: CGEventFlags) -> String {
        var parts: [String] = []
        if modifiers.contains(.maskControl) { parts.append("Ctrl") }
        if modifiers.contains(.maskAlternate) { parts.append("Opt") }
        if modifiers.contains(.maskShift) { parts.append("Shift") }
        if modifiers.contains(.maskCommand) { parts.append("Cmd") }
        parts.append(keyName(for: keyCode))
        return parts.joined(separator: "+")
    }

    static func keyName(for keyCode: CGKeyCode) -> String {
        // Map common key codes to readable names
        let names: [CGKeyCode: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G",
            6: "Z", 7: "X", 8: "C", 9: "V", 11: "B", 12: "Q",
            13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
            18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
            24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
            36: "Return", 37: "L", 38: "J", 39: "'", 40: "K",
            41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M",
            47: ".", 48: "Tab", 49: "Space", 50: "`",
            51: "Delete", 53: "Escape",
            123: "Left", 124: "Right", 125: "Down", 126: "Up",
        ]
        return names[keyCode] ?? "Key\(keyCode)"
    }

    private static func cgEventFlags(from nsFlags: NSEvent.ModifierFlags) -> CGEventFlags {
        var flags: UInt64 = 0
        if nsFlags.contains(.control)  { flags |= CGEventFlags.maskControl.rawValue }
        if nsFlags.contains(.option)   { flags |= CGEventFlags.maskAlternate.rawValue }
        if nsFlags.contains(.shift)    { flags |= CGEventFlags.maskShift.rawValue }
        if nsFlags.contains(.command)  { flags |= CGEventFlags.maskCommand.rawValue }
        return CGEventFlags(rawValue: flags)
    }
}
