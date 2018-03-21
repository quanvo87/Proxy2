import UIKit

protocol SoundSwitchManaging {
    var soundSwitch: UISwitch { get }
}

class SoundSwitchManager: SoundSwitchManaging {
    let soundSwitch = UISwitch(frame: .zero)
    private let database: Database
    private let uid: String

    init(database: Database = Firebase(), uid: String) {
        self.database = database
        self.uid = uid

        database.get(userProperty: .soundOn(Bool()), for: uid) { [weak self] result in
            guard let _self = self else {
                return
            }
            _self.soundSwitch.addTarget(self, action: #selector(_self.toggleSound), for: .valueChanged)
            var soundOn = true
            if case let .success(data) = result, let soundOnFromDatabase = data.value as? Bool {
                soundOn = soundOnFromDatabase
            } else {
                _self.database.set(userProperty: .soundOn(true), for: uid) { _ in }
            }
            _self.soundSwitch.setOn(soundOn, animated: false)
            UserDefaults.standard.set(soundOn, forKey: Constant.soundOn)
        }
    }

    @objc private func toggleSound() {
        let soundOn = soundSwitch.isOn
        database.set(userProperty: .soundOn(soundOn), for: uid) { _ in }
        UserDefaults.standard.set(soundOn, forKey: Constant.soundOn)
    }
}
