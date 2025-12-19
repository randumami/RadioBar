import Foundation

// Centraliseret modelstore for radiolisten med indlæsning/skrivning via RadioManager.
// Poster .radiosDidChange når data opdateres, så UI kan reagere.
final class RadioStore {
    static let shared = RadioStore()
    private let manager = RadioManager()
    private(set) var radios: [MyRadio] = []

    // Indlæser radiolisten asynkront og poster .radiosDidChange på hovedtråden.
    // Sikrer responsivt UI og konsistent state-opdatering.
    func load() {
        Task { @MainActor in
            self.radios = self.manager.loadRadios()
            NotificationCenter.default.post(name: .radiosDidChange, object: nil)
        }
    }

    // Opdaterer og persisterer radiolisten og poster .radiosDidChange.
    // Gør det let for andre dele af appen at reagere på ændringer.
    func update(_ radios: [MyRadio]) {
        Task { @MainActor in
            self.radios = radios
            self.manager.write(myRadios: radios)
            NotificationCenter.default.post(name: .radiosDidChange, object: nil)
        }
    }
}

extension Notification.Name {
    static let radiosDidChange = Notification.Name("radiosDidChange")
    static let nowPlayingDidUpdate = Notification.Name("nowPlayingDidUpdate")
}
