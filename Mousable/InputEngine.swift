import CoreGraphics
import Foundation

/// State machine that dispatches keyboard events to movers and mouse controller.
final class InputEngine {
    enum ActivationState {
        case deactivated
        case activated
    }

    private(set) var state: ActivationState = .deactivated

    /// Called on main thread when activation state changes.
    var onStateChanged: ((ActivationState) -> Void)?

    // MARK: - Dependencies

    let cursorMover: Mover
    let wheelMover: Mover
    let mouseController: MouseController
    let movementTimer: MovementTimer

    // MARK: - Held key tracking (prevents key-repeat from stacking directions)

    private var heldKeys = Set<CGKeyCode>()

    // MARK: - Held button tracking (for stuck-button prevention)

    private var leftButtonHeld = false
    private var rightButtonHeld = false

    // MARK: - Configurable keybindings

    private var activateKeyCode: CGKeyCode
    private var activateModifier: CGEventFlags
    private var deactivateKeyCode: CGKeyCode
    private var deactivateModifier: CGEventFlags

    // MARK: - Turbo parameters

    private var normalCursorMaxSpeed: Double
    private var turboCursorMaxSpeed: Double

    // MARK: - Modifier tracking for activation

    private var heldModifiers: CGEventFlags = []

    init() {
        let s = Settings.shared

        cursorMover = Mover(acceleration: s.cursorAcceleration, maxSpeed: s.cursorMaxSpeed,
                            startSpeed: s.cursorStartSpeed, diagonalRatio: 1.0 / sqrt(2.0))
        wheelMover = Mover(acceleration: s.scrollAcceleration, maxSpeed: s.scrollMaxSpeed,
                           startSpeed: s.scrollStartSpeed, diagonalRatio: 1.0)
        mouseController = MouseController()
        movementTimer = MovementTimer()

        normalCursorMaxSpeed = s.cursorMaxSpeed
        turboCursorMaxSpeed = s.turboMaxSpeed

        activateKeyCode = s.activateKeyCode
        activateModifier = s.activateModifierFlags
        deactivateKeyCode = s.deactivateKeyCode
        deactivateModifier = s.deactivateModifierFlags

        movementTimer.onTick = { [weak self] in
            self?.tick()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(applySettings),
                                               name: Settings.changedNotification, object: nil)
    }

    // MARK: - Settings observer

    @objc private func applySettings() {
        let s = Settings.shared

        cursorMover.updateParameters(acceleration: s.cursorAcceleration,
                                     maxSpeed: s.cursorMaxSpeed,
                                     startSpeed: s.cursorStartSpeed)
        wheelMover.updateParameters(acceleration: s.scrollAcceleration,
                                    maxSpeed: s.scrollMaxSpeed,
                                    startSpeed: s.scrollStartSpeed)

        normalCursorMaxSpeed = s.cursorMaxSpeed
        turboCursorMaxSpeed = s.turboMaxSpeed

        activateKeyCode = s.activateKeyCode
        activateModifier = s.activateModifierFlags
        deactivateKeyCode = s.deactivateKeyCode
        deactivateModifier = s.deactivateModifierFlags
    }

    // MARK: - Event handling

    /// Handle a key down/up event. Returns `true` if the event should be consumed.
    func handleKeyEvent(keyCode: CGKeyCode, isDown: Bool, flags: CGEventFlags) -> Bool {
        // Check activation keybinding
        if keyCode == activateKeyCode && isDown && modifiersMatch(flags, required: activateModifier) {
            if state == .deactivated {
                activate()
            }
            return true
        }

        // When deactivated, pass everything through
        guard state == .activated else { return false }

        // Check deactivation keybinding
        if keyCode == deactivateKeyCode && isDown && modifiersMatch(flags, required: deactivateModifier) {
            deactivate()
            return true
        }

        // Only intercept our bound keys
        guard KeyCode.interceptedKeys.contains(keyCode) else { return false }

        if isDown {
            // Ignore key-repeat events (macOS sends repeated keyDown while held)
            guard !heldKeys.contains(keyCode) else { return true }
            heldKeys.insert(keyCode)
            handleKeyDown(keyCode)
        } else {
            heldKeys.remove(keyCode)
            handleKeyUp(keyCode)
        }
        return true
    }

    /// Handle flagsChanged events (modifier keys). Returns `true` to consume.
    func handleFlagsChanged(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool {
        heldModifiers = flags.intersection([.maskCommand, .maskAlternate, .maskShift, .maskControl])
        // Don't consume modifier events
        return false
    }

    // MARK: - Private: modifier matching

    private func modifiersMatch(_ flags: CGEventFlags, required: CGEventFlags) -> Bool {
        let relevant: CGEventFlags = [.maskCommand, .maskAlternate, .maskShift, .maskControl]
        let active = flags.intersection(relevant)
        return active == required
    }

    // MARK: - Private: key dispatch

    private func handleKeyDown(_ keyCode: CGKeyCode) {
        switch keyCode {
        case KeyCode.w:
            cursorMover.addDirection(.up)
        case KeyCode.a:
            cursorMover.addDirection(.left)
        case KeyCode.s:
            cursorMover.addDirection(.down)
        case KeyCode.d:
            cursorMover.addDirection(.right)
        case KeyCode.j:
            if !leftButtonHeld {
                leftButtonHeld = true
                mouseController.mouseDown(.left)
            }
        case KeyCode.l:
            if !rightButtonHeld {
                rightButtonHeld = true
                mouseController.mouseDown(.right)
            }
        case KeyCode.r:
            wheelMover.addDirection(.up)
        case KeyCode.f:
            wheelMover.addDirection(.down)
        case KeyCode.q:
            wheelMover.addDirection(.right)
        case KeyCode.e:
            wheelMover.addDirection(.left)
        case KeyCode.h:
            cursorMover.setMaxSpeed(turboCursorMaxSpeed)
        default:
            break
        }
    }

    private func handleKeyUp(_ keyCode: CGKeyCode) {
        switch keyCode {
        case KeyCode.w:
            cursorMover.removeDirection(.up)
        case KeyCode.a:
            cursorMover.removeDirection(.left)
        case KeyCode.s:
            cursorMover.removeDirection(.down)
        case KeyCode.d:
            cursorMover.removeDirection(.right)
        case KeyCode.j:
            if leftButtonHeld {
                leftButtonHeld = false
                mouseController.mouseUp(.left)
            }
        case KeyCode.l:
            if rightButtonHeld {
                rightButtonHeld = false
                mouseController.mouseUp(.right)
            }
        case KeyCode.r:
            wheelMover.removeDirection(.up)
        case KeyCode.f:
            wheelMover.removeDirection(.down)
        case KeyCode.q:
            wheelMover.removeDirection(.right)
        case KeyCode.e:
            wheelMover.removeDirection(.left)
        case KeyCode.h:
            cursorMover.resetMaxSpeed()
        default:
            break
        }
    }

    // MARK: - Activation

    private func toggle() {
        switch state {
        case .deactivated:
            activate()
        case .activated:
            deactivate()
        }
    }

    private func activate() {
        state = .activated
        movementTimer.start()
        notifyStateChanged()
    }

    private func deactivate() {
        state = .deactivated
        movementTimer.stop()

        // Release any held mouse buttons to prevent stuck buttons
        if leftButtonHeld {
            leftButtonHeld = false
            mouseController.mouseUp(.left)
        }
        if rightButtonHeld {
            rightButtonHeld = false
            mouseController.mouseUp(.right)
        }

        // Reset movers and held key state
        cursorMover.reset()
        wheelMover.reset()
        heldKeys.removeAll()

        notifyStateChanged()
    }

    // MARK: - Timer tick

    private func tick() {
        // Accelerate movers
        cursorMover.accelerate()
        wheelMover.accelerate()

        // Get movement vectors
        let cursor = cursorMover.vector()
        let wheel = wheelMover.vector()

        // Post mouse events
        mouseController.moveCursor(dx: cursor.dx, dy: cursor.dy)
        // Scroll: up = negative direction in wheel mover but positive scroll value
        mouseController.scroll(vertical: -wheel.dy, horizontal: wheel.dx)
    }

    // MARK: - Notification

    private func notifyStateChanged() {
        let currentState = state
        DispatchQueue.main.async { [weak self] in
            self?.onStateChanged?(currentState)
        }
    }
}
