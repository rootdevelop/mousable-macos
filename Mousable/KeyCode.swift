import CoreGraphics

enum KeyCode {
    // Movement keys (WASD)
    static let w: CGKeyCode = 13
    static let a: CGKeyCode = 0
    static let s: CGKeyCode = 1
    static let d: CGKeyCode = 2

    // Action keys
    static let j: CGKeyCode = 38  // Left click
    static let l: CGKeyCode = 37  // Right click

    // Scroll keys
    static let r: CGKeyCode = 15  // Scroll up
    static let f: CGKeyCode = 3   // Scroll down
    static let q: CGKeyCode = 12  // Scroll left
    static let e: CGKeyCode = 14  // Scroll right

    // Modifier
    static let h: CGKeyCode = 4   // Speed boost (turbo)

    // Deactivation
    static let semicolon: CGKeyCode = 41

    /// All keys that should be intercepted when activated
    static let interceptedKeys: Set<CGKeyCode> = [
        w, a, s, d,
        j, l,
        r, f, q, e,
        h,
        semicolon
    ]
}
