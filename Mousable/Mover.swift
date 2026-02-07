import Foundation

struct DirectionSet: OptionSet {
    let rawValue: UInt8

    static let up    = DirectionSet(rawValue: 1 << 0)
    static let down  = DirectionSet(rawValue: 1 << 1)
    static let left  = DirectionSet(rawValue: 1 << 2)
    static let right = DirectionSet(rawValue: 1 << 3)
}

/// Velocity/acceleration model ported from windows-version/internal/logic/mover/mover.go
/// Tracks a stack of held directions and produces a velocity vector each tick.
final class Mover {
    private var speed: Double = 0
    private var _maxSpeed: Double
    private var defaultMaxSpeed: Double
    private var acceleration: Double
    private let diagonalRatio: Double
    private var startSpeed: Double

    /// Stack of held directions (allows correct behavior when multiple keys overlap)
    private var directionStack: [DirectionSet] = []
    /// Combined direction from the stack
    private var direction: DirectionSet = []

    init(acceleration: Double, maxSpeed: Double, startSpeed: Double = 0, diagonalRatio: Double = 1.0 / sqrt(2.0)) {
        self.acceleration = acceleration
        self._maxSpeed = maxSpeed
        self.defaultMaxSpeed = maxSpeed
        self.startSpeed = startSpeed
        self.diagonalRatio = diagonalRatio
    }

    // MARK: - Direction management

    func addDirection(_ dir: DirectionSet) {
        directionStack.append(dir)
        recalcDirection()
    }

    func removeDirection(_ dir: DirectionSet) {
        if let idx = directionStack.firstIndex(of: dir) {
            directionStack.remove(at: idx)
        }
        recalcDirection()
    }

    // MARK: - Speed management

    /// Increase speed by acceleration amount when a direction is active,
    /// or decay speed when idle so momentum carries through quick direction switches.
    func accelerate() {
        if direction.isEmpty {
            if speed > 0 {
                speed = max(speed - acceleration * 2, 0)
            }
            return
        }
        speed = min(speed + acceleration, _maxSpeed)
    }

    func setMaxSpeed(_ value: Double) {
        _maxSpeed = value
        if speed > value {
            speed = value
        }
    }

    func resetMaxSpeed() {
        _maxSpeed = defaultMaxSpeed
        if speed > defaultMaxSpeed {
            speed = defaultMaxSpeed
        }
    }

    // MARK: - Runtime parameter updates

    /// Update tuning parameters without resetting current motion state.
    func updateParameters(acceleration: Double, maxSpeed: Double, startSpeed: Double) {
        self.acceleration = acceleration
        self.defaultMaxSpeed = maxSpeed
        self._maxSpeed = maxSpeed
        self.startSpeed = startSpeed
        if speed > maxSpeed {
            speed = maxSpeed
        }
    }

    // MARK: - Vector output

    /// Returns the (dx, dy) movement vector for this tick
    func vector() -> (dx: Int, dy: Int) {
        guard !direction.isEmpty else { return (0, 0) }

        var fx: Double = 0
        var fy: Double = 0

        if direction.contains(.up)    { fy -= 1 }
        if direction.contains(.down)  { fy += 1 }
        if direction.contains(.left)  { fx -= 1 }
        if direction.contains(.right) { fx += 1 }

        // Apply diagonal ratio when moving diagonally
        let isDiagonal = fx != 0 && fy != 0
        if isDiagonal {
            fx *= diagonalRatio
            fy *= diagonalRatio
        }

        let dx = Int((speed * fx).rounded())
        let dy = Int((speed * fy).rounded())

        // If rounding gives zero vector despite having a non-zero unit direction,
        // speed is too low to produce movement — reset it. But don't reset when
        // opposing directions cancel (fx==0 && fy==0), so momentum is preserved
        // through direction switches (prevents "magnetic edge" stickiness).
        if dx == 0 && dy == 0 && (fx != 0 || fy != 0) {
            speed = 0
        }

        return (dx, dy)
    }

    // MARK: - Reset

    func reset() {
        speed = 0
        _maxSpeed = defaultMaxSpeed
        directionStack.removeAll()
        direction = []
    }

    // MARK: - Private

    private func recalcDirection() {
        let wasEmpty = direction.isEmpty
        direction = []
        for d in directionStack {
            direction.formUnion(d)
        }
        if !direction.isEmpty && wasEmpty {
            // Resuming movement — use retained momentum or startSpeed, whichever is greater
            speed = max(speed, startSpeed)
        }
        // When direction empties, don't zero speed immediately —
        // accelerate() will decay it, preserving momentum through quick direction switches.
    }
}
