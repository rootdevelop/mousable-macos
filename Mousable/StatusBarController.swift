import AppKit

/// Manages the menu bar status item with icon and dropdown menu.
final class StatusBarController {
    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var settingsWindowController: SettingsWindowController?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        setupMenu()
        setActivated(false)
    }

    func setActivated(_ activated: Bool) {
        if let button = statusItem.button {
            let imageName = activated ? "computermouse.fill" : "computermouse"
            if let image = NSImage(systemSymbolName: imageName, accessibilityDescription: "Mousable") {
                image.isTemplate = true
                button.image = image
            }
        }
        statusMenuItem.title = activated ? "Status: Active" : "Status: Inactive"
    }

    private func setupMenu() {
        let menu = NSMenu()

        statusMenuItem = NSMenuItem(title: "Status: Inactive", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Mousable", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow()
    }
}
