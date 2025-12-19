import Foundation

extension Notification.Name {
    /// Posted whenever the Radio updates its currently playing metadata (title/artist).
    static let nowPlayingDidUpdate = Notification.Name("nowPlayingDidUpdate")
}
