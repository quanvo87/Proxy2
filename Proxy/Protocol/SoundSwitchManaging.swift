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
            guard let strongSelf = self else {
                return
            }
            strongSelf.soundSwitch.addTarget(self, action: #selector(strongSelf.toggleSound), for: .valueChanged)
            var soundOn = true
            if case let .success(data) = result, let soundOnFromDatabase = data.value as? Bool {
                soundOn = soundOnFromDatabase
            } else {
                Shared.database.set(.soundOn(true), for: uid, playSound: false) { _ in }
            }
            strongSelf.soundSwitch.setOn(soundOn, animated: false)
            UserDefaults.standard.set(soundOn, forKey: SettableUserProperty.Name.soundOn.rawValue)
        }
    }

    @objc private func toggleSound() {
        let soundOn = soundSwitch.isOn
        Shared.database.set(.soundOn(soundOn), for: uid) { _ in }
        UserDefaults.standard.set(soundOn, forKey: SettableUserProperty.Name.soundOn.rawValue)
    }
}
