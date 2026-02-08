import Foundation
import CoreGraphics

/// UserDefaults-backed settings singleton for all configurable parameters.
final class Settings {
    static let shared = Settings()

    static let changedNotification = Notification.Name("SettingsChanged")

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Key: String {
        case cursorAcceleration, cursorMaxSpeed, cursorStartSpeed, turboMaxSpeed
        case scrollAcceleration, scrollMaxSpeed, scrollStartSpeed
        case activateKeyCode, activateModifierFlags
        case deactivateKeyCode, deactivateModifierFlags
    }

    // MARK: - Defaults

    static let defaultCursorAcceleration: Double = 0.575
    static let defaultCursorMaxSpeed: Double = 11.5
    static let defaultCursorStartSpeed: Double = 1.5
    static let defaultTurboMaxSpeed: Double = 75

    static let defaultScrollAcceleration: Double = 4.6
    static let defaultScrollMaxSpeed: Double = 46
    static let defaultScrollStartSpeed: Double = 2

    static let defaultActivateKeyCode: CGKeyCode = 38       // J
    static let defaultActivateModifierFlags: UInt64 = CGEventFlags.maskCommand.rawValue
    static let defaultDeactivateKeyCode: CGKeyCode = 41     // ;
    static let defaultDeactivateModifierFlags: UInt64 = 0   // no modifier

    // MARK: - Cursor Speed

    var cursorAcceleration: Double {
        get { value(for: .cursorAcceleration, default: Self.defaultCursorAcceleration) }
        set { set(newValue, for: .cursorAcceleration) }
    }

    var cursorMaxSpeed: Double {
        get { value(for: .cursorMaxSpeed, default: Self.defaultCursorMaxSpeed) }
        set { set(newValue, for: .cursorMaxSpeed) }
    }

    var cursorStartSpeed: Double {
        get { value(for: .cursorStartSpeed, default: Self.defaultCursorStartSpeed) }
        set { set(newValue, for: .cursorStartSpeed) }
    }

    var turboMaxSpeed: Double {
        get { value(for: .turboMaxSpeed, default: Self.defaultTurboMaxSpeed) }
        set { set(newValue, for: .turboMaxSpeed) }
    }

    // MARK: - Scroll Speed

    var scrollAcceleration: Double {
        get { value(for: .scrollAcceleration, default: Self.defaultScrollAcceleration) }
        set { set(newValue, for: .scrollAcceleration) }
    }

    var scrollMaxSpeed: Double {
        get { value(for: .scrollMaxSpeed, default: Self.defaultScrollMaxSpeed) }
        set { set(newValue, for: .scrollMaxSpeed) }
    }

    var scrollStartSpeed: Double {
        get { value(for: .scrollStartSpeed, default: Self.defaultScrollStartSpeed) }
        set { set(newValue, for: .scrollStartSpeed) }
    }

    // MARK: - Keybindings

    var activateKeyCode: CGKeyCode {
        get { CGKeyCode(intValue(for: .activateKeyCode, default: Int(Self.defaultActivateKeyCode))) }
        set { setInt(Int(newValue), for: .activateKeyCode) }
    }

    var activateModifierFlags: CGEventFlags {
        get { CGEventFlags(rawValue: uint64Value(for: .activateModifierFlags, default: Self.defaultActivateModifierFlags)) }
        set { setUInt64(newValue.rawValue, for: .activateModifierFlags) }
    }

    var deactivateKeyCode: CGKeyCode {
        get { CGKeyCode(intValue(for: .deactivateKeyCode, default: Int(Self.defaultDeactivateKeyCode))) }
        set { setInt(Int(newValue), for: .deactivateKeyCode) }
    }

    var deactivateModifierFlags: CGEventFlags {
        get { CGEventFlags(rawValue: uint64Value(for: .deactivateModifierFlags, default: Self.defaultDeactivateModifierFlags)) }
        set { setUInt64(newValue.rawValue, for: .deactivateModifierFlags) }
    }

    // MARK: - Reset

    func resetToDefaults() {
        let keys: [Key] = [
            .cursorAcceleration, .cursorMaxSpeed, .cursorStartSpeed, .turboMaxSpeed,
            .scrollAcceleration, .scrollMaxSpeed, .scrollStartSpeed,
            .activateKeyCode, .activateModifierFlags,
            .deactivateKeyCode, .deactivateModifierFlags,
        ]
        for key in keys {
            defaults.removeObject(forKey: key.rawValue)
        }
        postChanged()
    }

    // MARK: - Private helpers

    private func value(for key: Key, default defaultValue: Double) -> Double {
        defaults.object(forKey: key.rawValue) != nil ? defaults.double(forKey: key.rawValue) : defaultValue
    }

    private func intValue(for key: Key, default defaultValue: Int) -> Int {
        defaults.object(forKey: key.rawValue) != nil ? defaults.integer(forKey: key.rawValue) : defaultValue
    }

    private func uint64Value(for key: Key, default defaultValue: UInt64) -> UInt64 {
        defaults.object(forKey: key.rawValue) != nil ? UInt64(defaults.integer(forKey: key.rawValue)) : defaultValue
    }

    private func set(_ value: Double, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
        postChanged()
    }

    private func setInt(_ value: Int, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
        postChanged()
    }

    private func setUInt64(_ value: UInt64, for key: Key) {
        defaults.set(Int(value), forKey: key.rawValue)
        postChanged()
    }

    private func postChanged() {
        NotificationCenter.default.post(name: Self.changedNotification, object: self)
    }

    private init() {}
}
