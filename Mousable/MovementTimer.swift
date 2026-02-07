import Foundation

/// Fires a callback every 20ms (50Hz) on a high-priority serial queue.
final class MovementTimer {
    private let queue = DispatchQueue(label: "com.mousable.movement", qos: .userInteractive)
    private var timer: DispatchSourceTimer?

    var onTick: (() -> Void)?

    func start() {
        guard timer == nil else { return }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: .milliseconds(20), leeway: .milliseconds(1))
        t.setEventHandler { [weak self] in
            self?.onTick?()
        }
        t.resume()
        timer = t
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }
}
