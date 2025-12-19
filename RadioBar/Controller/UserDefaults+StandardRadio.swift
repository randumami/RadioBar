import Foundation

extension UserDefaults {
    private enum Keys {
        static let standardRadio = "standardRadio"
    }

    /// The user's selected default radio channel name. Defaults to "-" when not set.
    var standardRadio: String {
        get { string(forKey: Keys.standardRadio) ?? "-" }
        set { set(newValue, forKey: Keys.standardRadio) }
    }
}
