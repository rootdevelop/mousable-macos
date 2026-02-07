import CoreGraphics
import Foundation

/// Installs a CGEventTap to intercept keyboard events globally.
final class EventTapManager {
    /// Return `true` to consume the event, `false` to pass it through.
    var onKeyEvent: ((_ keyCode: CGKeyCode, _ isDown: Bool, _ flags: CGEventFlags) -> Bool)?

    /// Called for flagsChanged events (modifier keys).
    /// Return `true` to consume the event, `false` to pass it through.
    var onFlagsChanged: ((_ keyCode: CGKeyCode, _ flags: CGEventFlags) -> Bool)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() -> Bool {
        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        // Bridge `self` into the C callback via userInfo
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: userInfo
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
    }

    /// Re-enable the tap if macOS disabled it due to timeout
    fileprivate func reenable() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
}

/// C-compatible callback bridging to the EventTapManager instance.
private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let manager = Unmanaged<EventTapManager>.fromOpaque(userInfo).takeUnretainedValue()

    // Handle tap disabled by timeout
    if type == .tapDisabledByTimeout {
        manager.reenable()
        return Unmanaged.passUnretained(event)
    }

    let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
    let flags = event.flags

    switch type {
    case .keyDown:
        if manager.onKeyEvent?(keyCode, true, flags) == true {
            return nil // consume
        }
    case .keyUp:
        if manager.onKeyEvent?(keyCode, false, flags) == true {
            return nil // consume
        }
    case .flagsChanged:
        if manager.onFlagsChanged?(keyCode, flags) == true {
            return nil // consume
        }
    default:
        break
    }

    return Unmanaged.passUnretained(event)
}
