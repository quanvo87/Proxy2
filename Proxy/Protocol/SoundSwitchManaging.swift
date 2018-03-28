import UIKit

protocol SoundSwitchManaging {
    var soundSwitch: UISwitch { get }
}

class SoundSwitchManager: SoundSwitchManaging {
    let soundSwitch = UISwitch(frame: .zero)
    private let uid: String

    init(uid: String) {
        self.uid = uid

        Shared.database.get(.soundOn(Bool()), for: uid) { [weak self] result in
            guard let _self = self else {
                return
            }
            _self.soundSwitch.addTarget(self, action: #selector(_self.toggleSound), for: .valueChanged)
            var soundOn = true
            if case let .success(data) = result, let soundOnFromDatabase = data.value as? Bool {
                soundOn = soundOnFromDatabase
            } else {
                Shared.database.set(.soundOn(true), for: uid) { _ in }
            }
            _self.soundSwitch.setOn(soundOn, animated: false)
            UserDefaults.standard.set(soundOn, forKey: SettableUserProperty.Name.soundOn.rawValue)
        }
    }

    @objc private func toggleSound() {
        let soundOn = soundSwitch.isOn
        Shared.database.set(.soundOn(soundOn), for: uid) { _ in }
        UserDefaults.standard.set(soundOn, forKey: SettableUserProperty.Name.soundOn.rawValue)
    }
}
