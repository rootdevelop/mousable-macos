import CoreGraphics
import Foundation

enum MouseButton {
    case left
    case right
}

/// Posts mouse events via Core Graphics.
final class MouseController {

    /// Tracks click timing per button for multi-click detection
    private var lastClickTime: [MouseButton: TimeInterval] = [:]
    private var clickCount: [MouseButton: Int64] = [:]

    /// Tracks held buttons so moveCursor can post drag events
    private var leftHeld = false
    private var rightHeld = false

    /// macOS double-click threshold (matches system default)
    private let multiClickInterval: TimeInterval = 0.3

    // MARK: - Cursor movement

    func moveCursor(dx: Int, dy: Int) {
        guard dx != 0 || dy != 0 else { return }

        guard let currentEvent = CGEvent(source: nil) else { return }
        let currentLocation = currentEvent.location

        let bounds = MouseController.screenBounds()
        let newX = min(max(currentLocation.x + CGFloat(dx), bounds.minX), bounds.maxX - 1)
        let newY = min(max(currentLocation.y + CGFloat(dy), bounds.minY), bounds.maxY - 1)
        let newPoint = CGPoint(x: newX, y: newY)

        CGWarpMouseCursorPosition(newPoint)

        // Post the correct event type: drag events when a button is held,
        // mouseMoved otherwise. Without drag events, window moves/resizes
        // don't update visually until the button is released.
        let eventType: CGEventType
        let mouseButton: CGMouseButton
        if leftHeld {
            eventType = .leftMouseDragged
            mouseButton = .left
        } else if rightHeld {
            eventType = .rightMouseDragged
            mouseButton = .right
        } else {
            eventType = .mouseMoved
            mouseButton = .left
        }

        if let moveEvent = CGEvent(mouseEventSource: nil, mouseType: eventType,
                                   mouseCursorPosition: newPoint, mouseButton: mouseButton) {
            moveEvent.setIntegerValueField(.mouseEventDeltaX, value: Int64(dx))
            moveEvent.setIntegerValueField(.mouseEventDeltaY, value: Int64(dy))
            moveEvent.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Click / drag

    func mouseDown(_ button: MouseButton) {
        switch button {
        case .left: leftHeld = true
        case .right: rightHeld = true
        }

        guard let currentEvent = CGEvent(source: nil) else { return }
        let pos = currentEvent.location

        // Determine click count based on timing
        let now = ProcessInfo.processInfo.systemUptime
        let lastTime = lastClickTime[button] ?? 0
        if now - lastTime <= multiClickInterval {
            clickCount[button] = (clickCount[button] ?? 1) + 1
        } else {
            clickCount[button] = 1
        }
        lastClickTime[button] = now

        let count = clickCount[button] ?? 1
        let (eventType, cgButton) = buttonParams(button, isDown: true)
        if let event = CGEvent(mouseEventSource: nil, mouseType: eventType,
                               mouseCursorPosition: pos, mouseButton: cgButton) {
            event.setIntegerValueField(.mouseEventClickState, value: count)
            event.post(tap: .cghidEventTap)
        }
    }

    func mouseUp(_ button: MouseButton) {
        switch button {
        case .left: leftHeld = false
        case .right: rightHeld = false
        }

        guard let currentEvent = CGEvent(source: nil) else { return }
        let pos = currentEvent.location

        let count = clickCount[button] ?? 1
        let (eventType, cgButton) = buttonParams(button, isDown: false)
        if let event = CGEvent(mouseEventSource: nil, mouseType: eventType,
                               mouseCursorPosition: pos, mouseButton: cgButton) {
            event.setIntegerValueField(.mouseEventClickState, value: count)
            event.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Scrolling

    func scroll(vertical: Int, horizontal: Int) {
        guard vertical != 0 || horizontal != 0 else { return }

        // scrollWheelEvent2 with pixel units for smooth scrolling
        if let event = CGEvent(scrollWheelEvent2Source: nil,
                               units: .pixel,
                               wheelCount: 2,
                               wheel1: Int32(vertical),
                               wheel2: Int32(horizontal),
                               wheel3: 0) {
            event.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Screen bounds

    /// Returns the union of all active display bounds in CG coordinate space.
    private static func screenBounds() -> CGRect {
        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &displayCount)
        guard displayCount > 0 else { return CGRect(x: 0, y: 0, width: 1920, height: 1080) }

        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetActiveDisplayList(displayCount, &displays, &displayCount)

        var union = CGDisplayBounds(displays[0])
        for i in 1..<Int(displayCount) {
            union = union.union(CGDisplayBounds(displays[i]))
        }
        return union
    }

    // MARK: - Private

    private func buttonParams(_ button: MouseButton, isDown: Bool) -> (CGEventType, CGMouseButton) {
        switch button {
        case .left:
            return (isDown ? .leftMouseDown : .leftMouseUp, .left)
        case .right:
            return (isDown ? .rightMouseDown : .rightMouseUp, .right)
        }
    }
}
